import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome of a verify-payment call: whether HyperPay reported the payment
/// as paid, the gateway's result description (used to explain declines), and
/// the merchantTransactionId shown to users for support lookups.
class VerifyResult {
  const VerifyResult({
    required this.paid,
    this.description,
    this.merchantTransactionId,
  });

  final bool paid;
  final String? description;
  final String? merchantTransactionId;
}

/// Calls the verify-payment edge function, which checks the payment with
/// HyperPay server-side and flips the row to confirmed via user-scoped RPCs.
class HyperpayVerifyService {
  const HyperpayVerifyService();

  /// [kind] is one of: booking | concert_group | membership.
  /// [saveCard] asks the server to persist the card token for one-tap
  /// payments (only takes effect when the payment succeeds).
  Future<VerifyResult> verify({
    required String checkoutId,
    required String kind,
    required String id,
    required String referenceId,
    bool saveCard = false,
  }) async {
    final result = await Supabase.instance.client.functions.invoke(
      'verify-payment',
      body: {
        'checkout_id': checkoutId,
        'kind': kind,
        'id': id,
        'reference_id': referenceId,
        if (saveCard) 'save_card': true,
      },
    );
    if (result.status != 200) {
      throw Exception('verify-payment failed: ${result.data}');
    }
    final data = result.data as Map<String, dynamic>;
    return VerifyResult(
      paid: data['paid'] == true,
      description: data['description'] as String?,
      merchantTransactionId: data['merchant_transaction_id'] as String?,
    );
  }
}
