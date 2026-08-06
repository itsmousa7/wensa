// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm_shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FarmShift _$FarmShiftFromJson(Map<String, dynamic> json) => _FarmShift(
  placeId: json['placeId'] as String? ?? '',
  shiftType:
      $enumDecodeNullable(_$FarmShiftTypeEnumMap, json['shiftType']) ??
      FarmShiftType.day,
  startsTime: json['startsTime'] as String? ?? '',
  endsTime: json['endsTime'] as String? ?? '',
  priceIqd: (json['priceIqd'] as num?)?.toInt() ?? 0,
  isAvailable: json['isAvailable'] as bool? ?? true,
  isClosed: json['isClosed'] as bool? ?? false,
  partyEnabled: json['partyEnabled'] as bool? ?? false,
  partyIncludedPersons: (json['partyIncludedPersons'] as num?)?.toInt() ?? 1,
  partyFlatFeeIqd: (json['partyFlatFeeIqd'] as num?)?.toInt() ?? 0,
  partyExtraPersonFeeIqd:
      (json['partyExtraPersonFeeIqd'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FarmShiftToJson(_FarmShift instance) =>
    <String, dynamic>{
      'placeId': instance.placeId,
      'shiftType': _$FarmShiftTypeEnumMap[instance.shiftType]!,
      'startsTime': instance.startsTime,
      'endsTime': instance.endsTime,
      'priceIqd': instance.priceIqd,
      'isAvailable': instance.isAvailable,
      'isClosed': instance.isClosed,
      'partyEnabled': instance.partyEnabled,
      'partyIncludedPersons': instance.partyIncludedPersons,
      'partyFlatFeeIqd': instance.partyFlatFeeIqd,
      'partyExtraPersonFeeIqd': instance.partyExtraPersonFeeIqd,
    };

const _$FarmShiftTypeEnumMap = {
  FarmShiftType.day: 'day',
  FarmShiftType.night: 'night',
  FarmShiftType.full: 'full',
};
