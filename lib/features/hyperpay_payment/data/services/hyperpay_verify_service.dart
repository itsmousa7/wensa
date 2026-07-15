import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the verify-payment edge function, which checks the payment with
/// HyperPay server-side and flips the row to confirmed via user-scoped RPCs.
class HyperpayVerifyService {
  const HyperpayVerifyService();

  /// [kind] is one of: booking | concert_group | membership.
  /// Returns true when HyperPay reports the payment as paid.
  Future<bool> verify({
    required String checkoutId,
    required String kind,
    required String id,
    required String referenceId,
  }) async {
    final result = await Supabase.instance.client.functions.invoke(
      'verify-payment',
      body: {
        'checkout_id': checkoutId,
        'kind': kind,
        'id': id,
        'reference_id': referenceId,
      },
    );
    if (result.status != 200) {
      throw Exception('verify-payment failed: ${result.data}');
    }
    final data = result.data as Map<String, dynamic>;
    return data['paid'] == true;
  }
}
