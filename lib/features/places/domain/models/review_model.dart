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
    createdAt: _toUtcIso(json['created_at']),
  );

  static String? _toUtcIso(dynamic raw) {
    if (raw == null) return null;
    var s = (raw as String).trim().replaceFirst(
      ' ',
      'T',
    ); // normalize space → T
    if (s.endsWith('Z')) return s;
    // +00 or +00:00 → just use Z (Dart parses Z reliably)
    final plusIdx = s.lastIndexOf('+');
    if (plusIdx > 10) {
      final offset = s.substring(plusIdx + 1);
      if (offset == '00' || offset == '00:00') {
        '${s.substring(0, plusIdx)}Z';
      }
      // non-zero offset: ensure +HH:MM format
      if (!offset.contains(':')) {
        '${s.substring(0, plusIdx + 1)}$offset:00';
      }
      return s;
    }
    return '${s}Z'; // no tz info → assume UTC
  }
}
