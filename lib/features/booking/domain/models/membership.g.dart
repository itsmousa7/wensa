// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Membership _$MembershipFromJson(Map<String, dynamic> json) => _Membership(
  id: json['id'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  merchantId: json['merchantId'] as String? ?? '',
  placeId: json['placeId'] as String? ?? '',
  planId: json['planId'] as String? ?? '',
  status:
      $enumDecodeNullable(_$MembershipStatusEnumMap, json['status']) ??
      MembershipStatus.active,
  membershipType: json['membershipType'] as String? ?? '',
  startsAt: json['startsAt'] as String? ?? '',
  endsAt: json['endsAt'] as String? ?? '',
  amountIqd: (json['amountIqd'] as num?)?.toInt() ?? 0,
  paymentId: json['paymentId'] as String?,
  paymentStatus: json['paymentStatus'] as String?,
  qrToken: json['qrToken'] as String? ?? '',
  isFrozen: json['isFrozen'] as bool? ?? false,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$MembershipToJson(_Membership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'merchantId': instance.merchantId,
      'placeId': instance.placeId,
      'planId': instance.planId,
      'status': _$MembershipStatusEnumMap[instance.status]!,
      'membershipType': instance.membershipType,
      'startsAt': instance.startsAt,
      'endsAt': instance.endsAt,
      'amountIqd': instance.amountIqd,
      'paymentId': instance.paymentId,
      'paymentStatus': instance.paymentStatus,
      'qrToken': instance.qrToken,
      'isFrozen': instance.isFrozen,
      'createdAt': instance.createdAt,
    };

const _$MembershipStatusEnumMap = {
  MembershipStatus.active: 'active',
  MembershipStatus.frozen: 'frozen',
  MembershipStatus.expired: 'expired',
  MembershipStatus.cancelled: 'cancelled',
  MembershipStatus.used: 'used',
};
