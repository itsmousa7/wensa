import 'package:future_riverpod/features/booking/domain/models/court.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
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
