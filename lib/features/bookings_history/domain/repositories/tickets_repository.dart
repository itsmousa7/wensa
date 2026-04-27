// lib/features/bookings_history/domain/repositories/tickets_repository.dart
//
// Thin wrapper around BookingRepository — kept separate for feature isolation.

import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tickets_repository.g.dart';

class TicketsRepository {
  const TicketsRepository(this._repo);
  final BookingRepository _repo;

  Future<List<Booking>> fetchAll({BookingCategory? category}) =>
      _repo.fetchUserBookings(category: category);

  Future<Booking> fetchOne(String id) => _repo.fetchBooking(id);

  Future<List<Membership>> fetchMemberships() => _repo.fetchUserMemberships();
}

@riverpod
TicketsRepository ticketsRepository(Ref ref) =>
    TicketsRepository(ref.watch(bookingRepositoryProvider));
