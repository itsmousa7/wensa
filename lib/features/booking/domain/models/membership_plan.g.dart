// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MembershipPlan _$MembershipPlanFromJson(Map<String, dynamic> json) =>
    _MembershipPlan(
      id: json['id'] as String? ?? '',
      placeId: json['placeId'] as String? ?? '',
      membershipType: json['membershipType'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      priceIqd: (json['priceIqd'] as num?)?.toInt() ?? 0,
      allowFreeze: json['allowFreeze'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$MembershipPlanToJson(_MembershipPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'placeId': instance.placeId,
      'membershipType': instance.membershipType,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'durationDays': instance.durationDays,
      'priceIqd': instance.priceIqd,
      'allowFreeze': instance.allowFreeze,
      'isActive': instance.isActive,
    };
