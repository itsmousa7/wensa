import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/discounts/domain/discount_math.dart';

void main() {
  group('computeDiscount', () {
    test('returns 10% of 40,000 with no cap', () {
      final r = computeDiscount(subtotal: 40000, percent: 10);
      expect(r.discountAmount, 4000);
      expect(r.finalAmount, 36000);
    });

    test('clamps to max cap', () {
      final r = computeDiscount(subtotal: 50000, percent: 30, maxCap: 5000);
      expect(r.discountAmount, 5000);
      expect(r.finalAmount, 45000);
    });

    test('does not clamp when below cap', () {
      final r = computeDiscount(subtotal: 10000, percent: 30, maxCap: 5000);
      expect(r.discountAmount, 3000);
      expect(r.finalAmount, 7000);
    });

    test('rounds to nearest integer IQD', () {
      final r = computeDiscount(subtotal: 9999, percent: 10);
      expect(r.discountAmount, 1000); // round(999.9)
      expect(r.finalAmount, 8999);
    });

    test('zero subtotal yields zero discount', () {
      final r = computeDiscount(subtotal: 0, percent: 25);
      expect(r.discountAmount, 0);
      expect(r.finalAmount, 0);
    });

    test('null cap is treated as no cap', () {
      final r = computeDiscount(subtotal: 100000, percent: 50, maxCap: null);
      expect(r.discountAmount, 50000);
      expect(r.finalAmount, 50000);
    });
  });
}
