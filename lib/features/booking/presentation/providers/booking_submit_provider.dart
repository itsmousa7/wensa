import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'booking_submit_provider.freezed.dart';
part 'booking_submit_provider.g.dart';

String _friendlyErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('cash_disabled')) {
    return 'Cash payment is no longer available for this booking. Please choose E-Payment instead.';
  }
  return text;
}

@freezed
abstract class BookingSubmitState with _$BookingSubmitState {
  const factory BookingSubmitState.idle() = _Idle;
  const factory BookingSubmitState.loading() = _Loading;
  const factory BookingSubmitState.success({
    required String bookingId,
    // HyperPay checkout session id — the native mSDK submits the card against
    // this. Empty when the booking was confirmed by cash.
    required String checkoutId,
    required String holdUntil,
    // Our own reference (e.g. "booking_{uuid}_{ts}"), persisted as
    // bookings.payment_id and passed back to verify-payment. NOT the
    // merchantTransactionId sent to the gateway, and NOT bookingId.
    required String referenceId,
    // "LIVE" | "TEST" — selects the mSDK's environment.
    @Default('TEST') String paymentMode,
    // True when the booking was confirmed via cash (no checkout exists).
    @Default(false) bool cash,
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
    required PaymentMethod paymentMethod,
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
          'payment_method': paymentMethod.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        checkoutId: data['checkout_id'] as String? ?? '',
        holdUntil: data['hold_until'] as String? ?? '',
        referenceId: data['reference_id'] as String? ?? '',
        paymentMode: data['payment_mode'] as String? ?? 'TEST',
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(_friendlyErrorMessage(e));
    }
  }

  Future<void> createFarmBooking({
    required String placeId,
    required String date, // 'yyyy-MM-dd'
    required FarmShiftType shiftType,
    required PaymentMethod paymentMethod,
    String? promoCode,
    int? partySize,
    bool bringingParty = false,
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
          'payment_method': paymentMethod.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
          if (partySize case int s) 'party_size': s,
          'bringing_party': bringingParty,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        checkoutId: data['checkout_id'] as String? ?? '',
        holdUntil: data['hold_until'] as String? ?? '',
        referenceId: data['reference_id'] as String? ?? '',
        paymentMode: data['payment_mode'] as String? ?? 'TEST',
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(_friendlyErrorMessage(e));
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
        checkoutId: data['checkout_id'] as String? ?? '',
        holdUntil: '',
        referenceId: data['reference_id'] as String? ?? '',
        paymentMode: data['payment_mode'] as String? ?? 'TEST',
      );
    } catch (e) {
      state = BookingSubmitState.error(_friendlyErrorMessage(e));
    }
  }

  /// Creates a pending general-admission booking (no seat picking) and
  /// returns a HyperPay checkout id. verify-payment flips the row to
  /// confirmed once the gateway reports the payment as captured.
  Future<void> createGeneralAdmissionBooking({
    required String eventId,
    required String sectionId,
    required int quantity,
    required PaymentMethod paymentMethod,
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
          'payment_method': paymentMethod.name,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: (data['booking_id'] ?? '') as String,
        checkoutId: (data['checkout_id'] ?? '') as String,
        holdUntil: (data['hold_until'] ?? '') as String? ?? '',
        referenceId: (data['reference_id'] ?? '') as String,
        paymentMode: (data['payment_mode'] ?? 'TEST') as String,
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(_friendlyErrorMessage(e));
    }
  }

  Future<void> createConcertBooking({
    required String eventId,
    required List<String> seatIds,
    required PaymentMethod paymentMethod,
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
          'payment_method': paymentMethod.name,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      // Concerts return group_id (not booking_id) — use group_id as bookingId
      state = BookingSubmitState.success(
        bookingId: (data['group_id'] ?? data['booking_id'] ?? '') as String,
        checkoutId: (data['checkout_id'] ?? '') as String,
        holdUntil: (data['hold_until'] ?? '') as String? ?? '',
        referenceId: (data['reference_id'] ?? '') as String,
        paymentMode: (data['payment_mode'] ?? 'TEST') as String,
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(_friendlyErrorMessage(e));
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
      success: (id, _, _, _, _, _) => id,
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
