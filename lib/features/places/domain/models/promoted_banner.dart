import 'package:freezed_annotation/freezed_annotation.dart';

part 'promoted_banner.freezed.dart';
part 'promoted_banner.g.dart';

@freezed
abstract class PromotedBannerModel with _$PromotedBannerModel {
  const factory PromotedBannerModel({
    @Default('') String id,
    String? placeId,
    @Default('') String imageUrl,
    String? actionUrl,
    @Default('') String startDate,
    @Default('') String endDate,
    @Default(true) bool isActive,
    String? createdAt,
  }) = _PromotedBannerModel;

  factory PromotedBannerModel.fromJson(Map<String, dynamic> json) =>
      PromotedBannerModel(
        id: json['id'] ?? '',
        placeId: json['place_id'],
        imageUrl: json['image_url'] ?? '',
        actionUrl: json['action_url'],
        startDate: json['start_date'] ?? '',
        endDate: json['end_date'] ?? '',
        isActive: json['is_active'] ?? true,
        createdAt: json['created_at'],
      );
}
