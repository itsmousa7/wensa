import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'booking_submit_provider.freezed.dart';
part 'booking_submit_provider.g.dart';

@freezed
abstract class BookingSubmitState with _$BookingSubmitState {
  const factory BookingSubmitState.idle() = _Idle;
  const factory BookingSubmitState.loading() = _Loading;
  const factory BookingSubmitState.success({
    required String bookingId,
    required String paymentUrl,
    required String holdUntil,
    // Wayl referenceId (e.g. "booking_{uuid}_{ts}") — use this for polling,
    // NOT bookingId which is just the raw UUID.
    required String waylReferenceId,
  }) = _Success;
  const factory BookingSubmitState.error(String message) = _Error;
}

@riverpod
class BookingSubmit extends _$BookingSubmit {
  @override
  BookingSubmitState build() => const BookingSubmitState.idle();

  Future<void> createPadelBooking({
    required String placeId,
    required String courtId,
    required String startsAt, // ISO datetime string
    required int hours,
    String? promoCode,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'hourly',
          'place_id': placeId,
          'court_id': courtId,
          'starts_at': startsAt,
          'hours': hours,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String,
        holdUntil: data['hold_until'] as String? ?? '',
        waylReferenceId: data['reference_id'] as String,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  Future<void> createFarmBooking({
    required String placeId,
    required String date, // 'yyyy-MM-dd'
    required FarmShiftType shiftType,
    String? promoCode,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'shift',
          'place_id': placeId,
          'date': date,
          'shift_type': shiftType.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String,
        holdUntil: data['hold_until'] as String? ?? '',
        waylReferenceId: data['reference_id'] as String,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  Future<void> createRestaurantBooking({
    required String placeId,
    required String startsAt, // ISO datetime
    required int partySize,
    String? seatingOptionId,
    String? promoCode,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'reservation',
          'place_id': placeId,
          'starts_at': startsAt,
          'party_size': partySize,
          'seating_option_id': ?seatingOptionId,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String? ?? '',
        holdUntil: '',
        waylReferenceId: data['reference_id'] as String? ?? '',
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  /// Creates a pending general-admission booking (no seat picking) and
  /// returns a Wayl payment URL. The webhook flips the row to confirmed
  /// on payment success.
  Future<void> createGeneralAdmissionBooking({
    required String eventId,
    required String sectionId,
    required int quantity,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'general_admission',
          'event_id': eventId,
          'section_id': sectionId,
          'quantity': quantity,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: (data['booking_id'] ?? '') as String,
        paymentUrl: (data['payment_url'] ?? '') as String,
        holdUntil: (data['hold_until'] ?? '') as String? ?? '',
        waylReferenceId: (data['reference_id'] ?? '') as String,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  Future<void> createConcertBooking({
    required String eventId,
    required List<String> seatIds,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'venue_seat',
          'event_id': eventId,
          'seat_ids': seatIds,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      // Concerts return group_id (not booking_id) — use group_id as bookingId
      state = BookingSubmitState.success(
        bookingId: (data['group_id'] ?? data['booking_id'] ?? '') as String,
        paymentUrl: data['payment_url'] as String,
        holdUntil: data['hold_until'] as String? ?? '',
        waylReferenceId: data['reference_id'] as String,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  void reset() => state = const BookingSubmitState.idle();

  /// Cancels all pending rows for a concert group and releases seat holds.
  /// Use this instead of [cancelPending] for concert bookings because the
  /// concert success state stores the group_id, not an individual booking id.
  Future<void> cancelConcertGroup(String groupId) async {
    if (groupId.isEmpty) {
      state = const BookingSubmitState.idle();
      return;
    }
    state = const BookingSubmitState.loading();
    try {
      await ref.read(bookingRepositoryProvider).cancelConcertGroup(groupId);
    } catch (_) {
      // Non-fatal: the 3-minute cron will expire the pending rows anyway.
    }
    state = const BookingSubmitState.idle();
  }

  /// Cancels any pending booking row server-side, keeping the Proceed
  /// button disabled (state = loading) until the cancel completes. This
  /// avoids a race where the user re-taps "Proceed" before the prior
  /// `pending` row is released and hits the no-overlap exclusion constraint.
  Future<void> cancelPending() async {
    final current = state;
    final bookingId = current.maybeWhen(
      success: (id, _, _, _) => id,
      orElse: () => null,
    );
    if (bookingId == null || bookingId.isEmpty) {
      state = const BookingSubmitState.idle();
      return;
    }
    state = const BookingSubmitState.loading();
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(bookingId);
    } catch (_) {
      // Non-fatal: the server-side hold expires on its own.
    }
    state = const BookingSubmitState.idle();
  }
}
