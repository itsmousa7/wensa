import 'package:freezed_annotation/freezed_annotation.dart';

part 'slot.freezed.dart';
part 'slot.g.dart';

@freezed
abstract class Slot with _$Slot {
  const factory Slot({
    @Default('') String startsAt,
    @Default('') String endsAt,
    @Default(false) bool available,
  }) = _Slot;

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
    startsAt: json['starts_at'] ?? '',
    endsAt: json['ends_at'] ?? '',
    available: json['available'] ?? false,
  );
}
