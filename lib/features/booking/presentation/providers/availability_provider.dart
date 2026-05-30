import 'package:future_riverpod/features/booking/domain/models/court.dart';
import 'package:future_riverpod/features/booking/domain/models/event_tier.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';
import 'package:future_riverpod/features/booking/domain/models/restaurant_seating_option.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';
import 'package:future_riverpod/features/booking/domain/models/slot.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_layout.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_date_strip.dart';
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
Future<List<FarmShift>> farmShifts(Ref ref, String placeId, String date) =>
    ref.watch(bookingRepositoryProvider).fetchFarmShifts(placeId, date);

@riverpod
Future<Set<String>> placeClosedDates(Ref ref, String placeId) {
  final today = DateTime.now();
  final startDate = bookingFormatDate(today);
  final endDate = bookingFormatDate(today.add(const Duration(days: 89)));
  return ref.watch(bookingRepositoryProvider).fetchClosedDates(
    placeId: placeId,
    startDate: startDate,
    endDate: endDate,
  );
}

@riverpod
Future<List<RestaurantSeatingOption>> seatingOptions(
        Ref ref, String placeId) =>
    ref.watch(bookingRepositoryProvider).fetchSeatingOptions(placeId);

@riverpod
Future<List<MembershipPlan>> membershipPlans(Ref ref, String placeId) =>
    ref.watch(bookingRepositoryProvider).fetchMembershipPlans(placeId);

@riverpod
Future<List<Seat>> availableSeats(Ref ref, String eventId) =>
    ref.watch(bookingRepositoryProvider).fetchAvailableSeats(eventId);

@riverpod
Future<List<EventTier>> eventTiers(Ref ref, String eventId) =>
    ref.watch(bookingRepositoryProvider).fetchEventTiers(eventId);

@riverpod
Future<VenueLayout> venueLayout(Ref ref, String eventId) =>
    ref.watch(bookingRepositoryProvider).fetchVenueLayout(eventId);

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
