import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_model.freezed.dart';
part 'place_model.g.dart';

@freezed
abstract class PlaceModel with _$PlaceModel {
  const factory PlaceModel({
    @Default('') String id,
    @Default('') String nameAr,
    @Default('') String nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? categoryId,
    @Default('') String city,
    String? area,
    String? addressText,
    double? latitude,
    double? longitude,
    String? coverImageUrl,
    @Default(false) bool isNew,
    @Default(false) bool isTrending,
    @Default(false) bool isVerified,
    @Default(false) bool isFeatured,
    int? priceRange,
    // opening_hours stored as raw Map since it's a flexible jsonb
    Map<String, dynamic>? openingHours,
    String? phone,
    String? instagramUrl,
    String? websiteUrl,
    @Default(0) int viewCount,
    @Default(0) int savesCount,
    @Default(0) int reviewsCount,
    @Default(0) int sharesCount,
    @Default(0) int checkinsCount,
    @Default(0.0) double hotnessScore,
    String? createdAt,
    String? updatedAt,
  }) = _PlaceModel;

  factory PlaceModel.fromJson(Map<String, dynamic> json) => PlaceModel(
    id: json['id'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
    descriptionAr: json['description_ar'],
    descriptionEn: json['description_en'],
    categoryId: json['category_id'],
    city: json['city'] ?? '',
    area: json['area'],
    addressText: json['address_text'],
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    coverImageUrl: json['cover_image_url'],
    isNew: json['is_new'] ?? false,
    isTrending: json['is_trending'] ?? false,
    isVerified: json['is_verified'] ?? false,
    isFeatured: json['is_featured'] ?? false,
    priceRange: json['price_range'],
    openingHours: json['opening_hours'] != null
        ? Map<String, dynamic>.from(json['opening_hours'])
        : null,
    phone: json['phone'],
    instagramUrl: json['instagram_url'],
    websiteUrl: json['website_url'],
    viewCount: json['view_count'] ?? 0,
    savesCount: json['saves_count'] ?? 0,
    reviewsCount: json['reviews_count'] ?? 0,
    sharesCount: json['shares_count'] ?? 0,
    checkinsCount: json['checkins_count'] ?? 0,
    hotnessScore: (json['hotness_score'] as num?)?.toDouble() ?? 0.0,
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );
}