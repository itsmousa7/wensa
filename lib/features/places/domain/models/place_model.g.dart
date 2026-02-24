// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaceModel _$PlaceModelFromJson(Map<String, dynamic> json) => _PlaceModel(
  id: json['id'] as String? ?? '',
  nameAr: json['nameAr'] as String? ?? '',
  nameEn: json['nameEn'] as String? ?? '',
  descriptionAr: json['descriptionAr'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  categoryId: json['categoryId'] as String?,
  city: json['city'] as String? ?? '',
  area: json['area'] as String?,
  addressText: json['addressText'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  coverImageUrl: json['coverImageUrl'] as String?,
  isNew: json['isNew'] as bool? ?? false,
  isTrending: json['isTrending'] as bool? ?? false,
  isVerified: json['isVerified'] as bool? ?? false,
  isFeatured: json['isFeatured'] as bool? ?? false,
  priceRange: (json['priceRange'] as num?)?.toInt(),
  openingHours: json['openingHours'] as Map<String, dynamic>?,
  phone: json['phone'] as String?,
  instagramUrl: json['instagramUrl'] as String?,
  websiteUrl: json['websiteUrl'] as String?,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  savesCount: (json['savesCount'] as num?)?.toInt() ?? 0,
  reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
  sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
  checkinsCount: (json['checkinsCount'] as num?)?.toInt() ?? 0,
  hotnessScore: (json['hotnessScore'] as num?)?.toDouble() ?? 0.0,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$PlaceModelToJson(_PlaceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'descriptionAr': instance.descriptionAr,
      'descriptionEn': instance.descriptionEn,
      'categoryId': instance.categoryId,
      'city': instance.city,
      'area': instance.area,
      'addressText': instance.addressText,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'coverImageUrl': instance.coverImageUrl,
      'isNew': instance.isNew,
      'isTrending': instance.isTrending,
      'isVerified': instance.isVerified,
      'isFeatured': instance.isFeatured,
      'priceRange': instance.priceRange,
      'openingHours': instance.openingHours,
      'phone': instance.phone,
      'instagramUrl': instance.instagramUrl,
      'websiteUrl': instance.websiteUrl,
      'viewCount': instance.viewCount,
      'savesCount': instance.savesCount,
      'reviewsCount': instance.reviewsCount,
      'sharesCount': instance.sharesCount,
      'checkinsCount': instance.checkinsCount,
      'hotnessScore': instance.hotnessScore,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
