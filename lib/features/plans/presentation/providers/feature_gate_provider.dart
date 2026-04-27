import 'package:future_riverpod/features/plans/domain/feature_gate.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_model.dart';
import 'package:future_riverpod/features/plans/presentation/providers/current_plan_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_gate_provider.g.dart';

/// Returns the FeatureGate for a given merchant.
@riverpod
Future<FeatureGate> featureGate(Ref ref, String merchantId) async {
  final state = await ref.watch(merchantPlanStateProvider(merchantId).future);
  return FeatureGate(state.plan);
}

/// Can the merchant add another place or event?
/// [currentCombinedCount] = places + active events combined.
@riverpod
Future<bool> canAddItem(Ref ref, String merchantId, int currentCombinedCount) async {
  final gate = await ref.watch(featureGateProvider(merchantId).future);
  return gate.canAddItem(currentCombinedCount);
}

/// Can the merchant add another photo to a place?
@riverpod
Future<bool> canAddPhoto(Ref ref, String merchantId, int currentAdditionalCount) async {
  final gate = await ref.watch(featureGateProvider(merchantId).future);
  return gate.canAddPhoto(currentAdditionalCount);
}

/// FeatureGate from a plain PlanModel (no async needed).
FeatureGate gateFor(PlanModel plan) => FeatureGate(plan);
