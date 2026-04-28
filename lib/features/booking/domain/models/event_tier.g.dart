// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_tier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventTier _$EventTierFromJson(Map<String, dynamic> json) => _EventTier(
  id: json['id'] as String? ?? '',
  eventId: json['eventId'] as String? ?? '',
  nameAr: json['nameAr'] as String? ?? '',
  nameEn: json['nameEn'] as String? ?? '',
  priceIqd: (json['priceIqd'] as num?)?.toInt() ?? 0,
  capacity: (json['capacity'] as num?)?.toInt() ?? 0,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$EventTierToJson(_EventTier instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'priceIqd': instance.priceIqd,
      'capacity': instance.capacity,
      'sortOrder': instance.sortOrder,
    };
