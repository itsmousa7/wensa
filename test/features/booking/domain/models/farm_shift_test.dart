import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';

void main() {
  group('FarmShift.fromJson', () {
    const baseJson = {
      'place_id': 'place-abc',
      'shift_type': 'day',
      'starts_time': '08:00:00',
      'ends_time': '18:00:00',
      'price_iqd': 100000,
    };

    test('parses is_available true', () {
      final shift = FarmShift.fromJson({...baseJson, 'is_available': true});
      expect(shift.isAvailable, isTrue);
    });

    test('parses is_available false', () {
      final shift = FarmShift.fromJson({...baseJson, 'is_available': false});
      expect(shift.isAvailable, isFalse);
    });

    test('defaults isAvailable to true when field is absent', () {
      final shift = FarmShift.fromJson(baseJson);
      expect(shift.isAvailable, isTrue);
    });
  });

  group('FarmShift.fromJson party fields', () {
    const baseJson = {
      'place_id': 'place-abc',
      'shift_type': 'day',
      'starts_time': '08:00:00',
      'ends_time': '18:00:00',
      'price_iqd': 100000,
    };

    test('parses party fields when present', () {
      final shift = FarmShift.fromJson({
        ...baseJson,
        'party_enabled': true,
        'party_included_persons': 10,
        'party_flat_fee_iqd': 20000,
        'party_extra_person_fee_iqd': 5000,
      });
      expect(shift.partyEnabled, isTrue);
      expect(shift.partyIncludedPersons, 10);
      expect(shift.partyFlatFeeIqd, 20000);
      expect(shift.partyExtraPersonFeeIqd, 5000);
    });

    test('defaults party fields when absent', () {
      final shift = FarmShift.fromJson(baseJson);
      expect(shift.partyEnabled, isFalse);
      expect(shift.partyIncludedPersons, 1);
      expect(shift.partyFlatFeeIqd, 0);
      expect(shift.partyExtraPersonFeeIqd, 0);
    });
  });

  group('FarmShift.fromJson price override', () {
    const baseJson = {
      'place_id': 'place-abc',
      'shift_type': 'day',
      'starts_time': '08:00:00',
      'ends_time': '18:00:00',
      'price_iqd': 250000,
    };

    test('parses standard_price_iqd when an override is active', () {
      final shift = FarmShift.fromJson({
        ...baseJson,
        'standard_price_iqd': 200000,
      });
      expect(shift.priceIqd, 250000);
      expect(shift.standardPriceIqd, 200000);
    });

    test('standardPriceIqd defaults to null when absent (no override)', () {
      final shift = FarmShift.fromJson(baseJson);
      expect(shift.standardPriceIqd, isNull);
    });
  });
}
