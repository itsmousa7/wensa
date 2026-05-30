import 'package:freezed_annotation/freezed_annotation.dart';
import 'booking_enums.dart';

part 'seat.freezed.dart';
part 'seat.g.dart';

@freezed
abstract class Seat with _$Seat {
  const factory Seat({
    @Default('') String seatId,
    @Default('') String sectionId,
    @Default('') String row,
    @Default('') String seat,
    @Default('') String tierKey,
    @Default(0) int x,
    @Default(0) int y,
    @Default(0) int priceIqd,
    @Default(SeatStatus.free) SeatStatus status,
  }) = _Seat;

  factory Seat.fromJson(Map<String, dynamic> json) => Seat(
    seatId: json['seat_id'] ?? '',
    sectionId: json['section_id'] ?? '',
    row: json['row_label'] ?? json['row'] ?? '',
    seat: json['seat_label'] ?? json['seat'] ?? '',
    tierKey: json['tier_key'] ?? '',
    x: (json['x'] as num?)?.toInt() ?? 0,
    y: (json['y'] as num?)?.toInt() ?? 0,
    priceIqd: (json['price_iqd'] as num?)?.toInt() ?? 0,
    status: SeatStatusFromString.fromString(json['status'] ?? ''),
  );
}
