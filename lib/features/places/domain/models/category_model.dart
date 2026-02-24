import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
abstract class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    @Default('') String id,
    @Default('') String nameAr,
    @Default('') String nameEn,
    String? iconUrl,
    String? colorHex,
    String? createdAt,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
    iconUrl: json['icon_url'],
    colorHex: json['color_hex'],
    createdAt: json['created_at'],
  );
}