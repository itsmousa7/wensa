import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/presentation/providers/supabase_provider.dart';

/// Cached per-session signal of whether the current user has any prior
/// completed orders. Used to populate `p_is_first_purchase` and
/// `p_is_new_customer` when previewing promo codes.
///
/// Invalidate this provider (`ref.invalidate(userPurchaseHistoryProvider)`)
/// after a successful order so the next preview reflects the new state.
class PurchaseHistory {
  const PurchaseHistory({required this.bookingsCount, required this.membershipsCount});
  final int bookingsCount;
  final int membershipsCount;

  bool get hasAnyOrder => bookingsCount > 0 || membershipsCount > 0;

  bool hasOrderOfType(String orderType) {
    switch (orderType) {
      case 'bookings':
        return bookingsCount > 0;
      case 'memberships':
        return membershipsCount > 0;
      default:
        return false;
    }
  }
}

final userPurchaseHistoryProvider =
    FutureProvider<PurchaseHistory>((ref) async {
  final client = ref.watch(supabaseProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    return const PurchaseHistory(bookingsCount: 0, membershipsCount: 0);
  }
  final bookings = await client
      .from('bookings')
      .select('id')
      .eq('user_id', userId)
      .limit(1);
  final memberships = await client
      .from('memberships')
      .select('id')
      .eq('user_id', userId)
      .limit(1);
  return PurchaseHistory(
    bookingsCount: (bookings as List).length,
    membershipsCount: (memberships as List).length,
  );
});
