import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';

void main() {
  final base = {
    'id': 'd1',
    'name': '10% off',
    'percent': 10,
    'applies_to': ['bookings'],
    'scope_type': 'app',
    'target_category_ids': <String>[],
    'target_merchant_ids': <String>[],
    'target_place_ids': <String>[],
    'is_active': true,
  };

  group('AutoDiscount.fromJson', () {
    test('parses required + optional fields', () {
      final d = AutoDiscount.fromJson({
        ...base,
        'max_discount_amount': '5000',
        'starts_at': '2026-05-01T00:00:00Z',
        'ends_at': '2026-06-01T00:00:00Z',
      });
      expect(d.id, 'd1');
      expect(d.percent, 10);
      expect(d.maxDiscountAmount, 5000);
      expect(d.appliesTo, ['bookings']);
      expect(d.scopeType, 'app');
      expect(d.startsAt!.year, 2026);
    });

    test('handles missing optionals', () {
      final d = AutoDiscount.fromJson(base);
      expect(d.maxDiscountAmount, isNull);
      expect(d.startsAt, isNull);
      expect(d.endsAt, isNull);
    });

    test('parses percent when delivered as string (RPC quirk)', () {
      final d = AutoDiscount.fromJson({...base, 'percent': '15.5'});
      expect(d.percent, 15.5);
    });
  });

  group('appliesToOrder', () {
    final now = DateTime(2026, 5, 19);

    test('app-scope matches any place when order type is allowed', () {
      final d = AutoDiscount.fromJson(base);
      expect(
        d.appliesToOrder(
          orderType: 'bookings',
          placeId: 'p1', merchantId: 'm1', categoryId: 'c1',
          now: now,
        ),
        isTrue,
      );
    });

    test('rejects order type not in applies_to', () {
      final d = AutoDiscount.fromJson(base);
      expect(
        d.appliesToOrder(
          orderType: 'memberships',
          placeId: 'p1', merchantId: 'm1', categoryId: 'c1',
          now: now,
        ),
        isFalse,
      );
    });

    test('targeted with matching place_id', () {
      final d = AutoDiscount.fromJson({
        ...base,
        'scope_type': 'targeted',
        'target_place_ids': ['p1'],
      });
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: null, categoryId: null, now: now),
        isTrue,
      );
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p2', merchantId: null, categoryId: null, now: now),
        isFalse,
      );
    });

    test('targeted matches any of the three arrays', () {
      final d = AutoDiscount.fromJson({
        ...base,
        'scope_type': 'targeted',
        'target_merchant_ids': ['m9'],
      });
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: 'm9', categoryId: null, now: now),
        isTrue,
      );
    });

    test('targeted does not match when all caller ids are null', () {
      final d = AutoDiscount.fromJson({
        ...base,
        'scope_type': 'targeted',
        'target_place_ids': ['p1'],
      });
      expect(
        d.appliesToOrder(
          orderType: 'bookings',
          placeId: null,
          merchantId: null,
          categoryId: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('rejects when inactive', () {
      final d = AutoDiscount.fromJson({...base, 'is_active': false});
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: null, categoryId: null, now: now),
        isFalse,
      );
    });

    test('rejects when before starts_at', () {
      final d = AutoDiscount.fromJson({...base, 'starts_at': '2026-06-01T00:00:00Z'});
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: null, categoryId: null, now: now),
        isFalse,
      );
    });

    test('rejects when after ends_at', () {
      final d = AutoDiscount.fromJson({...base, 'ends_at': '2026-05-01T00:00:00Z'});
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: null, categoryId: null, now: now),
        isFalse,
      );
    });
  });
}
