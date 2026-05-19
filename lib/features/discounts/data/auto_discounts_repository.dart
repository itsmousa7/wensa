import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AutoDiscountsRepository {
  const AutoDiscountsRepository(this._client);
  final SupabaseClient _client;

  Future<List<AutoDiscount>> fetchActive() async {
    final rows = await _client
        .schema('business')
        .from('discounts')
        .select()
        .eq('is_active', true);
    return (rows as List)
        .map((r) => AutoDiscount.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
