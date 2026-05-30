import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/presentation/providers/supabase_provider.dart';

/// Cached per-session signal of the user's prior orders, used to populate
/// `p_is_first_purchase_at_place` and `p_is_new_customer` when previewing
/// promo codes (mirrors what the create-booking / create-membership edge
/// functions compute server-side at redemption time).
///
/// Keyed by `placeId` so we can answer "is this the user's first purchase at
/// this place?". `placeId == null` skips the per-place query and treats
/// `isFirstPurchaseAtPlace` as false (matches the server's behavior).
///
/// Invalidate this provider (`ref.invalidate(userPurchaseHistoryProvider)`)
/// after a successful order so the next preview reflects the new state.
class PurchaseHistory {
  const PurchaseHistory({
    required this.hasAnyOrder,
    required this.hasOrderAtPlace,
  });

  /// True if the user has at least one prior booking or membership anywhere.
  final bool hasAnyOrder;

  /// True if the user has at least one prior booking or membership at the
  /// queried place. Always false when `placeId` is null.
  final bool hasOrderAtPlace;

  bool get isNewCustomer => !hasAnyOrder;
  bool get isFirstPurchaseAtPlace => !hasOrderAtPlace;
}

final userPurchaseHistoryProvider =
    FutureProvider.family<PurchaseHistory, String?>((ref, placeId) async {
  final client = ref.watch(supabaseProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    return const PurchaseHistory(hasAnyOrder: false, hasOrderAtPlace: false);
  }

  final bookingsAny = client
      .schema('bookings')
      .from('bookings')
      .select('id')
      .eq('user_id', userId)
      .limit(1);
  final membershipsAny = client
      .schema('bookings')
      .from('memberships')
      .select('id')
      .eq('user_id', userId)
      .limit(1);

  final bookingsAtPlace = placeId == null
      ? Future.value(const <Map<String, dynamic>>[])
      : client
          .schema('bookings')
          .from('bookings')
          .select('id')
          .eq('user_id', userId)
          .eq('place_id', placeId)
          .limit(1);
  final membershipsAtPlace = placeId == null
      ? Future.value(const <Map<String, dynamic>>[])
      : client
          .schema('bookings')
          .from('memberships')
          .select('id')
          .eq('user_id', userId)
          .eq('place_id', placeId)
          .limit(1);

  final results = await Future.wait([
    bookingsAny,
    membershipsAny,
    bookingsAtPlace,
    membershipsAtPlace,
  ]);
  final hasAnyOrder =
      (results[0] as List).isNotEmpty || (results[1] as List).isNotEmpty;
  final hasOrderAtPlace = placeId != null &&
      ((results[2] as List).isNotEmpty || (results[3] as List).isNotEmpty);

  return PurchaseHistory(
    hasAnyOrder: hasAnyOrder,
    hasOrderAtPlace: hasOrderAtPlace,
  );
});
