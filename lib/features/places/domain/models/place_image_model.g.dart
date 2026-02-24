// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_image_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaceImageModel _$PlaceImageModelFromJson(Map<String, dynamic> json) =>
    _PlaceImageModel(
      id: json['id'] as String? ?? '',
      placeId: json['placeId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$PlaceImageModelToJson(_PlaceImageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'placeId': instance.placeId,
      'imageUrl': instance.imageUrl,
      'displayOrder': instance.displayOrder,
      'createdAt': instance.createdAt,
    };
