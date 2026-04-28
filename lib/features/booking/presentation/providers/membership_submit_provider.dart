import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'membership_submit_provider.g.dart';

@riverpod
class MembershipSubmit extends _$MembershipSubmit {
  @override
  BookingSubmitState build() => const BookingSubmitState.idle();

  Future<void> createMembership({
    required String placeId,
    required String planId,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'membership',
          'place_id': placeId,
          'plan_id': planId,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String,
        holdUntil: '',
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  Future<void> freezeMembership(String id) async {
    state = const BookingSubmitState.loading();
    try {
      await ref.read(bookingRepositoryProvider).freezeMembership(id);
      state = const BookingSubmitState.idle();
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  Future<void> resumeMembership(String id) async {
    state = const BookingSubmitState.loading();
    try {
      await ref.read(bookingRepositoryProvider).resumeMembership(id);
      state = const BookingSubmitState.idle();
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }

  void reset() => state = const BookingSubmitState.idle();
}
