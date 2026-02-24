import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_model.freezed.dart';
part 'tag_model.g.dart';

@freezed
abstract class TagModel with _$TagModel {
  const factory TagModel({
    @Default('') String id,
    @Default('') String nameAr,
    @Default('') String nameEn,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) => TagModel(
    id: json['id'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
  );
}