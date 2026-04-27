import 'package:freezed_annotation/freezed_annotation.dart';

part 'membership_plan.freezed.dart';
part 'membership_plan.g.dart';

@freezed
abstract class MembershipPlan with _$MembershipPlan {
  const factory MembershipPlan({
    @Default('') String id,
    @Default('') String placeId,
    @Default('') String membershipType,
    @Default('') String nameAr,
    @Default('') String nameEn,
    @Default(0) int durationDays,
    @Default(0) int priceIqd,
    @Default(false) bool allowFreeze,
    @Default(true) bool isActive,
  }) = _MembershipPlan;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
    id: json['id'] ?? '',
    placeId: json['place_id'] ?? '',
    membershipType: json['membership_type'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
    durationDays: json['duration_days'] ?? 0,
    priceIqd: json['price_iqd'] ?? 0,
    allowFreeze: json['allow_freeze'] ?? false,
    isActive: json['is_active'] ?? true,
  );
}
