import 'package:freezed_annotation/freezed_annotation.dart';
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

  void reset() => state = const BookingSubmitState.idle();
}
