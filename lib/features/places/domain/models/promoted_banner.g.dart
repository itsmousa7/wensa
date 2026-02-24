// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promoted_banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PromotedBannerModel _$PromotedBannerModelFromJson(Map<String, dynamic> json) =>
    _PromotedBannerModel(
      id: json['id'] as String? ?? '',
      placeId: json['placeId'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      actionUrl: json['actionUrl'] as String?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$PromotedBannerModelToJson(
  _PromotedBannerModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'placeId': instance.placeId,
  'imageUrl': instance.imageUrl,
  'actionUrl': instance.actionUrl,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt,
};
