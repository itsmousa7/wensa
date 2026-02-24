// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FavoriteModel _$FavoriteModelFromJson(Map<String, dynamic> json) =>
    _FavoriteModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      placeId: json['placeId'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$FavoriteModelToJson(_FavoriteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'placeId': instance.placeId,
      'createdAt': instance.createdAt,
    };
