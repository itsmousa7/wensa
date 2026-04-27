import 'plan_tier.dart';

class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.priceIqd,
    this.maxCombinedItems,         // null = unlimited (places + events total)
    this.maxAdditionalPhotos,      // null = unlimited
    required this.hasDirectContact,
    required this.hasBasicAnalytics,
    required this.hasAdvancedAnalytics,
    required this.hasPriorityPlacement,
    required this.hasHomeFeedPromotion,
    required this.hasVerifiedBadge,
    required this.hasPushToFollowers,
    required this.hasScheduledPosts,
    required this.hasMultiStaff,
    required this.maxStaffAccounts,
    required this.hasCsvExport,
    required this.hasApiAccess,
    required this.hasPrioritySupport,
    required this.quarterlyBannerSlots,
    required this.trialBannerDays,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int    priceIqd;
  final int?   maxCombinedItems;     // Basic=2, Growth=10, Pro=null
  final int?   maxAdditionalPhotos;  // Basic=3, Growth/Pro=null
  final bool   hasDirectContact;
  final bool   hasBasicAnalytics;
  final bool   hasAdvancedAnalytics;
  final bool   hasPriorityPlacement;
  final bool   hasHomeFeedPromotion;
  final bool   hasVerifiedBadge;
  final bool   hasPushToFollowers;
  final bool   hasScheduledPosts;
  final bool   hasMultiStaff;
  final int    maxStaffAccounts;
  final bool   hasCsvExport;
  final bool   hasApiAccess;
  final bool   hasPrioritySupport;
  final int    quarterlyBannerSlots;
  final int    trialBannerDays;
  final int    sortOrder;

  PlanTier get tier => PlanTier.fromId(id);

  bool get isFree => priceIqd == 0;

  factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
        id:                    json['id']                       as String,
        name:                  json['name']                     as String,
        priceIqd:              (json['price_iqd'] as num).toInt(),
        maxCombinedItems:      json['max_combined_items']       as int?,
        maxAdditionalPhotos:   json['max_additional_photos']    as int?,
        hasDirectContact:      json['has_direct_contact']       as bool? ?? false,
        hasBasicAnalytics:     json['has_basic_analytics']      as bool? ?? false,
        hasAdvancedAnalytics:  json['has_advanced_analytics']   as bool? ?? false,
        hasPriorityPlacement:  json['has_priority_placement']   as bool? ?? false,
        hasHomeFeedPromotion:  json['has_home_feed_promotion']  as bool? ?? false,
        hasVerifiedBadge:      json['has_verified_badge']       as bool? ?? false,
        hasPushToFollowers:    json['has_push_to_followers']    as bool? ?? false,
        hasScheduledPosts:     json['has_scheduled_posts']      as bool? ?? false,
        hasMultiStaff:         json['has_multi_staff']          as bool? ?? false,
        maxStaffAccounts:      (json['max_staff_accounts'] as num?)?.toInt() ?? 1,
        hasCsvExport:          json['has_csv_export']           as bool? ?? false,
        hasApiAccess:          json['has_api_access']           as bool? ?? false,
        hasPrioritySupport:    json['has_priority_support']     as bool? ?? false,
        quarterlyBannerSlots:  (json['quarterly_banner_slots'] as num?)?.toInt() ?? 0,
        trialBannerDays:       (json['trial_banner_days'] as num?)?.toInt() ?? 0,
        sortOrder:             (json['sort_order'] as num?)?.toInt() ?? 0,
      );

  static final PlanModel fallbackBasic = PlanModel(
    id: 'basic', name: 'Basic',
    priceIqd: 0,
    maxCombinedItems: 2, maxAdditionalPhotos: 3,
    hasDirectContact: false, hasBasicAnalytics: false, hasAdvancedAnalytics: false,
    hasPriorityPlacement: false, hasHomeFeedPromotion: false, hasVerifiedBadge: false,
    hasPushToFollowers: false, hasScheduledPosts: false, hasMultiStaff: false,
    maxStaffAccounts: 1, hasCsvExport: false, hasApiAccess: false, hasPrioritySupport: false,
    quarterlyBannerSlots: 0, trialBannerDays: 3, sortOrder: 1,
  );
}
