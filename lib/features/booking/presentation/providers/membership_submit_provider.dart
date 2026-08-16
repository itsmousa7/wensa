import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'membership_submit_provider.g.dart';

String _friendlyErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('cash_disabled')) {
    return 'Cash payment is no longer available for this booking. Please choose E-Payment instead.';
  }
  return text;
}

@riverpod
class MembershipSubmit extends _$MembershipSubmit {
  @override
  BookingSubmitState build() => const BookingSubmitState.idle();

  Future<void> createMembership({
    required String placeId,
    required String planId,
    required PaymentMethod paymentMethod,
    String? promoCode,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-membership',
        body: {
          'place_id': placeId,
          'plan_id': planId,
          'payment_method': paymentMethod.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['membership_id'] as String,
        checkoutId: data['checkout_id'] as String? ?? '',
        holdUntil: '',
        referenceId: data['reference_id'] as String? ?? '',
        paymentMode: data['payment_mode'] as String? ?? 'TEST',
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(_friendlyErrorMessage(e));
    }
  }

  Future<void> freezeMembership(String id) async {
    state = const BookingSubmitState.loading();
    try {
      await ref.read(bookingRepositoryProvider).freezeMembership(id);
      state = const BookingSubmitState.idle();
    } catch (e) {
      state = BookingSubmitState.error(_friendlyErrorMessage(e));
    }
  }

  Future<void> resumeMembership(String id) async {
    state = const BookingSubmitState.loading();
    try {
      await ref.read(bookingRepositoryProvider).resumeMembership(id);
      state = const BookingSubmitState.idle();
    } catch (e) {
      state = BookingSubmitState.error(_friendlyErrorMessage(e));
    }
  }

  void reset() => state = const BookingSubmitState.idle();
}
