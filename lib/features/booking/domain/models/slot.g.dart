// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Slot _$SlotFromJson(Map<String, dynamic> json) => _Slot(
  startsAt: json['startsAt'] as String? ?? '',
  endsAt: json['endsAt'] as String? ?? '',
  available: json['available'] as bool? ?? false,
);

Map<String, dynamic> _$SlotToJson(_Slot instance) => <String, dynamic>{
  'startsAt': instance.startsAt,
  'endsAt': instance.endsAt,
  'available': instance.available,
};
