// lib/features/bookings_history/presentation/providers/tickets_provider.dart
//
// Thin wrapper around BookingRepository — kept separate for feature isolation.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/domain/repositories/tickets_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tickets_provider.g.dart';

/// Bump this counter to force all booking list providers to re-fetch.
/// keepAlive (non-autoDispose) so it survives navigation.
class _BookingsRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final bookingsRefreshProvider =
    NotifierProvider<_BookingsRefreshNotifier, int>(
  _BookingsRefreshNotifier.new,
);

@riverpod
Future<List<Booking>> userBookings(Ref ref, {List<String>? categories}) =>
    ref.watch(ticketsRepositoryProvider).fetchAll(categories: categories);

@riverpod
Future<List<Membership>> userMemberships(Ref ref) =>
    ref.watch(ticketsRepositoryProvider).fetchMemberships();

@riverpod
Future<Booking> bookingDetail(Ref ref, String id) =>
    ref.watch(ticketsRepositoryProvider).fetchOne(id);
