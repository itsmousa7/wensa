// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventModel _$EventModelFromJson(Map<String, dynamic> json) => _EventModel(
  id: json['id'] as String? ?? '',
  placeId: json['placeId'] as String?,
  titleAr: json['titleAr'] as String? ?? '',
  titleEn: json['titleEn'] as String? ?? '',
  descriptionAr: json['descriptionAr'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  coverImageUrl: json['coverImageUrl'] as String?,
  startDate: json['startDate'] as String? ?? '',
  endDate: json['endDate'] as String?,
  ticketPrice: (json['ticketPrice'] as num?)?.toDouble(),
  ticketUrl: json['ticketUrl'] as String?,
  city: json['city'] as String?,
  isFeatured: json['isFeatured'] as bool? ?? false,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  savesCount: (json['savesCount'] as num?)?.toInt() ?? 0,
  reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
  sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
  checkinsCount: (json['checkinsCount'] as num?)?.toInt() ?? 0,
  hotnessScore: (json['hotnessScore'] as num?)?.toDouble() ?? 0.0,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$EventModelToJson(_EventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'placeId': instance.placeId,
      'titleAr': instance.titleAr,
      'titleEn': instance.titleEn,
      'descriptionAr': instance.descriptionAr,
      'descriptionEn': instance.descriptionEn,
      'coverImageUrl': instance.coverImageUrl,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'ticketPrice': instance.ticketPrice,
      'ticketUrl': instance.ticketUrl,
      'city': instance.city,
      'isFeatured': instance.isFeatured,
      'viewCount': instance.viewCount,
      'savesCount': instance.savesCount,
      'reviewsCount': instance.reviewsCount,
      'sharesCount': instance.sharesCount,
      'checkinsCount': instance.checkinsCount,
      'hotnessScore': instance.hotnessScore,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
