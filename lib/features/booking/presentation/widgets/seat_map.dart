import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';

class SeatMapWidget extends StatelessWidget {
  const SeatMapWidget({
    super.key,
    required this.seats,
    required this.selectedSeatIds,
    required this.tierColors,
    required this.onSeatTap,
    this.filterTierKeys,
  });

  final List<Seat> seats;
  final Set<String> selectedSeatIds;
  final Map<String, Color> tierColors;
  final void Function(Seat seat) onSeatTap;
  final Set<String>? filterTierKeys; // null = show all

  static const double _seatRadius = 12.0;
  static const double _canvasWidth = 1200.0;
  static const double _canvasHeight = 800.0;
  static const Color _selectedColor = Color(0xFF2196F3);

  List<Seat> get _visibleSeats {
    if (filterTierKeys == null || filterTierKeys!.isEmpty) return seats;
    return seats.where((s) => filterTierKeys!.contains(s.tierKey)).toList();
  }

  Widget _buildSeat(Seat seat) {
    final isSelected = selectedSeatIds.contains(seat.seatId);
    final isFree = seat.status == SeatStatus.free;

    final Color color;
    if (!isFree) {
      color = Colors.grey.shade400;
    } else if (isSelected) {
      color = _selectedColor;
    } else {
      color = tierColors[seat.tierKey] ?? Colors.grey;
    }

    return Positioned(
      left: seat.x.toDouble() - _seatRadius,
      top: seat.y.toDouble() - _seatRadius,
      child: GestureDetector(
        onTap: isFree ? () => onSeatTap(seat) : null,
        child: Container(
          width: _seatRadius * 2,
          height: _seatRadius * 2,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '${seat.row}${seat.seat}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleSeats;

    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 3.0,
      child: SizedBox(
        width: _canvasWidth,
        height: _canvasHeight,
        child: Stack(
          children: visible.map(_buildSeat).toList(),
        ),
      ),
    );
  }
}
