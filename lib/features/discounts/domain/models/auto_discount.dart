/// Maps to `business.discounts` rows (automatic % discounts).
///
/// Use [appliesToOrder] to check whether this discount matches a given
/// purchase. The biggest applicable percent wins — never stack.
class AutoDiscount {
  const AutoDiscount({
    required this.id,
    required this.name,
    required this.percent,
    required this.appliesTo,
    required this.scopeType,
    required this.targetCategoryIds,
    required this.targetMerchantIds,
    required this.targetPlaceIds,
    required this.isActive,
    this.description,
    this.maxDiscountAmount,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String name;
  final String? description;
  final double percent;
  final num? maxDiscountAmount;
  final List<String> appliesTo;
  final String scopeType; // 'app' | 'targeted'
  final List<String> targetCategoryIds;
  final List<String> targetMerchantIds;
  final List<String> targetPlaceIds;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  bool appliesToOrder({
    required String orderType,
    required String? placeId,
    required String? merchantId,
    required String? categoryId,
    DateTime? now,
  }) {
    if (!isActive) return false;
    final t = now ?? DateTime.now();
    if (startsAt != null && t.isBefore(startsAt!)) return false;
    if (endsAt != null && t.isAfter(endsAt!)) return false;
    if (!appliesTo.contains(orderType)) return false;
    if (scopeType == 'app') return true;
    // targeted: match ANY of the three id arrays
    if (categoryId != null && targetCategoryIds.contains(categoryId)) return true;
    if (merchantId != null && targetMerchantIds.contains(merchantId)) return true;
    if (placeId != null && targetPlaceIds.contains(placeId)) return true;
    return false;
  }

  factory AutoDiscount.fromJson(Map<String, dynamic> json) => AutoDiscount(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        percent: (json['percent'] as num).toDouble(),
        maxDiscountAmount: json['max_discount_amount'] == null
            ? null
            : num.tryParse(json['max_discount_amount'].toString()),
        appliesTo: ((json['applies_to'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        scopeType: (json['scope_type'] as String?) ?? 'app',
        targetCategoryIds: ((json['target_category_ids'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        targetMerchantIds: ((json['target_merchant_ids'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        targetPlaceIds: ((json['target_place_ids'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        startsAt: json['starts_at'] != null
            ? DateTime.parse(json['starts_at'] as String)
            : null,
        endsAt: json['ends_at'] != null
            ? DateTime.parse(json['ends_at'] as String)
            : null,
        isActive: (json['is_active'] as bool?) ?? true,
      );
}
