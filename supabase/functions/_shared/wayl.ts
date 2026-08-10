/**
 * _shared/wayl.ts — Wayl gateway helpers (payment links + refunds).
 *
 * Env vars required (Supabase Edge Function secrets):
 *   WAYL_API_KEY — sent as the X-WAYL-AUTHENTICATION header
 *   WAYL_BASE    — optional; defaults to https://api.thewayl.com
 *
 * REFUND RULE:
 *   POST /api/v1/refunds { referenceId, reason, amount } → 2xx means Wayl
 *   accepted the refund request. `reason` is validated by Wayl at 100–1500
 *   characters, so automated callers must build one with buildRefundReason()
 *   rather than passing a short string.
 *
 * Unlike HyperPay's RV (an immediate void keyed on the gateway's unique_id),
 * a Wayl refund is keyed on OUR referenceId — the same value stored as
 * bookings.payment_id — and settles asynchronously on Wayl's side.
 */

export interface WaylConfig {
  apiKey: string;
  base: string;
}

export function cfg(): WaylConfig {
  const apiKey = Deno.env.get("WAYL_API_KEY");
  if (!apiKey) throw new Error("WAYL_API_KEY not configured");
  const base = Deno.env.get("WAYL_BASE") ?? "https://api.thewayl.com";
  return { apiKey, base };
}

// ── Refunds ──────────────────────────────────────────────────────────────────

/** Wayl rejects a refund whose reason falls outside these bounds. */
export const REFUND_REASON_MIN = 100;
export const REFUND_REASON_MAX = 1500;

export interface RefundReasonInput {
  /** What is being refunded. */
  kind: "booking" | "membership";
  /** Our payment reference (bookings.payment_id). */
  referenceId: string;
  /** Who triggered it — shown to Wayl's support/ops for dispute context. */
  actorRole: "merchant" | "admin";
  amountIqd: number;
}

/**
 * Build a refund reason that always satisfies Wayl's 100–1500 char rule.
 *
 * The merchant-facing button collects no free text (it's a one-click cancel
 * inside the 1-hour window), so the reason is generated. It is padded with a
 * policy explanation rather than filler so the text stays useful to whoever
 * reads it on Wayl's side.
 */
export function buildRefundReason(o: RefundReasonInput): string {
  const actor = o.actorRole === "admin" ? "a Wansa administrator" : "the merchant";
  const base =
    `Customer ${o.kind} cancelled by ${actor} through the Wansa dashboard within the ` +
    `one-hour post-payment cancellation window. Reference ${o.referenceId}, ` +
    `amount ${o.amountIqd} IQD. The ${o.kind} has been cancelled and the reserved ` +
    `capacity released, so the full amount is returned to the customer under the ` +
    `Wansa cancellation policy. This refund was submitted automatically by the ` +
    `Wansa platform at the moment of cancellation and requires no further action.`;

  // Defensive: the template above is comfortably over the minimum, but a very
  // short referenceId must never be able to push it under.
  const padded = base.length >= REFUND_REASON_MIN
    ? base
    : base + " ".repeat(REFUND_REASON_MIN - base.length);

  return padded.slice(0, REFUND_REASON_MAX);
}

export interface RefundResult {
  ok: boolean;
  /** Wayl's refund status when it accepted the request. */
  status?: string;
  refundId?: string;
  /** Human-readable failure text, safe to log. */
  description?: string;
}

/**
 * Submit a full refund to Wayl for one payment reference.
 *
 * `amountIqd` must be the amount actually charged for that reference — for a
 * concert group that is the GROUP total, not one seat's share.
 */
export async function refundPayment(
  o: { referenceId: string; amountIqd: number; reason: string },
  c: WaylConfig,
): Promise<RefundResult> {
  if (o.reason.length < REFUND_REASON_MIN || o.reason.length > REFUND_REASON_MAX) {
    return {
      ok: false,
      description: `reason must be ${REFUND_REASON_MIN}–${REFUND_REASON_MAX} characters (got ${o.reason.length})`,
    };
  }
  if (!(o.amountIqd > 0)) {
    return { ok: false, description: `amount must be positive (got ${o.amountIqd})` };
  }

  let res: Response;
  try {
    res = await fetch(`${c.base}/api/v1/refunds`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-WAYL-AUTHENTICATION": c.apiKey,
      },
      body: JSON.stringify({
        referenceId: o.referenceId,
        reason: o.reason,
        amount: o.amountIqd,
      }),
    });
  } catch (e) {
    // Network failure — no refund was created, so the caller must NOT cancel.
    return { ok: false, description: e instanceof Error ? e.message : "Wayl request failed" };
  }

  const body = await res.json().catch(() => ({})) as {
    data?: { id?: string; status?: string };
    message?: string;
  };

  if (!res.ok) {
    return {
      ok: false,
      description: body?.message ?? `Wayl refund failed: HTTP ${res.status}`,
    };
  }

  return { ok: true, status: body?.data?.status, refundId: body?.data?.id };
}
