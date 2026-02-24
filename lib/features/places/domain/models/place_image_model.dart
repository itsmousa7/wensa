import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_image_model.freezed.dart';
part 'place_image_model.g.dart';

@freezed
abstract class PlaceImageModel with _$PlaceImageModel {
  const factory PlaceImageModel({
    @Default('') String id,
    @Default('') String placeId,
    @Default('') String imageUrl,
    @Default(0) int displayOrder,
    String? createdAt,
  }) = _PlaceImageModel;

  factory PlaceImageModel.fromJson(Map<String, dynamic> json) =>
      PlaceImageModel(
        id: json['id'] ?? '',
        placeId: json['place_id'] ?? '',
        imageUrl: json['image_url'] ?? '',
        displayOrder: json['display_order'] ?? 0,
        createdAt: json['created_at'],
      );
}
