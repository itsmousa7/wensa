/**
 * _shared/payments.ts — bookings.payment_transactions helpers.
 *
 * Mirror of wansa-admin-dashboard/supabase/functions/_shared/payments.ts —
 * both repos deploy functions into the same Supabase project and share the
 * table, so the row shape must stay in sync.
 *
 * One row per FINAL HyperPay result. checkout_id has a unique index; inserts
 * use resolution=ignore-duplicates so repeat finalizations are no-ops.
 * insertPaymentTransaction NEVER throws — a logging failure must not block
 * payment confirmation.
 */

export interface PaymentTxRow {
  intent: "booking" | "membership" | "plan" | "banner";
  reference_id: string | null;
  booking_id?: string | null;
  group_id?: string | null;
  membership_id?: string | null;
  merchant_id?: string | null;
  user_id?: string | null;
  amount_iqd?: number | null;
  status: "success" | "failed";
  result_code?: string | null;
  result_description?: string | null;
  unique_id?: string | null;
  merchant_transaction_id?: string | null;
  rrn?: string | null;
  clearing_institute_name?: string | null;
  card_scope?: "local" | "international" | null;
  payment_brand?: string | null;
  checkout_id: string;
}

const PROFILE = { "Accept-Profile": "bookings", "Content-Profile": "bookings" };

/**
 * Insert one FINAL payment result. NEVER throws — a logging failure must not
 * throw inside the payment path — but DOES report success/failure so callers
 * can escalate: losing the row for a CAPTURED payment is unrecoverable
 * (the OPPWA session is one-time read), so verify-payment turns `false` on a
 * paid result into a 500 with the full result logged.
 */
export async function insertPaymentTransaction(
  supabaseUrl: string,
  svc: Record<string, string>,
  row: PaymentTxRow,
): Promise<boolean> {
  try {
    // Explicit Content-Type: not every caller's svc headers include it, and
    // fetch defaults a string body to text/plain — PostgREST rejects that.
    const res = await fetch(`${supabaseUrl}/rest/v1/payment_transactions`, {
      method: "POST",
      headers: { ...svc, ...PROFILE, "Content-Type": "application/json", Prefer: "resolution=ignore-duplicates,return=minimal" },
      body: JSON.stringify(row),
    });
    if (!res.ok) {
      console.error(`insertPaymentTransaction failed (${res.status}):`, await res.text());
      return false;
    }
    return true;
  } catch (e) {
    console.error("insertPaymentTransaction error (non-fatal):", e);
    return false;
  }
}

/** Stamp local/international onto the paid row(s) so the dashboards can
 *  filter bookings/memberships without a payment_transactions join.
 *  kind uses the verify-payment/charge-saved-card vocabulary:
 *  "booking" | "concert_group" | "membership". Best-effort — never throws. */
export async function setCardScope(
  supabaseUrl: string,
  svc: Record<string, string>,
  kind: string,
  id: string,
  scope: "local" | "international" | null | undefined,
): Promise<void> {
  if (!scope) return;
  const target = kind === "membership"
    ? `memberships?id=eq.${encodeURIComponent(id)}`
    : kind === "concert_group"
      ? `bookings?group_id=eq.${encodeURIComponent(id)}`
      : `bookings?id=eq.${encodeURIComponent(id)}`;
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/${target}`, {
      method: "PATCH",
      headers: { ...svc, "Content-Type": "application/json", ...PROFILE },
      body: JSON.stringify({ card_scope: scope }),
    });
    if (!res.ok) {
      console.error(`setCardScope failed (${res.status}):`, await res.text().catch(() => ""));
    }
  } catch (e) {
    console.error("setCardScope error (non-fatal):", e);
  }
}

/**
 * Settle a DECLINED payment on the booking/membership row itself.
 *
 * MUST only be called for a FINAL non-success. A non-final code (000.200.* with
 * 3DS in flight, 800.120.100/900.* connector errors) may still have captured the
 * money, so those leave the row untouched — the isPending/isTransient guards at
 * the call sites are what make this safe.
 *
 * Without this the row keeps payment_status='pending' after a decline, so the
 * dashboards render a declined booking as Pending/Expired rather than Failed.
 *
 * The payment_status filter makes this a no-op against a row some other path
 * already settled as paid/refunded — a late decline must never cancel a booking
 * that was actually paid for. Best-effort: never throws.
 */
export async function markPaymentFailed(
  supabaseUrl: string,
  svc: Record<string, string>,
  kind: string,
  id: string,
): Promise<void> {
  // A concert group has no rows until the payment succeeds — nothing to settle.
  if (kind === "concert_group") return;
  const target = kind === "membership"
    ? `memberships?id=eq.${encodeURIComponent(id)}`
    : `bookings?id=eq.${encodeURIComponent(id)}`;
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/${target}&payment_status=eq.pending`,
      {
        method: "PATCH",
        headers: { ...svc, "Content-Type": "application/json", ...PROFILE },
        body: JSON.stringify({ payment_status: "failed", status: "cancelled" }),
      },
    );
    if (!res.ok) {
      console.error(`markPaymentFailed failed (${res.status}):`, await res.text().catch(() => ""));
    }
  } catch (e) {
    console.error("markPaymentFailed error (non-fatal):", e);
  }
}

export async function getPaymentTransactionByCheckout(
  supabaseUrl: string,
  svc: Record<string, string>,
  checkoutId: string,
): Promise<PaymentTxRow | null> {
  const res = await fetch(
    `${supabaseUrl}/rest/v1/payment_transactions?checkout_id=eq.${encodeURIComponent(checkoutId)}&select=*&limit=1`,
    { headers: { ...svc, "Accept-Profile": "bookings" } },
  );
  if (!res.ok) return null;
  const rows = await res.json() as PaymentTxRow[];
  return rows[0] ?? null;
}
