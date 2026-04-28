// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seat_hold.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeatHold _$SeatHoldFromJson(Map<String, dynamic> json) => _SeatHold(
  id: json['id'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  seatId: json['seatId'] as String? ?? '',
  eventId: json['eventId'] as String? ?? '',
  expiresAt: json['expiresAt'] as String? ?? '',
);

Map<String, dynamic> _$SeatHoldToJson(_SeatHold instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'seatId': instance.seatId,
  'eventId': instance.eventId,
  'expiresAt': instance.expiresAt,
};
