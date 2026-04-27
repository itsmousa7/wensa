import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
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
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'padel',
          'place_id': placeId,
          'court_id': courtId,
          'starts_at': startsAt,
          'hours': hours,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String,
        holdUntil: data['hold_until'] as String,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  Future<void> createFarmBooking({
    required String placeId,
    required String date, // 'yyyy-MM-dd'
    required FarmShiftType shiftType,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'farm',
          'place_id': placeId,
          'date': date,
          'shift_type': shiftType.name,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String,
        holdUntil: data['hold_until'] as String,
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
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'restaurant',
          'place_id': placeId,
          'starts_at': startsAt,
          'party_size': partySize,
          'seating_option_id': ?seatingOptionId,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      // Restaurant returns booking_id only (no payment_url at this stage)
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: '', // no payment yet
        holdUntil: '', // no hold for restaurant
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  void reset() => state = const BookingSubmitState.idle();
}
