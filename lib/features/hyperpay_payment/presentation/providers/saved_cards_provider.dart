import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/saved_card.dart';

part 'saved_cards_provider.g.dart';

/// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
/// select/delete to the caller; inserts happen server-side (verify-payment).
@riverpod
class SavedCards extends _$SavedCards {
  static final _db = Supabase.instance.client;

  @override
  Future<List<SavedCard>> build() async {
    final user = _db.auth.currentUser;
    if (user == null) return const [];

    final rows = await _db
        .schema('bookings')
        .from('user_payment_tokens')
        .select('id, brand, last4, exp_month, exp_year, holder')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => SavedCard.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a saved card, updating state optimistically and restoring the
  /// previous list if the server delete fails.
  Future<void> deleteCard(String cardId) async {
    final previous = state.value ?? const <SavedCard>[];
    state = AsyncData(previous.where((c) => c.id != cardId).toList());
    try {
      await _db
          .schema('bookings')
          .from('user_payment_tokens')
          .delete()
          .eq('id', cardId);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
