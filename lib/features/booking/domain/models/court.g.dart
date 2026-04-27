// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'court.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Court _$CourtFromJson(Map<String, dynamic> json) => _Court(
  id: json['id'] as String? ?? '',
  placeId: json['placeId'] as String? ?? '',
  nameAr: json['nameAr'] as String? ?? '',
  nameEn: json['nameEn'] as String? ?? '',
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? false,
);

Map<String, dynamic> _$CourtToJson(_Court instance) => <String, dynamic>{
  'id': instance.id,
  'placeId': instance.placeId,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'sortOrder': instance.sortOrder,
  'isActive': instance.isActive,
};
