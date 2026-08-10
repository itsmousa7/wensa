/**
 * booking-action — let an authorized merchant (or admin) cancel/confirm one of
 * their own bookings or memberships.
 *
 * Why this exists: the `bookings`/`memberships` tables only grant UPDATE to
 * `service_role` and to admins (`*_admin_update` RLS). Merchant staff have
 * SELECT but NO update policy, so a client-side PATCH from the merchant portal
 * matched zero rows and PostgREST returned `200 []` — a silent no-op that looked
 * like success but never persisted (the reported "canceled successfully but still
 * booked" bug). This runs with the service-role key and performs ONLY the
 * requested status transition, after verifying the caller is staff/owner of the
 * booking's merchant (or an admin). Merchants can't touch payment amounts or flip
 * an unpaid booking to "paid" through here.
 *
 * Input:  { id: string, action: "cancel" | "confirm", is_membership?: boolean }
 * Output: { success: true, status: <new status> }
 */

import { buildRefundReason, cfg, refundPayment } from "../_shared/wayl.ts";
import { isWithinRefundWindow } from "./refund.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// States that can no longer be cancelled/confirmed.
const TERMINAL = ["cancelled", "completed", "expired", "used", "no_show"];

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    // ── Auth: who is calling? ─────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) return json({ error: "Missing authorization" }, 401);
    const jwt = authHeader.slice(7);

    let uid = "";
    try {
      const b64 = jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
      uid = JSON.parse(atob(b64)).sub ?? "";
    } catch { /* handled below */ }
    if (!uid) return json({ error: "Unauthorized" }, 401);

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const svc = serviceHeaders(SERVICE_KEY);

    // ── Input ─────────────────────────────────────────────────────────────
    const body = await req.json().catch(() => ({})) as {
      id?: string; action?: string; is_membership?: boolean;
    };
    const id = body.id?.trim() ?? "";
    const action = body.action ?? "";
    if (!id) return json({ error: "id is required" }, 400);
    if (action !== "cancel" && action !== "confirm") {
      return json({ error: "action must be 'cancel' or 'confirm'" }, 400);
    }
    const table = body.is_membership ? "memberships" : "bookings";
    // `group_id` (concert seat groups) only exists on bookings.bookings, not
    // bookings.memberships — requesting it for memberships makes PostgREST
    // 400 with "column memberships.group_id does not exist", which this
    // function turns into a 500, breaking cancel for every membership.
    const selectCols = body.is_membership
      ? "id,merchant_id,status,payment_status,paid_at,payment_id,amount_iqd,payment_method"
      : "id,merchant_id,status,payment_status,paid_at,group_id,payment_id,amount_iqd,payment_method";

    // ── Load the row (service role bypasses RLS) ──────────────────────────
    const rowRes = await fetch(
      `${SUPABASE_URL}/rest/v1/${table}?id=eq.${id}&select=${selectCols}&limit=1`,
      { headers: { ...svc, "Accept-Profile": "bookings" } },
    );
    if (!rowRes.ok) throw new Error(`Lookup failed: ${rowRes.status}`);
    const rows = await rowRes.json() as Array<{
      id: string; merchant_id: string | null; status: string; payment_status: string | null;
      paid_at: string | null; group_id: string | null;
      payment_id: string | null; amount_iqd: number | null; payment_method: string | null;
    }>;
    if (!rows.length) return json({ error: "Not found" }, 404);
    const row = rows[0];

    // ── Authorize: staff/owner of this merchant, or an admin ──────────────
    const actorRole = await resolveActorRole(SUPABASE_URL, svc, uid, row.merchant_id);
    if (!actorRole) return json({ error: "Forbidden" }, 403);

    // ── Guard state ───────────────────────────────────────────────────────
    if (TERMINAL.includes(row.status)) {
      return json({ error: `Booking is already ${row.status}`, status: row.status }, 409);
    }

    if (action === "confirm") {
      await applyPatch(SUPABASE_URL, svc, table, id, { status: "confirmed" });
      console.log(`booking-action: confirm ${table} id=${id} by=${uid}`);
      return json({ success: true, status: "confirmed" }, 200);
    }

    // action === "cancel"
    if (row.payment_status === "refunded") {
      return json({ error: "Booking is already refunded" }, 409);
    }

    if (row.payment_status === "paid" && row.payment_method !== "cash") {
      // Paid → refund at Wayl then cancel, within the 60-minute window.
      if (!isWithinRefundWindow(row.paid_at, Date.now())) {
        return json({ error: "Refund window has passed" }, 409);
      }

      // Wayl refunds are keyed on OUR reference (the stored payment_id), not on
      // a gateway-side transaction id, so nothing needs looking up in
      // payment_transactions the way the HyperPay RV path did.
      const referenceId = row.payment_id;
      if (!referenceId) return json({ error: "No refundable payment found" }, 409);

      // Refund the amount actually charged against this reference. A concert
      // group shares ONE payment reference while each row carries only its own
      // seat's amount_iqd, so a per-row amount would under-refund the customer.
      const refundAmount = (!body.is_membership && row.group_id)
        ? await groupTotalIqd(SUPABASE_URL, svc, row.group_id)
        : row.amount_iqd ?? 0;
      if (!(refundAmount > 0)) {
        return json({ error: "No refundable amount found" }, 409);
      }

      const rv = await refundPayment({
        referenceId,
        amountIqd: refundAmount,
        reason: buildRefundReason({
          kind: body.is_membership ? "membership" : "booking",
          referenceId,
          actorRole,
          amountIqd: refundAmount,
        }),
      }, cfg());
      if (!rv.ok) {
        console.log(`booking-action: refund declined id=${id} ref=${referenceId} desc=${rv.description}`);
        return json({ error: "Refund declined", description: rv.description }, 409);
      }

      // Money refunded — cancel + mark refunded. Concerts patch the whole group.
      const patchTarget = (!body.is_membership && row.group_id)
        ? `${table}?group_id=eq.${row.group_id}`
        : `${table}?id=eq.${id}`;
      try {
        await applyPatchWhere(SUPABASE_URL, svc, patchTarget, {
          status: "cancelled", payment_status: "refunded",
        });
      } catch (patchErr) {
        // The refund is already accepted at Wayl but the row didn't update.
        // Surface a distinct, loud signal for manual reconciliation — a plain
        // retry would submit a SECOND refund for the same reference.
        console.error(`booking-action: RECONCILE — refund accepted but cancel PATCH failed id=${id} target=${patchTarget}:`, patchErr);
        return json({ error: "Payment refunded but booking update failed — needs reconciliation", reconcile: true }, 500);
      }

      // Bookings notify via the status trigger; memberships have none, so push here.
      if (body.is_membership) {
        await notifyMembershipRefund(SUPABASE_URL, SUPABASE_ANON_KEY, id);
      }

      // Mark the Wayl webhook_logs row so the admin Transactions feed agrees.
      await markWebhookRefunded(SUPABASE_URL, svc, referenceId);

      console.log(`booking-action: refund+cancel ${table} id=${id} by=${uid} ref=${referenceId} status=${rv.status ?? "accepted"}`);
      return json({ success: true, status: "cancelled", refunded: true }, 200);
    }

    // Free / unpaid → plain cancel (drops it from the Transactions view too).
    await applyPatch(SUPABASE_URL, svc, table, id, {
      status: "cancelled", payment_status: "cancelled",
    });
    console.log(`booking-action: cancel ${table} id=${id} by=${uid}`);
    return json({ success: true, status: "cancelled" }, 200);

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("booking-action error:", msg);
    return json({ error: msg }, 500);
  }
});

/**
 * Mirrors bookings.is_merchant_staff_of() OR public.is_admin(), for a
 * service-role caller. Returns WHICH role authorized the call (null = neither)
 * so the generated Wayl refund reason can name the actor. Admin wins when the
 * caller happens to be both.
 */
async function resolveActorRole(
  supabaseUrl: string,
  svc: Record<string, string>,
  uid: string,
  merchantId: string | null,
): Promise<"admin" | "merchant" | null> {
  const [isAdmin, ...merchantChecks] = await Promise.all([
    exists(`${supabaseUrl}/rest/v1/admin_roles?user_id=eq.${uid}&select=user_id&limit=1`, svc, "admin"),
    ...(merchantId
      ? [
        // merchant owner
        exists(`${supabaseUrl}/rest/v1/merchants?user_id=eq.${uid}&id=eq.${merchantId}&select=id&limit=1`, svc, "business"),
        // merchant staff
        exists(`${supabaseUrl}/rest/v1/merchant_staff?user_id=eq.${uid}&merchant_id=eq.${merchantId}&select=user_id&limit=1`, svc, "business"),
      ]
      : []),
  ]);
  if (isAdmin) return "admin";
  return merchantChecks.some(Boolean) ? "merchant" : null;
}

/**
 * Total charged for a concert group. Every row in the group shares one payment
 * reference, so the refund amount is the SUM of the seats, not one seat's share.
 */
async function groupTotalIqd(
  supabaseUrl: string,
  svc: Record<string, string>,
  groupId: string,
): Promise<number> {
  const res = await fetch(
    `${supabaseUrl}/rest/v1/bookings?group_id=eq.${groupId}&payment_status=eq.paid&select=amount_iqd`,
    { headers: { ...svc, "Accept-Profile": "bookings" } },
  );
  if (!res.ok) return 0;
  const rows = await res.json() as Array<{ amount_iqd: number | null }>;
  return rows.reduce((sum, r) => sum + (r.amount_iqd ?? 0), 0);
}

/**
 * Flag the Wayl webhook_logs row as refunded. Best-effort: the money is already
 * back and the Transactions feed derives refund state from payment_status too,
 * so a failure here must not fail the request.
 */
async function markWebhookRefunded(
  supabaseUrl: string,
  svc: Record<string, string>,
  referenceId: string,
): Promise<void> {
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/webhook_logs?body->>referenceId=eq.${encodeURIComponent(referenceId)}`,
      { method: "PATCH", headers: { ...svc }, body: JSON.stringify({ refunded: true }) },
    );
    if (!res.ok) console.warn(`booking-action: webhook_logs refund flag failed (${res.status})`);
  } catch (e) {
    console.warn("booking-action: webhook_logs refund flag error:", e);
  }
}

async function exists(url: string, svc: Record<string, string>, schema: string): Promise<boolean> {
  try {
    const res = await fetch(url, { headers: { ...svc, "Accept-Profile": schema } });
    if (!res.ok) return false;
    const rows = await res.json() as unknown[];
    return Array.isArray(rows) && rows.length > 0;
  } catch { return false; }
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function serviceHeaders(serviceKey: string): Record<string, string> {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
    Prefer: "return=minimal",
  };
}

async function applyPatch(
  url: string, svc: Record<string, string>, table: string, id: string, patch: Record<string, string>,
): Promise<void> {
  await applyPatchWhere(url, svc, `${table}?id=eq.${id}`, patch);
}

async function applyPatchWhere(
  url: string, svc: Record<string, string>, target: string, patch: Record<string, string>,
): Promise<void> {
  const res = await fetch(`${url}/rest/v1/${target}`, {
    method: "PATCH",
    headers: {
      ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings",
      Prefer: "return=representation",
    },
    body: JSON.stringify(patch),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(`Update failed: ${res.status} ${JSON.stringify(err)}`);
  }
  const updated = await res.json() as unknown[];
  if (!Array.isArray(updated) || !updated.length) throw new Error("Update affected 0 rows");
}

/** Memberships have no status-change trigger — invoke booking-notification directly. */
async function notifyMembershipRefund(url: string, anonKey: string, membershipId: string): Promise<void> {
  try {
    await fetch(`${url}/functions/v1/booking-notification`, {
      method: "POST",
      headers: { "Content-Type": "application/json", apikey: anonKey, Authorization: `Bearer ${anonKey}` },
      body: JSON.stringify({ membership_id: membershipId, new_status: "cancelled" }),
    });
  } catch (e) {
    console.warn("booking-action: membership refund notification failed:", e);
  }
}
