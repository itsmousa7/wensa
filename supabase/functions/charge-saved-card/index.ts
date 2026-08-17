/**
 * charge-saved-card — one-tap payment using a saved card token (MIT).
 *
 * UAT GATE (2026-08-16): merchantTransactionId is now DETERMINISTIC per entity
 * to close a double-charge hole (see the MIT charge block below). Before going
 * live, confirm that a DECLINED attempt can be retried under the same stable
 * id. If the acquirer rejects reuse after a decline, append an attempt counter
 * derived from persisted payment_transactions rows — never a random value,
 * which is exactly the bug this replaced.
 *
 * Server-to-server charge against a stored OPPWA registration:
 *   POST /v1/registrations/{registrationId}/payments
 * with standingInstruction mode=REPEATED source=MIT type=UNSCHEDULED — the
 * same proven body as the dashboard's hyperpay-charge-token. The result is
 * synchronous. Pending (000.200.*) and transient (800.120.100 / 900.*) codes
 * are NOT failures — the acquirer outcome is unknown and may be a capture, so
 * nothing is persisted and the response carries retryable:true.
 *
 * The client calls this INSTEAD of the card form + verify-payment: the
 * checkout session created by create-booking is simply left to expire.
 * On success the booking/membership is confirmed via the same user-scoped
 * SECURITY DEFINER RPCs verify-payment uses.
 *
 * Request (POST, user JWT required):
 *   { token_id: string,       // bookings.user_payment_tokens.id
 *     kind: "booking" | "concert_group" | "membership",
 *     id: string,             // booking_id | group_id | membership_id
 *     reference_id: string }  // stored into payment_id on confirm
 *
 * Response: { paid: boolean, code: string, description: string }
 *
 * The amount is NEVER taken from the client — it is read from the caller's
 * own pending row(s) (amount_iqd persisted by create-booking).
 *
 * Before charging, calls bookings.lock_for_payment(kind, id) to re-validate
 * and extend the hold: single-row holds (hourly/shift/reservation/general
 * admission) last only 60 seconds, so without this a charge could succeed at
 * HyperPay after the hold already expired, leaving the user paid with no
 * confirmed booking (confirm_payment only flips rows still 'pending'). If
 * the lock fails, no charge is attempted — the caller gets a "paid: false"
 * response with a slot-unavailable description instead.
 *
 * Env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY,
 *      HYPERPAY_ENV (selects the LIVE vs TEST credential set — see _shared/hyperpay.ts)
 *
 * ENTITY: this MIT charge is sent to the RECURRING channel entity
 * (HYPERPAY_{LIVE,TEST}_RECURRING_ENTITY_ID), not the checkout entity — the
 * initial CIT checkout that created the token still runs on the checkout one.
 */

import {
  cfg,
  chargeRegistration,
  extractPaymentDetails,
  isDuplicateMerchantTxnId,
  isPaid,
  isPending,
  isTransient,
} from "../_shared/hyperpay.ts";
import { insertPaymentTransaction, markPaymentFailed, setCardScope } from "../_shared/payments.ts";
import {
  buildPaymentTxRow,
  confirmViaRpc,
  corsHeaders,
  json,
  jwtSub,
  RPC_BY_KIND,
  serviceHeaders,
} from "../_shared/payment_flow.ts";

/** Re-validates and extends the caller's hold immediately before charging.
 *  Forwards the caller's own JWT (not the service role) so auth.uid() inside
 *  the SECURITY DEFINER RPC scopes the check to their row(s). */
async function lockForPayment(
  supabaseUrl: string,
  anonKey: string,
  authHeader: string,
  kind: string,
  id: string,
): Promise<boolean> {
  const res = await fetch(`${supabaseUrl}/rest/v1/rpc/lock_for_payment`, {
    method: "POST",
    headers: {
      Authorization: authHeader,
      apikey: anonKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ p_kind: kind, p_id: id }),
  });
  if (!res.ok) return false;
  return (await res.json()) === true;
}

/** Load the pending amount for the caller's row(s). Returns null when the
 *  row is missing, not the caller's, not pending, or has no positive amount. */
async function loadPendingAmount(
  supabaseUrl: string,
  svc: Record<string, string>,
  kind: string,
  id: string,
  callerId: string,
): Promise<number | null> {
  const headers = { ...svc, "Accept-Profile": "bookings" };
  let url: string;
  if (kind === "booking") {
    url = `${supabaseUrl}/rest/v1/bookings?id=eq.${id}&user_id=eq.${callerId}&status=eq.pending&select=amount_iqd`;
  } else if (kind === "concert_group") {
    url = `${supabaseUrl}/rest/v1/bookings?group_id=eq.${id}&user_id=eq.${callerId}&status=eq.pending&select=amount_iqd`;
  } else {
    url = `${supabaseUrl}/rest/v1/memberships?id=eq.${id}&user_id=eq.${callerId}&status=eq.pending&select=amount_iqd`;
  }
  const res = await fetch(url, { headers });
  if (!res.ok) return null;
  const rows = await res.json() as Array<{ amount_iqd: number | null }>;
  if (!rows.length) return null;
  const total = rows.reduce((sum, r) => sum + (Number(r.amount_iqd) || 0), 0);
  return total > 0 ? Math.round(total) : null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const SUPABASE_URL        = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY         = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const ANON_KEY            = Deno.env.get("SUPABASE_ANON_KEY")!;

  try {
    // ── Auth ────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing authorization" }, 401);
    }
    const callerId = jwtSub(authHeader.slice(7));
    if (!callerId) return json({ error: "Unauthorized" }, 401);

    const body = await req.json().catch(() => null) as {
      token_id?: string; kind?: string; id?: string; reference_id?: string;
    } | null;
    const rpc = body?.kind ? RPC_BY_KIND[body.kind] : undefined;
    if (!body?.token_id || !body?.id || !body?.reference_id || !rpc) {
      return json({ error: "token_id, kind, id, reference_id required" }, 400);
    }

    const svc = serviceHeaders(SERVICE_KEY);

    // ── Load the caller's saved card ────────────────────────────────────────
    const tRes = await fetch(
      `${SUPABASE_URL}/rest/v1/user_payment_tokens` +
        `?id=eq.${body.token_id}&user_id=eq.${callerId}` +
        `&select=registration_id,initial_transaction_id&limit=1`,
      { headers: { ...svc, "Accept-Profile": "bookings" } },
    );
    const tokens = await tRes.json() as Array<{
      registration_id: string; initial_transaction_id: string | null;
    }>;
    if (!tRes.ok || !tokens.length) return json({ error: "Saved card not found" }, 404);
    const token = tokens[0];

    // ── Resolve amount server-side from the caller's pending row(s) ─────────
    const amount = await loadPendingAmount(SUPABASE_URL, svc, body.kind!, body.id, callerId);
    if (amount === null) return json({ error: "No pending payment found" }, 404);

    // ── Re-validate + extend the hold right before charging ─────────────────
    const locked = await lockForPayment(SUPABASE_URL, ANON_KEY, authHeader, body.kind!, body.id);
    if (!locked) {
      console.log(`charge-saved-card: lock failed kind=${body.kind} id=${body.id}`);
      return json({
        paid: false,
        code: "hold_expired",
        description: "This slot is no longer available. Please start again.",
      }, 200);
    }

    // ── MIT charge ──────────────────────────────────────────────────────────
    // DETERMINISTIC per entity — this closes a real double-charge hole. The
    // previous code minted a FRESH random `mit-<uuid>` on every call, so two
    // requests for the same (kind, id) — a double-tap, a client retry after a
    // timeout, a replay — looked like two unrelated MIT charges to HyperPay
    // and BOTH were captured. Nothing else de-duplicates: both requests read
    // the same pending row and both pass lock_for_payment, which extends the
    // hold rather than claiming it.
    //
    // Deriving the id from the entity makes the duplicate visible to the
    // acquirer and to our own payment_transactions unique index, so the second
    // attempt is rejected before money moves.
    //
    // Format rules this must not break (any deviation ⇒ 800.100.156 "format
    // error"): ≤32 chars, dashes only, never an underscore.
    const mitEntityPrefix = body.kind === "membership"
      ? "m"
      : body.kind === "concert_group"
      ? "g"
      : "b";
    const merchantTransactionId =
      `mit-${mitEntityPrefix}-${body.id.replace(/-/g, "")}`.slice(0, 32);

    const hpConfig = cfg();

    const result = await chargeRegistration(token.registration_id, {
      amount,
      merchantTransactionId,
      initialTransactionId: token.initial_transaction_id,
    }, hpConfig);

    const code        = result.result?.code ?? "unknown";
    const description = result.result?.description ?? "Unknown payment result";
    const paid        = isPaid(code, hpConfig.env);
    const details     = extractPaymentDetails(result);
    console.log(
      `charge-saved-card: kind=${body.kind} id=${body.id} amount=${amount} ` +
      `code=${code} paid=${paid} rrn=${details.rrn} scope=${details.cardScope} desc=${description}`,
    );

    // ── Non-final codes: outcome UNKNOWN, never "failed" ────────────────────
    // 000.200.* (still in flight), 800.120.100 (rate limit) and 900.* ("error
    // in communication with the connector") do NOT mean the card wasn't
    // charged — the acquirer may well have captured it, we just never got the
    // answer. Writing a `failed` row here would let the client release the
    // booking on money that was taken, and would poison any reconciliation
    // sweep (the row would look like a settled failure). So: persist nothing,
    // and answer with a distinct retryable signal instead of paid:false alone.
    //
    // 200.300.404 gets the SAME treatment but is NOT retryable: it means the
    // acquirer rejected this merchantTransactionId as already-used, which can
    // only happen if some earlier attempt (possibly one we never persisted,
    // e.g. a pending/transient result) already reached HyperPay under this
    // id — see isDuplicateMerchantTxnId. Since the id is deterministic, a
    // client retry would resend the exact same id and collide again, so this
    // needs manual reconciliation, not another tap.
    if (isPending(code) || isTransient(code) || isDuplicateMerchantTxnId(code)) {
      console.error(
        `charge-saved-card: NON-FINAL result — outcome unknown, may be captured. ` +
        `kind=${body.kind} id=${body.id} amount=${amount} code=${code} ` +
        `mtx=${merchantTransactionId} uniqueId=${details.uniqueId} desc=${description}`,
      );
      const duplicate = isDuplicateMerchantTxnId(code);
      return json({
        paid: false,
        pending: true,
        retryable: !duplicate,
        status: "pending",
        code,
        description: duplicate
          ? "We could not confirm this payment automatically. Please check " +
            "your bookings or contact support with this transaction ID " +
            "before trying again."
          : description,
        merchant_transaction_id: merchantTransactionId,
      }, 200);
    }

    // Persist the outcome for the dashboards (result code, RRN, card scope).
    // An MIT charge has no checkout session — the OPPWA payment id fills the
    // unique checkout_id slot (falling back to our own MIT reference).
    const txRow = buildPaymentTxRow({
      kind: body.kind!,
      id: body.id,
      referenceId: body.reference_id,
      userId: callerId,
      amountIqd: amount,
      paid,
      code,
      description,
      details,
      checkoutId: details.uniqueId ?? `mit_${merchantTransactionId}`,
      fallbackMerchantTransactionId: merchantTransactionId,
    });
    const persisted = await insertPaymentTransaction(SUPABASE_URL, svc, txRow);
    if (paid && !persisted) {
      // The charge succeeded but the audit row is lost. Unlike verify-payment
      // this is still confirmable (the result is in hand, not behind a consumed
      // one-time session), so continue — but dump the result for reconciliation.
      console.error(
        "charge-saved-card: CHARGED BUT RECORD FAILED — reconcile manually. " +
        `kind=${body.kind} id=${body.id} reference=${body.reference_id} ` +
        `result=${JSON.stringify(result)}`,
      );
    }

    if (!paid) {
      // Settled decline — the non-final codes already returned above, so the
      // money definitively was not taken. Mark the row failed/cancelled instead
      // of leaving it pending for the client or the expiry crons: a pending row
      // shows in the dashboards as Expired rather than Failed.
      await markPaymentFailed(SUPABASE_URL, svc, body.kind!, body.id);
      return json(
        { paid: false, code, description, merchant_transaction_id: merchantTransactionId },
        200,
      );
    }

    // ── Confirm via the existing user-scoped RPC ────────────────────────────
    const rpcOut = await confirmViaRpc(
      SUPABASE_URL, ANON_KEY, authHeader, rpc, body.id, body.reference_id,
    );
    if (!rpcOut.ok) {
      console.error(`charge-saved-card: ${rpc.fn} failed ${rpcOut.status}: ${rpcOut.errText}`);
      return json({ error: `Payment charged but confirm failed (${rpcOut.status})` }, 500);
    }

    await setCardScope(SUPABASE_URL, svc, body.kind!, body.id, details.cardScope);

    return json(
      { paid: true, code, description, merchant_transaction_id: merchantTransactionId },
      200,
    );
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("charge-saved-card error:", msg);
    return json({ error: msg }, 500);
  }
});
