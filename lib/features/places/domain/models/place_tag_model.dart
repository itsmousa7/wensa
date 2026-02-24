import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_tag_model.freezed.dart';
part 'place_tag_model.g.dart';

@freezed
abstract class PlaceTagModel with _$PlaceTagModel {
  const factory PlaceTagModel({
    @Default('') String placeId,
    @Default('') String tagId,
  }) = _PlaceTagModel;

  factory PlaceTagModel.fromJson(Map<String, dynamic> json) => PlaceTagModel(
    placeId: json['place_id'] ?? '',
    tagId: json['tag_id'] ?? '',
  );
}