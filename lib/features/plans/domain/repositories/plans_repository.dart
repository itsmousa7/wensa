import 'package:future_riverpod/features/plans/domain/models/plan_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'plans_repository.g.dart';

class PlansRepository {
  const PlansRepository(this._client);
  final SupabaseClient _client;

  Future<List<PlanModel>> fetchAllPlans() async {
    final data = await _client
        .schema('business')
        .from('plans')
        .select()
        .order('sort_order', ascending: true);
    return (data as List).map((e) => PlanModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PlanModel> fetchPlan(String planId) async {
    final data = await _client
        .schema('business')
        .from('plans')
        .select()
        .eq('id', planId)
        .single();
    return PlanModel.fromJson(data);
  }
}

@riverpod
PlansRepository plansRepository(Ref ref) =>
    PlansRepository(Supabase.instance.client);
