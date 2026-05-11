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
}
