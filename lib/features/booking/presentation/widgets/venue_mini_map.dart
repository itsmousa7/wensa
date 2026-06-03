import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_layout.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/venue_overview_map.dart'
    show colorFromHex;

/// Small corner thumbnail of the whole venue, highlighting the section
/// currently being viewed.
class VenueMiniMap extends StatelessWidget {
  const VenueMiniMap({
    super.key,
    required this.layout,
    required this.highlightSectionId,
    this.width = 120,
  });

  final VenueLayout layout;
  final String highlightSectionId;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (layout.canvasWidth <= 0 || layout.canvasHeight <= 0) {
      return const SizedBox.shrink();
    }
    final scale = width / layout.canvasWidth;
    final height = layout.canvasHeight * scale;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusSM,
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusSM,
        child: Stack(
          children: layout.sections.map((s) {
            final isActive = s.id == highlightSectionId;
            final color = colorFromHex(s.fillColor);
            return Positioned(
              left: s.x * scale,
              top: s.y * scale,
              width: s.w * scale,
              height: s.h * scale,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isActive ? 0.9 : 0.3),
                  borderRadius: BorderRadius.circular(2),
                  border: isActive
                      ? Border.all(color: Colors.white, width: 1)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
