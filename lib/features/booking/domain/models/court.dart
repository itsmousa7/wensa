import 'package:freezed_annotation/freezed_annotation.dart';

part 'court.freezed.dart';
part 'court.g.dart';

@freezed
abstract class Court with _$Court {
  const factory Court({
    @Default('') String id,
    @Default('') String placeId,
    @Default('') String nameAr,
    @Default('') String nameEn,
    @Default(0) int sortOrder,
    @Default(false) bool isActive,
  }) = _Court;

  factory Court.fromJson(Map<String, dynamic> json) => Court(
    id: json['id'] ?? '',
    placeId: json['place_id'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
    sortOrder: json['sort_order'] ?? 0,
    isActive: json['is_active'] ?? false,
  );
}
