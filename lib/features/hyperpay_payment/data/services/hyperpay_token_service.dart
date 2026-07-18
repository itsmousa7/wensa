import 'edge_function.dart';

/// Calls the charge-saved-card edge function: a server-to-server HyperPay
/// charge on a stored card token that also confirms the booking/membership
/// (same user-scoped RPCs as verify-payment). No card form, no 3DS.
class HyperpayTokenService {
  const HyperpayTokenService();

  /// [kind] is one of: booking | concert_group | membership.
  /// Returns (paid, description, merchantTransactionId): `paid` is true when
  /// the charge succeeded; `description` carries HyperPay's failure text when
  /// it did not; `merchantTransactionId` is the gateway-side id shown to the
  /// user for support lookups.
  Future<({bool paid, String? description, String? merchantTransactionId})>
  chargeSavedCard({
    required String tokenId,
    required String kind,
    required String id,
    required String referenceId,
  }) async {
    final data = await invokeEdgeFunction('charge-saved-card', {
      'token_id': tokenId,
      'kind': kind,
      'id': id,
      'reference_id': referenceId,
    });
    return (
      paid: data['paid'] == true,
      description: data['description'] as String?,
      merchantTransactionId: data['merchant_transaction_id'] as String?,
    );
  }
}
