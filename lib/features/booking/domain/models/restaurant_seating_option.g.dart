// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_seating_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RestaurantSeatingOption _$RestaurantSeatingOptionFromJson(
  Map<String, dynamic> json,
) => _RestaurantSeatingOption(
  id: json['id'] as String? ?? '',
  placeId: json['placeId'] as String? ?? '',
  labelAr: json['labelAr'] as String? ?? '',
  labelEn: json['labelEn'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? false,
);

Map<String, dynamic> _$RestaurantSeatingOptionToJson(
  _RestaurantSeatingOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'placeId': instance.placeId,
  'labelAr': instance.labelAr,
  'labelEn': instance.labelEn,
  'isActive': instance.isActive,
};
