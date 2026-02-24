// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_view_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaceViewModel _$PlaceViewModelFromJson(Map<String, dynamic> json) =>
    _PlaceViewModel(
      id: json['id'] as String? ?? '',
      placeId: json['placeId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      viewedAt: json['viewedAt'] as String?,
    );

Map<String, dynamic> _$PlaceViewModelToJson(_PlaceViewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'placeId': instance.placeId,
      'userId': instance.userId,
      'viewedAt': instance.viewedAt,
    };
