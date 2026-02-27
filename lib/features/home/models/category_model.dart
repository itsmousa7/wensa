import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
abstract class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,
    required String nameAr,
    required String nameEn,
    String? iconUrl,
    String? colorHex,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
    iconUrl: json['icon_url'],
    colorHex: json['color_hex'],
  );
}

extension CategoryModelX on CategoryModel {
  String nameFor(String locale) => locale == 'ar' ? nameAr : nameEn;
}
