import 'package:future_riverpod/features/booking/domain/models/court.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/restaurant_seating_option.dart';
import 'package:future_riverpod/features/booking/domain/models/slot.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'availability_provider.g.dart';

@riverpod
Future<List<Court>> courts(Ref ref, String placeId) =>
    ref.watch(bookingRepositoryProvider).fetchCourts(placeId);

@riverpod
Future<List<Slot>> availableSlots(
  Ref ref, {
  required String courtId,
  required String date, // 'yyyy-MM-dd'
}) =>
    ref.watch(bookingRepositoryProvider).fetchAvailableSlots(
      courtId: courtId,
      date: date,
    );

@riverpod
Future<List<FarmShift>> farmShifts(Ref ref, String placeId) =>
    ref.watch(bookingRepositoryProvider).fetchFarmShifts(placeId);

@riverpod
Future<List<RestaurantSeatingOption>> seatingOptions(
        Ref ref, String placeId) =>
    ref.watch(bookingRepositoryProvider).fetchSeatingOptions(placeId);

/// Generates 30-minute time slots from 10:00 to 22:00 (Asia/Baghdad, UTC+3).
/// Returns ISO datetime strings stored as UTC (Baghdad - 3h).
@riverpod
List<String> restaurantTimeSlots(Ref ref, String date) {
  final slots = <String>[];
  final d = DateTime.parse(date);
  for (int h = 10; h < 22; h++) {
    for (int m = 0; m < 60; m += 30) {
      // Store as UTC (Baghdad is UTC+3, so subtract 3h)
      slots.add(DateTime.utc(d.year, d.month, d.day, h - 3, m).toIso8601String());
    }
  }
  return slots;
}
