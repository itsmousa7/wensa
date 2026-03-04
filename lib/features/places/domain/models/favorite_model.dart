import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_model.freezed.dart';
part 'favorite_model.g.dart';

@freezed
abstract class FavoriteModel with _$FavoriteModel {
  const factory FavoriteModel({
    @Default('') String id,
    @Default('') String userId,
    String? placeId, // nullable — a favorite is either a place OR event
    String? eventId, // nullable — added after migration
    String? createdAt,
  }) = _FavoriteModel;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? '',
    placeId: json['place_id'] as String?,
    eventId: json['event_id'] as String?,
    createdAt: json['created_at'] as String?,
  );
}
