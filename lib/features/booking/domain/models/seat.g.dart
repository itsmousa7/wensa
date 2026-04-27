// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Seat _$SeatFromJson(Map<String, dynamic> json) => _Seat(
  seatId: json['seatId'] as String? ?? '',
  row: json['row'] as String? ?? '',
  seat: json['seat'] as String? ?? '',
  tierKey: json['tierKey'] as String? ?? '',
  x: (json['x'] as num?)?.toInt() ?? 0,
  y: (json['y'] as num?)?.toInt() ?? 0,
  status:
      $enumDecodeNullable(_$SeatStatusEnumMap, json['status']) ??
      SeatStatus.free,
);

Map<String, dynamic> _$SeatToJson(_Seat instance) => <String, dynamic>{
  'seatId': instance.seatId,
  'row': instance.row,
  'seat': instance.seat,
  'tierKey': instance.tierKey,
  'x': instance.x,
  'y': instance.y,
  'status': _$SeatStatusEnumMap[instance.status]!,
};

const _$SeatStatusEnumMap = {
  SeatStatus.free: 'free',
  SeatStatus.held: 'held',
  SeatStatus.taken: 'taken',
};
