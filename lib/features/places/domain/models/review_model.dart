import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_model.freezed.dart';
part 'review_model.g.dart';

@freezed
abstract class ReviewModel with _$ReviewModel {
  const factory ReviewModel({
    @Default('') String id,
    @Default('') String placeId,
    @Default('') String userId,
    @Default(1) int rating,
    String? comment,
    String? createdAt,
  }) = _ReviewModel;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'] ?? '',
    placeId: json['place_id'] ?? '',
    userId: json['user_id'] ?? '',
    rating: json['rating'] ?? 1,
    comment: json['comment'],
    createdAt: json['created_at'],
  );
}