import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/slot_availability.dart';
import 'package:future_riverpod/features/booking/presentation/sections/farm_section.dart';

void main() {
  group('computeShiftAvailability', () {
    final baseShift = FarmShift(
      placeId: 'place-1',
      shiftType: FarmShiftType.day,
      startsTime: '08:00:00',
      endsTime: '18:00:00',
      priceIqd: 100000,
      isAvailable: true,
      isClosed: false,
    );

    test('returns available when not today and shift is available', () {
      final result = computeShiftAvailability(baseShift, isToday: false);
      expect(result, SlotAvailability.available);
    });

    test('returns booked when not today and shift is unavailable', () {
      final shift = baseShift.copyWith(isAvailable: false);
      final result = computeShiftAvailability(shift, isToday: false);
      expect(result, SlotAvailability.booked);
    });

    test('returns closed when isClosed is true regardless of isAvailable', () {
      final shift = baseShift.copyWith(isClosed: true, isAvailable: false);
      final result = computeShiftAvailability(shift, isToday: false);
      expect(result, SlotAvailability.closed);
    });

    test('returns closed when isClosed is true on today', () {
      final shift = baseShift.copyWith(isClosed: true);
      final result = computeShiftAvailability(shift, isToday: true);
      expect(result, SlotAvailability.closed);
    });

    test('returns expired when today and shift starts far in the past', () {
      // Shift that started at midnight — guaranteed past
      final shift = baseShift.copyWith(startsTime: '00:00:00');
      final result = computeShiftAvailability(shift, isToday: true);
      expect(result, SlotAvailability.expired);
    });

    test('returns available or expired when today and shift starts at 23:59', () {
      // Shift that starts at 23:59 — not yet expired unless test runs at 23:59+ Baghdad time
      final shift = baseShift.copyWith(startsTime: '23:59:00');
      final result = computeShiftAvailability(shift, isToday: true);
      // Accept either to avoid flakiness
      expect(
        [SlotAvailability.available, SlotAvailability.expired],
        contains(result),
      );
    });
  });

  group('FarmShift.fromJson', () {
    test('parses isClosed correctly', () {
      final json = {
        'place_id': 'abc',
        'shift_type': 'day',
        'starts_time': '08:00:00',
        'ends_time': '18:00:00',
        'price_iqd': 100000,
        'is_available': false,
        'is_closed': true,
      };
      final shift = FarmShift.fromJson(json);
      expect(shift.isClosed, isTrue);
      expect(shift.isAvailable, isFalse);
    });

    test('defaults isClosed to false when not present in json', () {
      final json = {
        'place_id': 'abc',
        'shift_type': 'day',
        'starts_time': '08:00:00',
        'ends_time': '18:00:00',
        'price_iqd': 100000,
        'is_available': true,
      };
      final shift = FarmShift.fromJson(json);
      expect(shift.isClosed, isFalse);
    });
  });
}
