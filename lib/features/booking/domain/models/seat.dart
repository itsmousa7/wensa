import 'package:freezed_annotation/freezed_annotation.dart';
import 'booking_enums.dart';

part 'seat.freezed.dart';
part 'seat.g.dart';

@freezed
abstract class Seat with _$Seat {
  const factory Seat({
    @Default('') String seatId,
    @Default('') String row,
    @Default('') String seat,
    @Default('') String tierKey,
    @Default(0) int x,
    @Default(0) int y,
    @Default(SeatStatus.free) SeatStatus status,
  }) = _Seat;

  factory Seat.fromJson(Map<String, dynamic> json) => Seat(
    seatId: json['seat_id'] ?? '',
    row: json['row'] ?? '',
    seat: json['seat'] ?? '',
    tierKey: json['tier_key'] ?? '',
    x: json['x'] ?? 0,
    y: json['y'] ?? 0,
    status: SeatStatusFromString.fromString(json['status'] ?? ''),
  );
}
