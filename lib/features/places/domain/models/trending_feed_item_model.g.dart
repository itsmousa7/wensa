// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trending_feed_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrendingFeedItemModel _$TrendingFeedItemModelFromJson(
  Map<String, dynamic> json,
) => _TrendingFeedItemModel(
  id: json['id'] as String? ?? '',
  type: json['type'] as String? ?? 'place',
  titleAr: json['titleAr'] as String? ?? '',
  titleEn: json['titleEn'] as String? ?? '',
  coverImageUrl: json['coverImageUrl'] as String?,
  city: json['city'] as String?,
  subtitleAr: json['subtitleAr'] as String?,
  subtitleEn: json['subtitleEn'] as String?,
  hotnessScore: (json['hotnessScore'] as num?)?.toDouble() ?? 0.0,
  isVerified: json['isVerified'] as bool? ?? false,
  isFeatured: json['isFeatured'] as bool? ?? false,
  eventStartDate: json['eventStartDate'] as String?,
  ticketPrice: (json['ticketPrice'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TrendingFeedItemModelToJson(
  _TrendingFeedItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'coverImageUrl': instance.coverImageUrl,
  'city': instance.city,
  'subtitleAr': instance.subtitleAr,
  'subtitleEn': instance.subtitleEn,
  'hotnessScore': instance.hotnessScore,
  'isVerified': instance.isVerified,
  'isFeatured': instance.isFeatured,
  'eventStartDate': instance.eventStartDate,
  'ticketPrice': instance.ticketPrice,
};
