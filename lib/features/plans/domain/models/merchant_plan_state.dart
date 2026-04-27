import 'plan_model.dart';
import 'plan_tier.dart';

class MerchantPlanState {
  const MerchantPlanState({
    required this.merchantId,
    required this.plan,
    this.planActivatedAt,
    this.planExpiresAt,
    required this.bannerTrialDaysRemaining,
    required this.quarterlySlotsUsed,
    this.quarterlySlotsTotalForPlan,
  });

  final String      merchantId;
  final PlanModel   plan;
  final DateTime?   planActivatedAt;
  final DateTime?   planExpiresAt;    // null for Basic
  final int         bannerTrialDaysRemaining;
  final int         quarterlySlotsUsed;
  final int?        quarterlySlotsTotalForPlan;

  PlanTier get tier => plan.tier;

  bool get isExpiringSoon {
    if (planExpiresAt == null) return false;
    return planExpiresAt!.difference(DateTime.now()).inDays <= 7;
  }

  int get quarterlyBannerSlotsRemaining =>
      (quarterlySlotsTotalForPlan ?? plan.quarterlyBannerSlots) - quarterlySlotsUsed;

  factory MerchantPlanState.fromJson(
    Map<String, dynamic> merchantJson,
    PlanModel plan,
  ) =>
      MerchantPlanState(
        merchantId:                merchantJson['id']                          as String,
        plan:                      plan,
        planActivatedAt:           merchantJson['plan_activated_at'] != null
            ? DateTime.tryParse(merchantJson['plan_activated_at'] as String)
            : null,
        planExpiresAt:             merchantJson['plan_expires_at'] != null
            ? DateTime.tryParse(merchantJson['plan_expires_at'] as String)
            : null,
        bannerTrialDaysRemaining:  (merchantJson['banner_trial_days_remaining'] as num?)?.toInt() ?? 0,
        quarterlySlotsUsed:        (merchantJson['quarterly_slots_used'] as num?)?.toInt() ?? 0,
        quarterlySlotsTotalForPlan: plan.quarterlyBannerSlots,
      );
}
