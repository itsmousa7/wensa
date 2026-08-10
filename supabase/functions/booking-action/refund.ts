/** Merchant cancel-with-refund window: 60 minutes from payment. */
export const REFUND_WINDOW_MS = 60 * 60 * 1000;

export function isWithinRefundWindow(paidAt: string | null, nowMs: number): boolean {
  if (!paidAt) return false;
  const t = Date.parse(paidAt);
  if (Number.isNaN(t)) return false;
  return nowMs - t < REFUND_WINDOW_MS;
}
