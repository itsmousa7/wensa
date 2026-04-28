import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant_seating_option.freezed.dart';
part 'restaurant_seating_option.g.dart';

@freezed
abstract class RestaurantSeatingOption with _$RestaurantSeatingOption {
  const factory RestaurantSeatingOption({
    @Default('') String id,
    @Default('') String placeId,
    @Default('') String labelAr,
    @Default('') String labelEn,
    @Default(false) bool isActive,
  }) = _RestaurantSeatingOption;

  factory RestaurantSeatingOption.fromJson(Map<String, dynamic> json) =>
      RestaurantSeatingOption(
        id: json['id'] ?? '',
        placeId: json['place_id'] ?? '',
        labelAr: json['label_ar'] ?? '',
        labelEn: json['label_en'] ?? '',
        isActive: json['is_active'] ?? false,
      );
}
