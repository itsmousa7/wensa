import 'package:future_riverpod/features/discounts/domain/models/merchant_discount.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantDiscountsRepository {
  const MerchantDiscountsRepository(this._client);
  final SupabaseClient _client;

  Future<List<MerchantDiscount>> fetchActive() async {
    final rows = await _client
        .schema('business')
        .from('merchant_discounts')
        .select()
        .eq('is_active', true);

    return (rows as List)
        .map((r) => MerchantDiscount.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
