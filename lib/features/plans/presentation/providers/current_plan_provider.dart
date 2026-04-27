import 'package:future_riverpod/features/plans/domain/models/merchant_plan_state.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_model.dart';
import 'package:future_riverpod/features/plans/domain/repositories/merchant_plan_repository.dart';
import 'package:future_riverpod/features/plans/domain/repositories/plans_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_plan_provider.g.dart';

/// All subscription plans (for the comparison page).
@riverpod
Future<List<PlanModel>> allPlans(Ref ref) =>
    ref.watch(plansRepositoryProvider).fetchAllPlans();

/// Current merchant's full plan state.
@riverpod
Future<MerchantPlanState> merchantPlanState(Ref ref, String merchantId) =>
    ref.watch(merchantPlanRepositoryProvider).fetchMerchantPlanState(merchantId);

/// Current combined item count (places + active events) for quota display.
@riverpod
Future<int> combinedItemCount(Ref ref, String merchantId) =>
    ref.watch(merchantPlanRepositoryProvider).fetchCombinedItemCount(merchantId);

/// Notifier that triggers a plan change and exposes the result.
/// UI checks [PlanChangeResult.paymentUrl] — if set, opens browser.
@riverpod
class PlanChanger extends _$PlanChanger {
  @override
  AsyncValue<PlanChangeResult?> build() => const AsyncData(null);

  Future<PlanChangeResult?> changePlan({
    required String merchantId,
    required String targetPlanId,
  }) async {
    state = const AsyncLoading();
    PlanChangeResult? result;
    state = await AsyncValue.guard(() async {
      result = await ref.read(merchantPlanRepositoryProvider).changePlan(
            merchantId:    merchantId,
            targetPlanId:  targetPlanId,
          );
      // If immediate change (downgrade), refresh cached state
      if (result?.planId != null) {
        ref.invalidate(merchantPlanStateProvider(merchantId));
        ref.invalidate(combinedItemCountProvider(merchantId));
      }
      return result;
    });
    return result;
  }
}
