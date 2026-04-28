import 'package:freezed_annotation/freezed_annotation.dart';
import 'booking_enums.dart';

part 'membership.freezed.dart';
part 'membership.g.dart';

@freezed
abstract class Membership with _$Membership {
  const factory Membership({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String merchantId,
    @Default('') String placeId,
    @Default('') String planId,
    @Default(MembershipStatus.active) MembershipStatus status,
    @Default('') String membershipType,
    @Default('') String startsAt,
    @Default('') String endsAt,
    @Default(0) int amountIqd,
    String? paymentId,
    String? paymentStatus,
    @Default('') String qrToken,
    @Default(false) bool isFrozen,
    String? createdAt,
  }) = _Membership;

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? '',
    merchantId: json['merchant_id'] ?? '',
    placeId: json['place_id'] ?? '',
    planId: json['plan_id'] ?? '',
    status: MembershipStatusFromString.fromString(json['status'] ?? ''),
    membershipType: json['membership_type'] ?? '',
    startsAt: json['starts_at'] ?? '',
    endsAt: json['ends_at'] ?? '',
    amountIqd: (json['amount_iqd'] as num?)?.toInt() ?? 0,
    paymentId: json['payment_id'],
    paymentStatus: json['payment_status'],
    qrToken: json['qr_token'] ?? '',
    isFrozen: json['is_frozen'] ?? false,
    createdAt: json['created_at'],
  );
}
