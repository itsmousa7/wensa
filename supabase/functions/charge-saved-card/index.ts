/**
 * charge-saved-card — one-tap payment using a saved card token (MIT).
 *
 * Server-to-server charge against a stored OPPWA registration:
 *   POST /v1/registrations/{registrationId}/payments
 * with standingInstruction mode=REPEATED source=MIT type=UNSCHEDULED — the
 * same proven body as the dashboard's hyperpay-charge-token. The result is
 * synchronous; pending/transient codes are treated as failure.
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
 *      HYPERPAY_BASE, HYPERPAY_ENTITY_ID, HYPERPAY_AUTH_TOKEN, HYPERPAY_ENV
 */

import {
  chargeRegistration,
  type HyperPayConfig,
  type HyperPayEnv,
} from "../_shared/hyperpay.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Success rule per environment — mirrors verify-payment:
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
  const HYPERPAY_BASE       = Deno.env.get("HYPERPAY_BASE") ?? "https://eu-test.oppwa.com";
  const HYPERPAY_ENTITY_ID  = Deno.env.get("HYPERPAY_ENTITY_ID")!;
  const HYPERPAY_AUTH_TOKEN = Deno.env.get("HYPERPAY_AUTH_TOKEN")!;
  const HYPERPAY_ENV        = Deno.env.get("HYPERPAY_ENV") ?? "test";

  try {
    // ── Auth ────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing authorization" }, 401);
    }
    let callerId: string;
    try {
      const b64 = authHeader.slice(7).split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
      const payload = JSON.parse(atob(b64));
      if (!payload.sub) throw new Error("no sub");
      callerId = payload.sub;
    } catch {
      return json({ error: "Unauthorized" }, 401);
    }

    const body = await req.json().catch(() => null) as {
      token_id?: string; kind?: string; id?: string; reference_id?: string;
    } | null;
    const rpc = body?.kind ? RPC_BY_KIND[body.kind] : undefined;
    if (!body?.token_id || !body?.id || !body?.reference_id || !rpc) {
      return json({ error: "token_id, kind, id, reference_id required" }, 400);
    }

    const svc: Record<string, string> = {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
    };

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
    // ≤32 chars and no underscore (both trigger the acquirer's 800.100.156
    // "format error"): "mit-" + 28 hex chars of a UUID.
    const merchantTransactionId =
      `mit-${crypto.randomUUID().replace(/-/g, "").slice(0, 28)}`;

    const hpEnv: HyperPayEnv =
      HYPERPAY_ENV === "live" || HYPERPAY_ENV === "prod" ? "prod" : "test";
    const hpConfig: HyperPayConfig = {
      entityId:  HYPERPAY_ENTITY_ID,
      authToken: HYPERPAY_AUTH_TOKEN,
      env:       hpEnv,
      base:      HYPERPAY_BASE,
    };

    const result = await chargeRegistration(token.registration_id, {
      amount,
      merchantTransactionId,
      initialTransactionId: token.initial_transaction_id,
    }, hpConfig);

    const code        = result.result?.code ?? "unknown";
    const description = result.result?.description ?? "Unknown payment result";
    const paid        = isPaid(code, HYPERPAY_ENV);
    console.log(
      `charge-saved-card: kind=${body.kind} id=${body.id} amount=${amount} ` +
      `code=${code} paid=${paid} desc=${description}`,
    );
    if (!paid) {
      // Not an error: the row stays pending; the client releases it (same
      // path as a failed card payment) or the expiry crons clean it up.
      return json(
        { paid: false, code, description, merchant_transaction_id: merchantTransactionId },
        200,
      );
    }

    // ── Confirm via the existing user-scoped RPC ────────────────────────────
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
      console.error(`charge-saved-card: ${rpc.fn} failed ${rpcRes.status}: ${errText}`);
      return json({ error: `Payment charged but confirm failed (${rpcRes.status})` }, 500);
    }

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
