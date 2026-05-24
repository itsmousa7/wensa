import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';

/// Returns the seats that the current selection would leave orphaned.
///
/// A seat is orphan iff it is free, not selected, and both its immediate
/// row-neighbors are blockers (booked / held / selected / off the row edge),
/// AND at least one of those blockers is in `selectedSeatIds`. The selection
/// must be a cause — pre-existing orphans from prior bookings are never
/// reported because the buyer cannot fix them.
///
/// A row edge alone is not sufficient causality — a selected seat must
/// appear on at least one immediate side. For example, a free seat at
/// the row's left end with a `taken` seat on its right is NOT an orphan,
/// because the user's selection didn't cause it.
///
/// `seats` should be the full set of seats for the event (every section,
/// every status). The cost is O(n log n) per (section, row) for the sort.
List<Seat> findOrphanSeats({
  required List<Seat> seats,
  required Set<String> selectedSeatIds,
}) {
  // Group by (sectionId, row).
  final byRow = <String, List<Seat>>{};
  for (final s in seats) {
    final key = '${s.sectionId}::${s.row}';
    (byRow[key] ??= <Seat>[]).add(s);
  }

  final orphans = <Seat>[];

  for (final row in byRow.values) {
    row.sort(_compareSeats);

    for (var i = 0; i < row.length; i++) {
      final seat = row[i];
      if (seat.status != SeatStatus.free) continue;
      if (selectedSeatIds.contains(seat.seatId)) continue;

      final left = i > 0 ? row[i - 1] : null;
      final right = i < row.length - 1 ? row[i + 1] : null;

      final leftBlocker = _isBlocker(left, selectedSeatIds);
      final rightBlocker = _isBlocker(right, selectedSeatIds);
      if (!leftBlocker || !rightBlocker) continue;

      final leftFromSelection =
          left != null && selectedSeatIds.contains(left.seatId);
      final rightFromSelection =
          right != null && selectedSeatIds.contains(right.seatId);
      if (!leftFromSelection && !rightFromSelection) continue;

      orphans.add(seat);
    }
  }

  return orphans;
}

bool _isBlocker(Seat? neighbor, Set<String> selectedSeatIds) {
  // Row edge, occupied seat, or part of the user's selection.
  return neighbor == null ||
      neighbor.status != SeatStatus.free ||
      selectedSeatIds.contains(neighbor.seatId);
}

int _compareSeats(Seat a, Seat b) {
  final ai = int.tryParse(a.seat);
  final bi = int.tryParse(b.seat);
  if (ai != null && bi != null) return ai.compareTo(bi);
  return a.seat.compareTo(b.seat);
}
