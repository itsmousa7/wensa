import 'models/plan_model.dart';

/// Single source of truth for all feature-gate decisions.
/// Reads capabilities from the DB plan — no hardcoded limits in Flutter.
class FeatureGate {
  const FeatureGate(this.plan);

  final PlanModel plan;

  // ── Combined quota (places + active events counted together) ───────────────
  /// [currentCombinedCount] = visible places + active events for the merchant.
  bool canAddItem(int currentCombinedCount) =>
      plan.maxCombinedItems == null || currentCombinedCount < plan.maxCombinedItems!;

  // Convenience aliases used in paywall routing:
  bool canAddPlace(int currentCombinedCount) => canAddItem(currentCombinedCount);
  bool canAddEvent(int currentCombinedCount) => canAddItem(currentCombinedCount);

  // ── Photo quota (separate from combined) ───────────────────────────────────
  bool canAddPhoto(int currentAdditionalCount) =>
      plan.maxAdditionalPhotos == null || currentAdditionalCount < plan.maxAdditionalPhotos!;

  // ── Feature flags ──────────────────────────────────────────────────────────
  bool get hasDirectContact      => plan.hasDirectContact;
  bool get hasBasicAnalytics     => plan.hasBasicAnalytics;
  bool get hasAdvancedAnalytics  => plan.hasAdvancedAnalytics;
  bool get hasPriorityPlacement  => plan.hasPriorityPlacement;
  bool get hasHomeFeedPromotion  => plan.hasHomeFeedPromotion;
  bool get hasVerifiedBadge      => plan.hasVerifiedBadge;
  bool get hasPushToFollowers    => plan.hasPushToFollowers;
  bool get hasScheduledPosts     => plan.hasScheduledPosts;
  bool get hasMultiStaff         => plan.hasMultiStaff;
  bool get hasCsvExport          => plan.hasCsvExport;
  bool get hasApiAccess          => plan.hasApiAccess;
  bool get hasPrioritySupport    => plan.hasPrioritySupport;

  // ── Banner helpers ─────────────────────────────────────────────────────────
  bool canUseBannerTrial(int trialDaysRemaining, int requestedDays) =>
      trialDaysRemaining >= requestedDays;

  bool canUseQuarterlySlot(int slotsUsed) =>
      plan.quarterlyBannerSlots > 0 && slotsUsed < plan.quarterlyBannerSlots;

  /// Cheapest plan that unlocks a given feature — drives paywall copy.
  static String cheapestPlanForFeature(String featureKey) => switch (featureKey) {
        'places'            => 'growth',
        'events'            => 'growth',
        'photos'            => 'growth',
        'directContact'     => 'growth',
        'basicAnalytics'    => 'growth',
        'advancedAnalytics' => 'pro',
        'priorityPlacement' => 'pro',
        'homeFeedPromotion' => 'pro',
        'verifiedBadge'     => 'pro',
        'pushToFollowers'   => 'pro',
        'scheduledPosts'    => 'pro',
        'multiStaff'        => 'pro',
        'csvExport'         => 'pro',
        'apiAccess'         => 'pro',
        'prioritySupport'   => 'pro',
        _                   => 'growth',
      };
}
