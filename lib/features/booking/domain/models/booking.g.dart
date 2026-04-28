// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Booking _$BookingFromJson(Map<String, dynamic> json) => _Booking(
  id: json['id'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  merchantId: json['merchantId'] as String? ?? '',
  placeId: json['placeId'] as String?,
  eventId: json['eventId'] as String?,
  category:
      $enumDecodeNullable(_$BookingCategoryEnumMap, json['category']) ??
      BookingCategory.padel,
  status:
      $enumDecodeNullable(_$BookingStatusEnumMap, json['status']) ??
      BookingStatus.pending,
  startsAt: json['startsAt'] as String? ?? '',
  endsAt: json['endsAt'] as String? ?? '',
  amountIqd: (json['amountIqd'] as num?)?.toInt() ?? 0,
  paymentId: json['paymentId'] as String?,
  paymentStatus: json['paymentStatus'] as String?,
  qrToken: json['qrToken'] as String? ?? '',
  holdUntil: json['holdUntil'] as String?,
  categoryData:
      json['categoryData'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  groupId: json['groupId'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$BookingToJson(_Booking instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'merchantId': instance.merchantId,
  'placeId': instance.placeId,
  'eventId': instance.eventId,
  'category': _$BookingCategoryEnumMap[instance.category]!,
  'status': _$BookingStatusEnumMap[instance.status]!,
  'startsAt': instance.startsAt,
  'endsAt': instance.endsAt,
  'amountIqd': instance.amountIqd,
  'paymentId': instance.paymentId,
  'paymentStatus': instance.paymentStatus,
  'qrToken': instance.qrToken,
  'holdUntil': instance.holdUntil,
  'categoryData': instance.categoryData,
  'groupId': instance.groupId,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

const _$BookingCategoryEnumMap = {
  BookingCategory.padel: 'padel',
  BookingCategory.football: 'football',
  BookingCategory.farm: 'farm',
  BookingCategory.concert: 'concert',
  BookingCategory.restaurant: 'restaurant',
};

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.completed: 'completed',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.expired: 'expired',
  BookingStatus.noShow: 'noShow',
  BookingStatus.used: 'used',
};
