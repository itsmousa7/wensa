/**
 * verify-payment — server-side HyperPay payment verification + booking confirm.
 *
 * The app calls this after the native mSDK reports success/SYNC. We check the
 * payment status with HyperPay using server-held credentials, and only if the
 * result code is a success do we flip the booking/membership to confirmed via
 * the existing SECURITY DEFINER RPCs (which are scoped to the caller's uid and
 * idempotent). Rows that never get verified stay pending and are swept by the
 * existing expiry crons.
 *
 * Every FINAL result is persisted into bookings.payment_transactions (audit:
 * result code, merchantTransactionId, RRN, local/international card scope) —
 * the admin/merchant dashboards read that table via get-transactions /
 * get-payment-transaction. The OPPWA status read is ONE-TIME consumable, so
 * the persisted row also answers retries: a repeat call (or one that lost the
 * race and sees 200.300.404) is served DB-first instead of failing.
 *
 * Request (POST, user JWT required):
 *   { checkout_id: string,
 *     kind: "booking" | "concert_group" | "membership",
 *     id: string,              // booking_id | group_id | membership_id
 *     reference_id: string,    // stored into payment_id on confirm
 *     save_card?: boolean }    // persist the card token for one-tap payments
 *
 * Response: { paid: boolean, code: string, description: string,
 *             merchant_transaction_id: string | null }
 *
 * Checkouts are created with createRegistration=true (create-booking), so a
 * successful status result carries a registrationId. When save_card is true
 * we upsert it into bookings.user_payment_tokens for the caller (best-effort,
 * never fails the payment) — unless the admin dashboard's card-saving toggle
 * (public.app_settings key card_saving_enabled) is off, in which case the
 * save is silently skipped and the payment still succeeds.
 *
 * Env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY,
 *      HYPERPAY_ENV (selects the LIVE vs TEST credential set — see _shared/hyperpay.ts)
 */

import {
  cfg,
  extractPaymentDetails,
  getPaymentStatus,
  isPaid,
  isPending,
  isTransient,
  type HyperPayResult,
} from "../_shared/hyperpay.ts";
import { insertPaymentTransaction, getPaymentTransactionByCheckout, markPaymentFailed, setCardScope } from "../_shared/payments.ts";
import {
  buildPaymentTxRow,
  confirmViaRpc,
  corsHeaders,
  json,
  jwtSub,
  RPC_BY_KIND,
  rowEntityId,
  serviceHeaders,
} from "../_shared/payment_flow.ts";

/**
 * Whether the admin dashboard's "allow saving cards" toggle is on
 * (public.app_settings, key card_saving_enabled). Missing row or any value
 * other than the literal string "false" defaults to enabled, matching the
 * seeded default.
 */
async function isCardSavingEnabled(supabaseUrl: string, serviceKey: string): Promise<boolean> {
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/app_settings?key=eq.card_saving_enabled&select=value`,
      { headers: serviceHeaders(serviceKey) },
    );
    if (!res.ok) return true;
    const rows = await res.json() as Array<{ value: string }>;
    return rows[0]?.value !== "false";
  } catch {
    return true;
  }
}

/**
 * Upsert the card token from a successful payment result into
 * bookings.user_payment_tokens for the JWT's user. Conflict target is the
 * (user_id, brand, last4, exp_month, exp_year) unique index so re-saving the
 * same physical card refreshes registration_id instead of duplicating the row.
 * Best-effort — a token-save failure must never fail the payment itself.
 */
async function saveCardToken(
  supabaseUrl: string,
  jwt: string,
  payment: HyperPayResult,
): Promise<void> {
  try {
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    if (!(await isCardSavingEnabled(supabaseUrl, SERVICE_KEY))) return;

    const userId = jwtSub(jwt);
    if (!userId) return;

    const res = await fetch(
      `${supabaseUrl}/rest/v1/user_payment_tokens` +
        `?on_conflict=user_id,brand,last4,exp_month,exp_year`,
      {
        method: "POST",
        headers: {
          apikey: SERVICE_KEY,
          Authorization: `Bearer ${SERVICE_KEY}`,
          "Content-Type": "application/json",
          "Content-Profile": "bookings",
          Prefer: "resolution=merge-duplicates,return=minimal",
        },
        body: JSON.stringify({
          user_id: userId,
          registration_id: payment.registrationId,
          brand: payment.paymentBrand ?? null,
          last4: payment.card?.last4Digits ?? null,
          exp_month: payment.card?.expiryMonth ?? null,
          exp_year: payment.card?.expiryYear ?? null,
          holder: payment.card?.holder ?? null,
          initial_transaction_id: payment.id ?? null,
        }),
      },
    );
    if (!res.ok) {
      console.error(`saveCardToken failed ${res.status}: ${await res.text().catch(() => "")}`);
    }
  } catch (e) {
    console.error("saveCardToken failed (non-fatal):", e);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const SUPABASE_URL        = Deno.env.get("SUPABASE_URL")!;
  const ANON_KEY            = Deno.env.get("SUPABASE_ANON_KEY")!;
  const SERVICE_KEY         = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing authorization" }, 401);
    }

    const body = await req.json().catch(() => null) as {
      checkout_id?: string; kind?: string; id?: string; reference_id?: string;
      save_card?: boolean;
    } | null;

    const rpc = body?.kind ? RPC_BY_KIND[body.kind] : undefined;
    if (!body?.checkout_id || !body?.id || !body?.reference_id || !rpc) {
      return json({ error: "checkout_id, kind, id, reference_id required" }, 400);
    }

    const svc = serviceHeaders(SERVICE_KEY);

    // ── 0. DB-first: this checkout's final outcome may already be persisted ──
    // (a retried call, or one that lost the race for the one-time OPPWA read).
    // On a persisted success re-run the confirm RPC anyway — it's idempotent
    // and user-scoped, and it heals the crash window where the row was written
    // but the confirm never ran.
    const existing = await getPaymentTransactionByCheckout(SUPABASE_URL, svc, body.checkout_id);
    if (existing) {
      const callerId = jwtSub(authHeader.slice(7));
      if (existing.user_id && callerId && existing.user_id !== callerId) {
        return json({ error: "Forbidden" }, 403);
      }
      // SECURITY: the row is looked up by checkout_id ALONE, so it must also be
      // proven to target the entity being confirmed. Without this, a caller can
      // replay their own already-paid checkout against a NEW pending booking and
      // have it confirmed for free — the confirm RPCs key only on (id, uid,
      // status) and never see the checkout, so they offer no defence.
      const existingEntityId = rowEntityId(existing);
      if (existingEntityId && existingEntityId !== body.id) {
        console.error(
          `verify-payment: REJECTED checkout replay — checkout=${body.checkout_id} ` +
          `is bound to entity=${existingEntityId} but caller requested entity=${body.id} ` +
          `(kind=${body.kind} user=${callerId})`,
        );
        return json({ error: "Forbidden" }, 403);
      }
      if (existing.status === "success") {
        const rpcOut = await confirmViaRpc(SUPABASE_URL, ANON_KEY, authHeader, rpc, body.id, body.reference_id);
        if (!rpcOut.ok) {
          console.error(`verify-payment (db-first): ${rpc.fn} failed ${rpcOut.status}: ${rpcOut.errText}`);
          return json({ error: `Payment verified but confirm failed (${rpcOut.status})` }, 500);
        }
        await setCardScope(SUPABASE_URL, svc, body.kind!, body.id, existing.card_scope);
        return json({
          paid: true,
          code: existing.result_code ?? "unknown",
          description: existing.result_description ?? "Payment approved",
          merchant_transaction_id: existing.merchant_transaction_id ?? null,
        }, 200);
      }
      // Persisted decline: settle the entity too. Idempotent (the PATCH only
      // matches a still-pending row), so this also heals rows left pending by
      // the earlier behaviour of returning without touching them.
      await markPaymentFailed(SUPABASE_URL, svc, body.kind!, body.id);
      return json({
        paid: false,
        code: existing.result_code ?? "unknown",
        description: existing.result_description ?? "Payment was not completed",
        merchant_transaction_id: existing.merchant_transaction_id ?? null,
      }, 200);
    }

    // ── 1. Ask HyperPay for the payment status ──────────────────────────────
    const hpConfig = cfg();
    const { httpStatus, result: statusJson } = await getPaymentStatus(body.checkout_id, hpConfig);

    // A non-2xx WITHOUT a result code means the verification call itself broke
    // (bad credentials, HyperPay outage) — surface as retryable, not "unpaid".
    // Declined payments come back with a result code even on non-2xx statuses,
    // so those still classify normally below.
    const httpOk = httpStatus >= 200 && httpStatus < 300;
    if (!httpOk && !statusJson.result?.code) {
      console.error(`verify-payment: HyperPay status check failed ${httpStatus}`);
      return json({ error: `HyperPay status check failed (${httpStatus})` }, 502);
    }

    const code        = statusJson.result?.code ?? "unknown";
    const description = statusJson.result?.description ?? `HTTP ${httpStatus}`;
    const details     = extractPaymentDetails(statusJson);
    // Echoed back so the app can show a support-friendly transaction id on
    // the payment result page (matches the id visible in the HyperPay BIP).
    const merchantTransactionId = details.merchantTransactionId;

    // SECURITY: bind this checkout to the entity being confirmed.
    //
    // The rowEntityId guard above only runs when a payment_transactions row
    // ALREADY exists, i.e. from the second call onward. On the FIRST call for a
    // checkout there is nothing to compare against, so without this a caller
    // could pay for a cheap booking, never verify it, then present that paid
    // checkout_id alongside a DIFFERENT pending booking's id and have the
    // expensive one confirmed for free. The confirm RPCs key only on
    // (id, uid, status) and never see the checkout, so they offer no defence.
    //
    // create-booking / create-membership derive merchantTransactionId
    // deterministically from the entity, so the gateway's own echo of it is
    // proof of which entity the money was for.
    //
    // Only rejects on a PRESENT-and-mismatched value: the field is genuinely
    // absent in some gateway responses, and failing closed there would break
    // legitimate payments. A forged replay always carries the other entity's
    // id, so the attack is still caught.
    const expectedTxnId = body.kind === "membership"
      ? `membership-${body.id}`.slice(0, 32)
      : body.kind === "concert_group"
      ? `booking-venue-${body.id}`.slice(0, 32)
      : `booking-${body.id}`.slice(0, 32);
    if (merchantTransactionId && merchantTransactionId !== expectedTxnId) {
      console.error(
        `verify-payment: REJECTED checkout/entity mismatch — checkout=${body.checkout_id} ` +
        `carries mtx=${merchantTransactionId} but entity=${body.id} (kind=${body.kind}) ` +
        `expects mtx=${expectedTxnId} (user=${jwtSub(authHeader.slice(7))})`,
      );
      return json({ error: "Forbidden" }, 403);
    }

    // Non-final codes (3DS still in flight, gateway rate limit) and a lost
    // 200.300.404 race with no persisted row yet: nothing to persist or
    // confirm — report unpaid and let the app retry.
    if (isPending(code) || isTransient(code) || code === "200.300.404") {
      return json(
        { paid: false, code, description, merchant_transaction_id: merchantTransactionId },
        200,
      );
    }

    const paid = isPaid(code, hpConfig.env);
    console.log(
      `verify-payment: checkout=${body.checkout_id} kind=${body.kind} ` +
      `http=${httpStatus} code=${code} paid=${paid} rrn=${details.rrn} ` +
      `scope=${details.cardScope} desc=${description}`,
    );

    // ── 2. Persist the FINAL outcome (before confirming) ────────────────────
    // The OPPWA session is now consumed; this row is the durable record the
    // dashboards read (RRN, result code, local/international card scope) and
    // what serves any retry of this function.
    const row = buildPaymentTxRow({
      kind: body.kind!,
      id: body.id,
      referenceId: body.reference_id,
      userId: jwtSub(authHeader.slice(7)),
      amountIqd: statusJson.amount != null && !Number.isNaN(Number(statusJson.amount))
        ? Math.round(Number(statusJson.amount))
        : null,
      paid,
      code,
      description,
      details,
      checkoutId: body.checkout_id,
    });
    const persisted = await insertPaymentTransaction(SUPABASE_URL, svc, row);

    // A CAPTURED payment whose row we failed to write is unrecoverable through
    // this endpoint: the OPPWA session is a one-time read, so every retry now
    // gets 200.300.404 with no persisted row to serve it. Dump the full result
    // so the payment can be reconciled from the logs, and fail loudly instead
    // of confirming on top of a missing audit row.
    if (paid && !persisted) {
      console.error(
        "verify-payment: PAYMENT CAPTURED BUT RECORD FAILED — reconcile manually. " +
        `checkout=${body.checkout_id} kind=${body.kind} id=${body.id} ` +
        `reference=${body.reference_id} result=${JSON.stringify(statusJson)}`,
      );
      return json({
        error: "Payment captured but could not be recorded. Support has been notified.",
        code: "payment_recorded_failed",
      }, 500);
    }

    if (!paid) {
      // Settled decline (the non-final codes returned above). Mark the row
      // failed/cancelled rather than leaving it pending for the expiry crons —
      // a pending row shows in the dashboards as Expired instead of Failed.
      await markPaymentFailed(SUPABASE_URL, svc, body.kind!, body.id);
      return json(
        { paid: false, code, description, merchant_transaction_id: merchantTransactionId },
        200,
      );
    }

    // ── 3. Confirm via the existing user-scoped RPC ─────────────────────────
    // Forward the caller's JWT so auth.uid() inside the RPC scopes the update.
    const rpcOut = await confirmViaRpc(SUPABASE_URL, ANON_KEY, authHeader, rpc, body.id, body.reference_id);
    if (!rpcOut.ok) {
      console.error(`verify-payment: ${rpc.fn} failed ${rpcOut.status}: ${rpcOut.errText}`);
      return json({ error: `Payment verified but confirm failed (${rpcOut.status})` }, 500);
    }

    await setCardScope(SUPABASE_URL, svc, body.kind!, body.id, details.cardScope);

    // ── 4. Optionally persist the card token (best-effort, never fatal) ─────
    if (body.save_card === true && statusJson.registrationId) {
      await saveCardToken(SUPABASE_URL, authHeader.slice(7), statusJson);
    }

    return json(
      { paid: true, code, description, merchant_transaction_id: merchantTransactionId },
      200,
    );
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("verify-payment error:", msg);
    return json({ error: msg }, 500);
  }
});
