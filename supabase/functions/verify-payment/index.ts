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
 * never fails the payment).
 *
 * Env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY,
 *      HYPERPAY_BASE, HYPERPAY_ENTITY_ID, HYPERPAY_AUTH_TOKEN
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Success rule per environment — mirrors the dashboard's proven integration
// (wansa-admin-dashboard _shared/hyperpay.ts):
//   test: any "successfully processed in test mode" code — 000.100.1xx
//   prod: only 000.000.000 is a successful payment
const TEST_SUCCESS_RE = /^000\.100\.1\d{2}$/;
const PROD_SUCCESS_CODE = "000.000.000";

function isPaid(code: string, env: string): boolean {
  return env === "live" || env === "prod"
    ? code === PROD_SUCCESS_CODE
    : TEST_SUCCESS_RE.test(code) || code === PROD_SUCCESS_CODE;
}

const RPC_BY_KIND: Record<string, { fn: string; idParam: string }> = {
  booking:       { fn: "confirm_payment",               idParam: "p_booking_id" },
  concert_group: { fn: "confirm_concert_group_payment", idParam: "p_group_id" },
  membership:    { fn: "confirm_membership_payment",    idParam: "p_membership_id" },
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
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
  payment: {
    registrationId?: string;
    paymentBrand?: string;
    id?: string;
    card?: {
      last4Digits?: string; holder?: string;
      expiryMonth?: string; expiryYear?: string;
    };
  },
): Promise<void> {
  try {
    const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const b64 = jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    const userId = (JSON.parse(atob(b64)) as { sub?: string }).sub;
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
  const HYPERPAY_BASE       = Deno.env.get("HYPERPAY_BASE") ?? "https://eu-test.oppwa.com";
  const HYPERPAY_ENTITY_ID  = Deno.env.get("HYPERPAY_ENTITY_ID")!;
  const HYPERPAY_AUTH_TOKEN = Deno.env.get("HYPERPAY_AUTH_TOKEN")!;
  const HYPERPAY_ENV        = Deno.env.get("HYPERPAY_ENV") ?? "test";

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

    // ── 1. Ask HyperPay for the payment status ──────────────────────────────
    const statusRes = await fetch(
      `${HYPERPAY_BASE}/v1/checkouts/${encodeURIComponent(body.checkout_id)}` +
        `/payment?entityId=${encodeURIComponent(HYPERPAY_ENTITY_ID)}`,
      { headers: { Authorization: `Bearer ${HYPERPAY_AUTH_TOKEN}` } },
    );

    const statusJson = await statusRes.json().catch(() => ({})) as {
      result?: { code?: string; description?: string };
      merchantTransactionId?: string;
      registrationId?: string;
      paymentBrand?: string;
      id?: string;
      card?: {
        last4Digits?: string; holder?: string;
        expiryMonth?: string; expiryYear?: string;
      };
    };
    // A non-2xx WITHOUT a result code means the verification call itself broke
    // (bad credentials, HyperPay outage) — surface as retryable, not "unpaid".
    // Declined payments come back with a result code even on non-2xx statuses,
    // so those still classify normally below.
    if (!statusRes.ok && !statusJson.result?.code) {
      console.error(`verify-payment: HyperPay status check failed ${statusRes.status}`);
      return json({ error: `HyperPay status check failed (${statusRes.status})` }, 502);
    }

    const code        = statusJson.result?.code ?? "unknown";
    const description = statusJson.result?.description ?? `HTTP ${statusRes.status}`;
    // Echoed back so the app can show a support-friendly transaction id on
    // the payment result page (matches the id visible in the HyperPay BIP).
    const merchantTransactionId = statusJson.merchantTransactionId ?? null;

    const paid = isPaid(code, HYPERPAY_ENV);
    console.log(
      `verify-payment: checkout=${body.checkout_id} kind=${body.kind} ` +
      `http=${statusRes.status} code=${code} paid=${paid} desc=${description}`,
    );
    if (!paid) {
      // Not an error: the row stays pending; expiry crons clean it up.
      return json(
        { paid: false, code, description, merchant_transaction_id: merchantTransactionId },
        200,
      );
    }

    // ── 2. Confirm via the existing user-scoped RPC ─────────────────────────
    // Forward the caller's JWT so auth.uid() inside the RPC scopes the update.
    const rpcRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${rpc.fn}`, {
      method: "POST",
      headers: {
        "Authorization": authHeader,
        "apikey":        ANON_KEY,
        "Content-Type":  "application/json",
      },
      body: JSON.stringify({
        [rpc.idParam]: body.id,
        p_payment_id:  body.reference_id,
      }),
    });

    if (!rpcRes.ok) {
      const errText = await rpcRes.text().catch(() => "");
      console.error(`verify-payment: ${rpc.fn} failed ${rpcRes.status}: ${errText}`);
      return json({ error: `Payment verified but confirm failed (${rpcRes.status})` }, 500);
    }

    // ── 3. Optionally persist the card token (best-effort, never fatal) ─────
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
