import 'package:supabase_flutter/supabase_flutter.dart';

/// Re-validates and extends a booking/membership hold immediately before a
/// charge is attempted (bookings.lock_for_payment RPC). Single-row holds
/// (hourly/shift/reservation/general admission) last only 60 seconds, so
/// without this check a card charge can succeed at HyperPay after the hold
/// already expired — the user gets charged but confirm_payment silently
/// no-ops because the row is no longer 'pending'.
class BookingLockService {
  const BookingLockService();

  /// [kind] is one of: booking | concert_group | membership.
  /// Returns true when the hold is still the caller's and was extended.
  Future<bool> lockForPayment({
    required String kind,
    required String id,
  }) async {
    final result = await Supabase.instance.client.rpc(
      'lock_for_payment',
      params: {'p_kind': kind, 'p_id': id},
    );
    return result == true;
  }
}
