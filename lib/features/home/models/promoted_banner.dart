import 'package:freezed_annotation/freezed_annotation.dart';

part 'promoted_banner.freezed.dart';

@freezed
abstract class PromotedBannerModel with _$PromotedBannerModel {
  const factory PromotedBannerModel({
    required String id,
    String? placeId,
    required String imageUrl,
    String? actionUrl,
    required String startDate,
    required String endDate,
    @Default(true) bool isActive,
    String? placeNameAr,
    String? placeNameEn,
    String? placeArea,
  }) = _PromotedBannerModel;

  factory PromotedBannerModel.fromJson(Map<String, dynamic> json) {
    final place = json['places'] as Map<String, dynamic>?;
    return PromotedBannerModel(
      id: json['id'] ?? '',
      placeId: json['place_id'],
      imageUrl: json['image_url'] ?? '',
      actionUrl: json['action_url'],
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      isActive: json['is_active'] ?? true,
      placeNameAr: place?['name_ar'],
      placeNameEn: place?['name_en'],
      placeArea: place?['area'],
    );
  }
}

extension PromotedBannerX on PromotedBannerModel {
  String placeNameFor(String locale) =>
      locale == 'ar' ? (placeNameAr ?? '') : (placeNameEn ?? '');
}
