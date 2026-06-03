import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_layout.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_section.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/venue_mini_map.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/venue_overview_map.dart'
    show colorFromHex;

const double _seatRadius = 15;

/// Focused, zoomable seat picker for a single section. Seats are positioned
/// relative to the section origin; a corner mini-map shows context.
class SectionSeatPicker extends StatefulWidget {
  const SectionSeatPicker({
    super.key,
    required this.section,
    required this.seats,
    required this.selectedSeatIds,
    required this.layout,
    required this.onSeatTap,
  });

  final VenueSection section;
  final List<Seat> seats; // already filtered to this section
  final Set<String> selectedSeatIds;
  final VenueLayout layout;
  final void Function(Seat seat) onSeatTap;

  @override
  State<SectionSeatPicker> createState() => _SectionSeatPickerState();
}

class _SectionSeatPickerState extends State<SectionSeatPicker> {
  final _controller = TransformationController();
  String? _fittedSectionId;

  static const double _pad = 40;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Section-local content size (with padding so edge seats aren't clipped).
  double get _contentW => widget.section.w + _pad * 2;
  double get _contentH => widget.section.h + _pad * 2;

  void _fit(Size viewport) {
    if (_fittedSectionId == widget.section.id) return;
    if (_contentW <= 0 || _contentH <= 0) return;
    final sx = viewport.width / _contentW;
    final sy = viewport.height / _contentH;
    final scale = (sx < sy ? sx : sy).clamp(0.1, 3.0);
    final dx = (viewport.width - _contentW * scale) / 2;
    final dy = (viewport.height - _contentH * scale) / 2;
    _controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _fittedSectionId = widget.section.id;
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(widget.section.fillColor);
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            _fit(constraints.biggest);
            return InteractiveViewer(
              transformationController: _controller,
              constrained: false,
              minScale: 0.3,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(300),
              child: SizedBox(
                width: _contentW,
                height: _contentH,
                child: Stack(
                  children: widget.seats
                      .map((s) => _buildSeat(s, color))
                      .toList(),
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: VenueMiniMap(
            layout: widget.layout,
            highlightSectionId: widget.section.id,
          ),
        ),
      ],
    );
  }

  Widget _buildSeat(Seat seat, Color sectionColor) {
    final isSelected = widget.selectedSeatIds.contains(seat.seatId);
    final isFree = seat.status == SeatStatus.free;

    final Color color;
    if (!isFree) {
      color = Colors.grey.shade400;
    } else if (isSelected) {
      color = AppColors.brandBlue;
    } else {
      color = sectionColor;
    }

    // Position relative to the section origin, offset by padding.
    final left = seat.x - widget.section.x + _pad - _seatRadius;
    final top = seat.y - widget.section.y + _pad - _seatRadius;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: isFree ? () => widget.onSeatTap(seat) : null,
        child: Container(
          width: _seatRadius * 2,
          height: _seatRadius * 2,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white70,
              width: isSelected ? 3 : 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '${seat.row}${seat.seat}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
