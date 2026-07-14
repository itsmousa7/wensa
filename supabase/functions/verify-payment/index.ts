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
 *     reference_id: string }   // stored into payment_id on confirm
 *
 * Response: { paid: boolean, code: string, description: string }
 *
 * Env: SUPABASE_URL, SUPABASE_ANON_KEY,
 *      HYPERPAY_BASE, HYPERPAY_ENTITY_ID, HYPERPAY_AUTH_TOKEN
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// deno-lint-ignore no-control-regex
const SUCCESS_CODE = /^(000\.000\.|000\.100\.1)/;
const MANUAL_REVIEW_CODE = /^(000\.400\.0[^3]|000\.400\.100)/;

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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const SUPABASE_URL        = Deno.env.get("SUPABASE_URL")!;
  const ANON_KEY            = Deno.env.get("SUPABASE_ANON_KEY")!;
  const HYPERPAY_BASE       = Deno.env.get("HYPERPAY_BASE") ?? "https://eu-test.oppwa.com";
  const HYPERPAY_ENTITY_ID  = Deno.env.get("HYPERPAY_ENTITY_ID")!;
  const HYPERPAY_AUTH_TOKEN = Deno.env.get("HYPERPAY_AUTH_TOKEN")!;

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing authorization" }, 401);
    }

    const body = await req.json().catch(() => null) as {
      checkout_id?: string; kind?: string; id?: string; reference_id?: string;
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
    };
    const code        = statusJson.result?.code ?? "unknown";
    const description = statusJson.result?.description ?? `HTTP ${statusRes.status}`;

    const paid = SUCCESS_CODE.test(code) || MANUAL_REVIEW_CODE.test(code);
    if (!paid) {
      // Not an error: the row stays pending; expiry crons clean it up.
      return json({ paid: false, code, description }, 200);
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

    return json({ paid: true, code, description }, 200);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("verify-payment error:", msg);
    return json({ error: msg }, 500);
  }
});
