import 'package:freezed_annotation/freezed_annotation.dart';
import 'booking_enums.dart';

part 'farm_shift.freezed.dart';
part 'farm_shift.g.dart';

@freezed
abstract class FarmShift with _$FarmShift {
  const factory FarmShift({
    @Default('') String placeId,
    @Default(FarmShiftType.day) FarmShiftType shiftType,
    @Default('') String startsTime,
    @Default('') String endsTime,
    @Default(0) int priceIqd,
  }) = _FarmShift;

  factory FarmShift.fromJson(Map<String, dynamic> json) => FarmShift(
    placeId: json['place_id'] ?? '',
    shiftType: FarmShiftTypeFromString.fromString(json['shift_type'] ?? ''),
    startsTime: json['starts_time'] ?? '',
    endsTime: json['ends_time'] ?? '',
    priceIqd: json['price_iqd'] ?? 0,
  );
}
