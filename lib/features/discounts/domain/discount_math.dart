/// Pure helper for client-side discount math (display only — the server is
/// authoritative at redemption time).
class DiscountResult {
  const DiscountResult({required this.discountAmount, required this.finalAmount});
  final int discountAmount;
  final int finalAmount;
}

/// Applies [percent] to [subtotal] and clamps the resulting discount to
/// [maxCap] when provided. Amounts are integer IQD (matches the rest of the
/// app's price formatting).
DiscountResult computeDiscount({
  required int subtotal,
  required double percent,
  num? maxCap,
}) {
  if (subtotal <= 0 || percent <= 0) {
    return DiscountResult(discountAmount: 0, finalAmount: subtotal);
  }
  var discount = (subtotal * percent / 100).round();
  if (maxCap != null && discount > maxCap) {
    discount = maxCap.round();
  }
  if (discount > subtotal) discount = subtotal;
  return DiscountResult(discountAmount: discount, finalAmount: subtotal - discount);
}
