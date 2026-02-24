import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

@freezed
abstract class EventModel with _$EventModel {
  const factory EventModel({
    @Default('') String id,
    String? placeId,
    @Default('') String titleAr,
    @Default('') String titleEn,
    String? descriptionAr,
    String? descriptionEn,
    String? coverImageUrl,
    @Default('') String startDate,
    String? endDate,
    double? ticketPrice,
    String? ticketUrl,
    String? city,
    @Default(false) bool isFeatured,
    @Default(0) int viewCount,
    @Default(0) int savesCount,
    @Default(0) int reviewsCount,
    @Default(0) int sharesCount,
    @Default(0) int checkinsCount,
    @Default(0.0) double hotnessScore,
    String? createdAt,
    String? updatedAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
    id: json['id'] ?? '',
    placeId: json['place_id'],
    titleAr: json['title_ar'] ?? '',
    titleEn: json['title_en'] ?? '',
    descriptionAr: json['description_ar'],
    descriptionEn: json['description_en'],
    coverImageUrl: json['cover_image_url'],
    startDate: json['start_date'] ?? '',
    endDate: json['end_date'],
    ticketPrice: (json['ticket_price'] as num?)?.toDouble(),
    ticketUrl: json['ticket_url'],
    city: json['city'],
    isFeatured: json['is_featured'] ?? false,
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