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
    int? standardPriceIqd,
    @Default(true) bool isAvailable,
    @Default(false) bool isClosed,
    @Default(false) bool partyEnabled,
    @Default(1) int partyIncludedPersons,
    @Default(0) int partyFlatFeeIqd,
    @Default(0) int partyExtraPersonFeeIqd,
  }) = _FarmShift;

  factory FarmShift.fromJson(Map<String, dynamic> json) => FarmShift(
    placeId: json['place_id'] ?? '',
    shiftType: FarmShiftTypeFromString.fromString(json['shift_type'] ?? ''),
    startsTime: json['starts_time'] ?? '',
    endsTime: json['ends_time'] ?? '',
    priceIqd: (json['price_iqd'] as num?)?.toInt() ?? 0,
    standardPriceIqd: (json['standard_price_iqd'] as num?)?.toInt(),
    isAvailable: (json['is_available'] as bool?) ?? true,
    isClosed: (json['is_closed'] as bool?) ?? false,
    partyEnabled: (json['party_enabled'] as bool?) ?? false,
    partyIncludedPersons: (json['party_included_persons'] as num?)?.toInt() ?? 1,
    partyFlatFeeIqd: (json['party_flat_fee_iqd'] as num?)?.toInt() ?? 0,
    partyExtraPersonFeeIqd: (json['party_extra_person_fee_iqd'] as num?)?.toInt() ?? 0,
  );
}
