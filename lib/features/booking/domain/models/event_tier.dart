import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_tier.freezed.dart';
part 'event_tier.g.dart';

@freezed
abstract class EventTier with _$EventTier {
  const factory EventTier({
    @Default('') String id,
    @Default('') String eventId,
    @Default('') String nameAr,
    @Default('') String nameEn,
    @Default(0) int priceIqd,
    @Default(0) int capacity,
    @Default(0) int sortOrder,
  }) = _EventTier;

  factory EventTier.fromJson(Map<String, dynamic> json) => EventTier(
    id: json['id'] ?? '',
    eventId: json['event_id'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
    priceIqd: (json['price_iqd'] as num?)?.toInt() ?? 0,
    capacity: json['capacity'] ?? 0,
    sortOrder: json['sort_order'] ?? 0,
  );
}
