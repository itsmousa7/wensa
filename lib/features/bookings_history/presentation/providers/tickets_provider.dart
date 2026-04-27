// lib/features/bookings_history/presentation/providers/tickets_provider.dart

import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/domain/repositories/tickets_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tickets_provider.g.dart';

@riverpod
Future<List<Booking>> userBookings(Ref ref, {BookingCategory? category}) =>
    ref.watch(ticketsRepositoryProvider).fetchAll(category: category);

@riverpod
Future<List<Membership>> userMemberships(Ref ref) =>
    ref.watch(ticketsRepositoryProvider).fetchMemberships();

@riverpod
Future<Booking> bookingDetail(Ref ref, String id) =>
    ref.watch(ticketsRepositoryProvider).fetchOne(id);
