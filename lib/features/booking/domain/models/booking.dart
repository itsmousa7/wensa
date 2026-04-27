import 'package:freezed_annotation/freezed_annotation.dart';
import 'booking_enums.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

@freezed
abstract class Booking with _$Booking {
  const factory Booking({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String merchantId,
    String? placeId,
    String? eventId,
    @Default(BookingCategory.padel) BookingCategory category,
    @Default(BookingStatus.pending) BookingStatus status,
    @Default('') String startsAt,
    @Default('') String endsAt,
    @Default(0) int amountIqd,
    String? paymentId,
    String? paymentStatus,
    @Default('') String qrToken,
    String? holdUntil,
    @Default(<String, dynamic>{}) Map<String, dynamic> categoryData,
    String? groupId,
    String? createdAt,
    String? updatedAt,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? '',
    merchantId: json['merchant_id'] ?? '',
    placeId: json['place_id'],
    eventId: json['event_id'],
    category: BookingCategoryFromString.fromString(json['category'] ?? ''),
    status: BookingStatusFromString.fromString(json['status'] ?? ''),
    startsAt: json['starts_at'] ?? '',
    endsAt: json['ends_at'] ?? '',
    amountIqd: (json['amount_iqd'] as num?)?.toInt() ?? 0,
    paymentId: json['payment_id'],
    paymentStatus: json['payment_status'],
    qrToken: json['qr_token'] ?? '',
    holdUntil: json['hold_until'],
    categoryData: json['category_data'] != null
        ? Map<String, dynamic>.from(json['category_data'])
        : {},
    groupId: json['group_id'],
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );
}
