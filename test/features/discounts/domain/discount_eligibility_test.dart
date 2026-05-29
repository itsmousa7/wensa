import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/domain/models/merchant_discount.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';

void main() {
  final now = DateTime(2026, 5, 29, 12, 0);

  MerchantDiscount merchantDiscount({
    required String id,
    required String merchantId,
    bool appliesToAllPlaces = true,
    List<String> placeIds = const [],
    bool isActive = true,
    DateTime? startsAt,
    DateTime? expiresAt,
  }) =>
      MerchantDiscount(
        id: id,
        merchantId: merchantId,
        percent: 10,
        appliesToAllPlaces: appliesToAllPlaces,
        placeIds: placeIds,
        timeMode: 'all_day',
        hourSlots: const [],
        discountDates: const [],
        isActive: isActive,
        startsAt: startsAt,
        expiresAt: expiresAt,
      );

  AutoDiscount autoDiscount({
    required String scopeType,
    List<String> targetMerchantIds = const [],
    List<String> targetPlaceIds = const [],
    bool isActive = true,
    DateTime? startsAt,
    DateTime? endsAt,
  }) =>
      AutoDiscount(
        id: 'a1',
        name: 'test',
        percent: 5,
        appliesTo: const ['bookings'],
        scopeType: scopeType,
        targetCategoryIds: const [],
        targetMerchantIds: targetMerchantIds,
        targetPlaceIds: targetPlaceIds,
        isActive: isActive,
        startsAt: startsAt,
        endsAt: endsAt,
      );

  group('buildDiscountEligibility', () {
    test('empty inputs → isEmpty', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [],
        now: now,
      );
      expect(e.isEmpty, isTrue);
      expect(e.appWide, isFalse);
    });

    test('active merchant discount adds merchantId', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [merchantDiscount(id: 'd1', merchantId: 'm1')],
        autoDiscounts: [],
        now: now,
      );
      expect(e.merchantIds, contains('m1'));
      expect(e.appWide, isFalse);
    });

    test('inactive merchant discount is ignored', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [
          merchantDiscount(id: 'd1', merchantId: 'm1', isActive: false),
        ],
        autoDiscounts: [],
        now: now,
      );
      expect(e.isEmpty, isTrue);
    });

    test('expired merchant discount is ignored', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [
          merchantDiscount(
            id: 'd1',
            merchantId: 'm1',
            expiresAt: DateTime(2026, 5, 1),
          ),
        ],
        autoDiscounts: [],
        now: now,
      );
      expect(e.isEmpty, isTrue);
    });

    test('place-specific discount adds placeIds', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [
          merchantDiscount(
            id: 'd1',
            merchantId: 'm1',
            appliesToAllPlaces: false,
            placeIds: ['p1', 'p2'],
          ),
        ],
        autoDiscounts: [],
        now: now,
      );
      expect(e.merchantIds, contains('m1'));
      expect(e.placeIds, containsAll(['p1', 'p2']));
    });

    test('app-scope AutoDiscount → appWide = true', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [autoDiscount(scopeType: 'app')],
        now: now,
      );
      expect(e.appWide, isTrue);
    });

    test('targeted AutoDiscount adds merchant and place ids', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [
          autoDiscount(
            scopeType: 'targeted',
            targetMerchantIds: ['m2'],
            targetPlaceIds: ['p3'],
          ),
        ],
        now: now,
      );
      expect(e.merchantIds, contains('m2'));
      expect(e.placeIds, contains('p3'));
      expect(e.appWide, isFalse);
    });

    test('inactive AutoDiscount is ignored', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [autoDiscount(scopeType: 'app', isActive: false)],
        now: now,
      );
      expect(e.appWide, isFalse);
    });

    test('future AutoDiscount is ignored', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [
          autoDiscount(
            scopeType: 'app',
            startsAt: DateTime(2026, 6, 1),
          ),
        ],
        now: now,
      );
      expect(e.appWide, isFalse);
    });
  });
}
