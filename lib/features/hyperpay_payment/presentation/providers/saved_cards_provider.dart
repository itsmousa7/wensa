import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/edge_function.dart';
import '../../domain/models/saved_card.dart';

part 'saved_cards_provider.g.dart';

/// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
/// select to the caller; inserts happen server-side (verify-payment) and
/// removal goes through the hyperpay-deregister-tokens edge function, which
/// revokes the token at the gateway before deleting the row.
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
        .select('id, brand, last4, exp_month, exp_year')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => SavedCard.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Removes a saved card, de-registering it at HyperPay first.
  ///
  /// This goes through the hyperpay-deregister-tokens edge function instead of
  /// deleting the row directly. The row is only OUR record of the card; the
  /// token itself lives at HyperPay and stays chargeable until OPPWA is told to
  /// de-register it. Deleting the row alone also throws away the registrationId,
  /// so the token could never be revoked afterwards. The function calls the
  /// gateway first and drops the row only once HyperPay confirms.
  ///
  /// State updates optimistically and is restored if anything refuses, so a card
  /// that is still live at the gateway never quietly vanishes from the list.
  Future<void> deleteCard(String cardId) async {
    final previous = state.value ?? const <SavedCard>[];
    state = AsyncData(previous.where((c) => c.id != cardId).toList());
    try {
      final res = await invokeEdgeFunction('hyperpay-deregister-tokens', {
        'scope': 'card',
        'target_id': cardId,
      });
      // A 200 does NOT mean the card is gone: the function reports per-card
      // gateway outcomes in its body and keeps the row for anything HyperPay
      // refused. "Nothing de-registered" is a failure, not a success.
      final deregistered = (res['deregistered'] as num?)?.toInt() ?? 0;
      if (deregistered < 1) {
        final failures = res['failures'] as List?;
        final reason = (failures != null && failures.isNotEmpty)
            ? (failures.first as Map)['description']
            : null;
        throw Exception(
          'Card was not de-registered at HyperPay${reason == null ? '' : ': $reason'}',
        );
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
