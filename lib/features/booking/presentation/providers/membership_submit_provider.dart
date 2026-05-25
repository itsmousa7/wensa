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
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['membership_id'] as String,
        paymentUrl: data['payment_url'] as String? ?? '',
        holdUntil: '',
        waylReferenceId: data['reference_id'] as String? ?? '',
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

  /// Cancels any pending membership row server-side, keeping the Proceed
  /// button disabled (state = loading) until the cancel completes. Mirrors
  /// [BookingSubmit.cancelPending] — see that doc comment for rationale.
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
      // cancel_booking only operates on the bookings table; memberships live
      // in their own table and need cancel_membership. Without this call the
      // pending row would survive until the memberships_expire_pending cron
      // sweeps it ~1 minute later.
      await ref.read(bookingRepositoryProvider).cancelMembership(bookingId);
    } catch (_) {}
    state = const BookingSubmitState.idle();
  }
}
