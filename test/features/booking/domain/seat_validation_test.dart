import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';
import 'package:future_riverpod/features/booking/domain/seat_validation.dart';

Seat _seat({
  required String id,
  required String row,
  required String seat,
  String section = 'sec-1',
  SeatStatus status = SeatStatus.free,
}) =>
    Seat(seatId: id, sectionId: section, row: row, seat: seat, status: status);

void main() {
  group('findOrphanSeats', () {
    test('empty selection produces no orphans', () {
      final seats = [
        _seat(id: '1', row: 'A', seat: '1'),
        _seat(id: '2', row: 'A', seat: '2'),
        _seat(id: '3', row: 'A', seat: '3'),
      ];
      expect(findOrphanSeats(seats: seats, selectedSeatIds: {}), isEmpty);
    });

    test('selection sandwiching a free seat creates one orphan', () {
      // Row A: seats 1, 2, 3. User selects 1 and 3. Seat 2 is orphaned.
      final seats = [
        _seat(id: '1', row: 'A', seat: '1'),
        _seat(id: '2', row: 'A', seat: '2'),
        _seat(id: '3', row: 'A', seat: '3'),
      ];
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'1', '3'});
      expect(orphans.map((s) => s.seatId).toList(), ['2']);
    });

    test('selection adjacent to row edge with one free seat orphans it', () {
      // Row A: seats 1, 2. User selects 2. Seat 1 is at row edge with selection
      // on its right, so both sides are blockers (edge + selection).
      final seats = [
        _seat(id: '1', row: 'A', seat: '1'),
        _seat(id: '2', row: 'A', seat: '2'),
      ];
      final orphans = findOrphanSeats(seats: seats, selectedSeatIds: {'2'});
      expect(orphans.map((s) => s.seatId).toList(), ['1']);
    });

    test('pre-existing orphan (booked sandwich) is not reported', () {
      // Row A: seats 1 (taken), 2 (free), 3 (taken). User selects an unrelated
      // seat in row B. Seat 2 is orphan by pre-existing booking, but the
      // selection did not cause it — so it is NOT reported.
      final seats = [
        _seat(id: '1', row: 'A', seat: '1', status: SeatStatus.taken),
        _seat(id: '2', row: 'A', seat: '2'),
        _seat(id: '3', row: 'A', seat: '3', status: SeatStatus.taken),
        _seat(id: '10', row: 'B', seat: '1'),
        _seat(id: '11', row: 'B', seat: '2'),
        _seat(id: '12', row: 'B', seat: '3'),
      ];
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'10'});
      expect(orphans, isEmpty);
    });

    test('held seats count as blockers like taken seats', () {
      // Row A: 1 (held), 2 (free), 3 (free but in selectedSeatIds). The held seat
      // + the user's selection sandwich seat 2 — at least one blocker is from
      // the selection, so seat 2 IS an orphan.
      final seats = [
        _seat(id: '1', row: 'A', seat: '1', status: SeatStatus.held),
        _seat(id: '2', row: 'A', seat: '2'),
        _seat(id: '3', row: 'A', seat: '3'),
      ];
      final orphans = findOrphanSeats(seats: seats, selectedSeatIds: {'3'});
      expect(orphans.map((s) => s.seatId).toList(), ['2']);
    });

    test('seats sort numerically not lexicographically', () {
      // Row A seat labels: '1', '2', '10'. Lexicographic ordering would place
      // '10' between '1' and '2'. Numeric sort puts them 1, 2, 10. User selects
      // 1 and 10 — after sort, seat 2 is sandwiched by both selected seats.
      // Seat 2 is an orphan.
      final seats = [
        _seat(id: 'a', row: 'A', seat: '1'),
        _seat(id: 'b', row: 'A', seat: '2'),
        _seat(id: 'c', row: 'A', seat: '10'),
      ];
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'a', 'c'});
      expect(orphans.map((s) => s.seatId).toList(), ['b']);
    });

    test('rows are independent — selecting in one row does not affect another',
        () {
      final seats = [
        _seat(id: 'a1', row: 'A', seat: '1'),
        _seat(id: 'a2', row: 'A', seat: '2'),
        _seat(id: 'a3', row: 'A', seat: '3'),
        _seat(id: 'b1', row: 'B', seat: '1'),
        _seat(id: 'b2', row: 'B', seat: '2'),
        _seat(id: 'b3', row: 'B', seat: '3'),
      ];
      // Select row A seats 1 and 3 (orphans seat A-2). Row B untouched.
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'a1', 'a3'});
      expect(orphans.map((s) => s.seatId).toList(), ['a2']);
    });

    test('sections are independent', () {
      // Same row label "A" in two sections — must not merge.
      final seats = [
        _seat(id: 'sx1', section: 'sec-X', row: 'A', seat: '1'),
        _seat(id: 'sx2', section: 'sec-X', row: 'A', seat: '2'),
        _seat(id: 'sy1', section: 'sec-Y', row: 'A', seat: '1'),
        _seat(id: 'sy2', section: 'sec-Y', row: 'A', seat: '2'),
      ];
      // Select sx2. In sec-X row A, seat 1 has edge-left and selection-right
      // → orphan. Sec-Y is untouched.
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'sx2'});
      expect(orphans.map((s) => s.seatId).toList(), ['sx1']);
    });

    test('selected seats themselves are never orphans', () {
      final seats = [
        _seat(id: '1', row: 'A', seat: '1'),
        _seat(id: '2', row: 'A', seat: '2'),
      ];
      // Both selected: nothing free to be orphan.
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'1', '2'});
      expect(orphans, isEmpty);
    });

    test('non-numeric seat labels fall back to lexicographic sort', () {
      // Row A: A1, A2, A3 (alphanumeric labels). int.tryParse fails, falls
      // back to compareTo. User selects A1 and A3 → A2 orphan.
      final seats = [
        _seat(id: 'x', row: 'A', seat: 'A1'),
        _seat(id: 'y', row: 'A', seat: 'A2'),
        _seat(id: 'z', row: 'A', seat: 'A3'),
      ];
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'x', 'z'});
      expect(orphans.map((s) => s.seatId).toList(), ['y']);
    });
  });
}
