// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => _ReviewModel(
  id: json['id'] as String? ?? '',
  placeId: json['placeId'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  rating: (json['rating'] as num?)?.toInt() ?? 1,
  comment: json['comment'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$ReviewModelToJson(_ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'placeId': instance.placeId,
      'userId': instance.userId,
      'rating': instance.rating,
      'comment': instance.comment,
      'createdAt': instance.createdAt,
    };
