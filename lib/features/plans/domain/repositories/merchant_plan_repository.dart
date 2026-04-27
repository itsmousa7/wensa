import 'package:future_riverpod/features/plans/domain/models/merchant_plan_state.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_model.dart';
import 'package:future_riverpod/features/plans/domain/repositories/plans_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'merchant_plan_repository.g.dart';

/// Returned by [changePlan].
/// [paymentUrl] is non-null when a Wayl payment link must be opened.
/// [planId] is non-null when the change was applied immediately (downgrade).
class PlanChangeResult {
  const PlanChangeResult({this.paymentUrl, this.referenceId, this.planId});

  final String? paymentUrl;   // open this in browser for paid upgrades
  final String? referenceId;  // Wayl referenceId for tracking
  final String? planId;       // set for immediate downgrades
}

class MerchantPlanRepository {
  const MerchantPlanRepository(this._client, this._plansRepo);
  final SupabaseClient _client;
  final PlansRepository _plansRepo;

  Future<MerchantPlanState> fetchMerchantPlanState(String merchantId) async {
    final data = await _client
        .schema('business')
        .from('merchants')
        .select(
          'id, plan_id, plan_activated_at, plan_expires_at, '
          'banner_trial_days_remaining, quarterly_slots_used',
        )
        .eq('id', merchantId)
        .single();

    final planId = data['plan_id'] as String? ?? 'basic';
    PlanModel plan;
    try {
      plan = await _plansRepo.fetchPlan(planId);
    } catch (_) {
      plan = PlanModel.fallbackBasic;
    }

    return MerchantPlanState.fromJson(data as Map<String, dynamic>, plan);
  }

  /// Calls `plans-change` edge function.
  /// Returns a [PlanChangeResult] — caller must check whether a payment URL is set.
  Future<PlanChangeResult> changePlan({
    required String merchantId,
    required String targetPlanId,
  }) async {
    final res = await _client.functions.invoke(
      'plans-change',
      body: {'merchant_id': merchantId, 'target_plan_id': targetPlanId},
    );
    final body = res.data as Map<String, dynamic>?;

    if (body == null || body['success'] != true) {
      throw Exception(body?['error'] ?? 'Plan change failed');
    }

    // Paid upgrade → Wayl payment link returned
    if (body['payment_url'] != null) {
      return PlanChangeResult(
        paymentUrl:  body['payment_url'] as String,
        referenceId: body['reference_id'] as String?,
      );
    }

    // Immediate (downgrade / already free)
    return PlanChangeResult(planId: body['plan_id'] as String?);
  }

  /// Fetches the current combined item count (places + active events) for quota display.
  Future<int> fetchCombinedItemCount(String merchantId) async {
    final result = await _client.rpc(
      'get_combined_item_count',
      params: {'p_merchant_id': merchantId},
    );
    return (result as num?)?.toInt() ?? 0;
  }
}

@riverpod
MerchantPlanRepository merchantPlanRepository(Ref ref) => MerchantPlanRepository(
      Supabase.instance.client,
      ref.watch(plansRepositoryProvider),
    );
