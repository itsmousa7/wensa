import 'package:freezed_annotation/freezed_annotation.dart';

part 'promoted_banner.freezed.dart';

@freezed
abstract class PromotedBannerModel with _$PromotedBannerModel {
  const factory PromotedBannerModel({
    required String id,
    String? placeId,
    String? eventId,
    required String imageUrl,
    String? actionUrl,
    required String startDate,
    required String endDate,
    @Default(true) bool isActive,
    // Merchant-entered title (description_en / description_ar in DB)
    String? titleEn,
    String? titleAr,
    // Merchant-entered city
    String? cityEn,
    String? cityAr,
    // Joined from linked place / event (fallbacks)
    String? placeNameAr,
    String? placeNameEn,
    String? placeArea,
    String? eventTitleAr,
    String? eventTitleEn,
    String? eventCity,
  }) = _PromotedBannerModel;

  factory PromotedBannerModel.fromJson(Map<String, dynamic> json) {
    return PromotedBannerModel(
      id: json['id'] ?? '',
      placeId: json['place_id'],
      eventId: json['event_id'],
      imageUrl: json['image_url'] ?? '',
      actionUrl: json['action_url'],
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      isActive: json['is_active'] ?? true,
      titleEn: json['title_en'],
      titleAr: json['title_ar'],
      cityEn: json['city_en'],
      cityAr: json['city_ar'],
      placeNameAr: json['place_name_ar'],
      placeNameEn: json['place_name_en'],
      placeArea: json['place_area'],
      eventTitleAr: json['event_title_ar'],
      eventTitleEn: json['event_title_en'],
      eventCity: json['event_city'],
    );
  }
}

extension PromotedBannerX on PromotedBannerModel {
  // Merchant title takes priority; falls back to linked item name.
  String displayNameFor(String locale) {
    if (locale == 'ar') return titleAr ?? placeNameAr ?? eventTitleAr ?? '';
    return titleEn ?? placeNameEn ?? eventTitleEn ?? '';
  }

  // Merchant city takes priority; falls back to linked item location.
  String? displayLocationFor(String locale) {
    if (locale == 'ar') return cityAr ?? placeArea ?? eventCity;
    return cityEn ?? placeArea ?? eventCity;
  }
}
