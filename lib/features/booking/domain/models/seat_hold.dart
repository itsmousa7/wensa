import 'package:freezed_annotation/freezed_annotation.dart';

part 'seat_hold.freezed.dart';
part 'seat_hold.g.dart';

@freezed
abstract class SeatHold with _$SeatHold {
  const factory SeatHold({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String seatId,
    @Default('') String eventId,
    @Default('') String expiresAt,
  }) = _SeatHold;

  factory SeatHold.fromJson(Map<String, dynamic> json) => SeatHold(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? '',
    seatId: json['seat_id'] ?? '',
    eventId: json['event_id'] ?? '',
    expiresAt: json['expires_at'] ?? '',
  );
}
