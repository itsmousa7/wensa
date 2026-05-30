import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_layout.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_section.dart';

/// Parses a `#RRGGBB` (or `#AARRGGBB`) hex string into a [Color].
Color colorFromHex(String hex, {Color fallback = const Color(0xFF6C63FF)}) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final value = int.tryParse(h, radix: 16);
  return value == null ? fallback : Color(value);
}

/// Zoomable venue overview — the stage and all section blocks positioned
/// spatially. Tapping a seating section drills into its seat picker.
class VenueOverviewMap extends StatefulWidget {
  const VenueOverviewMap({
    super.key,
    required this.layout,
    required this.onSectionTap,
  });

  final VenueLayout layout;
  final void Function(VenueSection section) onSectionTap;

  @override
  State<VenueOverviewMap> createState() => _VenueOverviewMapState();
}

class _VenueOverviewMapState extends State<VenueOverviewMap> {
  final _controller = TransformationController();
  bool _fitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitToViewport(Size viewport) {
    if (_fitted) return;
    final cw = widget.layout.canvasWidth;
    final ch = widget.layout.canvasHeight;
    if (cw <= 0 || ch <= 0) return;
    final scale = (viewport.width / cw).clamp(0.1, 1.0) <
            (viewport.height / ch).clamp(0.1, 1.0)
        ? viewport.width / cw
        : viewport.height / ch;
    final dx = (viewport.width - cw * scale) / 2;
    final dy = (viewport.height - ch * scale) / 2;
    _controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _fitted = true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fitToViewport(constraints.biggest);
        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: 0.2,
          maxScale: 5.0,
          boundaryMargin: const EdgeInsets.all(400),
          child: SizedBox(
            width: widget.layout.canvasWidth,
            height: widget.layout.canvasHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.white),
                ),
                if (widget.layout.backgroundImageUrl != null &&
                    widget.layout.backgroundImageUrl!.isNotEmpty)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.5,
                      child: CachedNetworkImage(
                        imageUrl: widget.layout.backgroundImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ...widget.layout.sections.map(_buildSection),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(VenueSection s) {
    return Positioned(
      left: s.x,
      top: s.y,
      width: s.w,
      height: s.h,
      child: SectionBlock(
        section: s,
        onTap: s.isTappable && !s.soldOut
            ? () => widget.onSectionTap(s)
            : null,
      ),
    );
  }
}

/// A single section block — stage / label / seating — rendered on the canvas.
class SectionBlock extends StatelessWidget {
  const SectionBlock({super.key, required this.section, this.onTap});

  final VenueSection section;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final color = colorFromHex(section.fillColor);
    final name = isAr
        ? (section.nameAr.isNotEmpty ? section.nameAr : section.nameEn)
        : (section.nameEn.isNotEmpty ? section.nameEn : section.nameAr);

    final bool isStage = section.isStage;
    final bool isSeating = section.isSeating;
    final bool isGA = section.isGeneralAdmission;
    final bool isInteractive = section.isTappable;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isStage
              ? color
              : color.withValues(alpha: isGA ? 0.10 : (isSeating ? 0.18 : 0.30)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: section.soldOut ? 0.4 : 1),
            width: isGA ? 2.5 : 2,
            style: isGA ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isStage ? 26 : 18,
                  color: isStage ? Colors.white : color,
                ),
              ),
              if (isGA) ...[
                const SizedBox(height: 2),
                Text(
                  isAr ? 'مقاعد عامة' : 'General admission',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
              if (isInteractive && section.priceIqd > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${section.priceIqd.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} IQD',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
              if (isInteractive) ...[
                const SizedBox(height: 2),
                Text(
                  section.soldOut
                      ? (isAr ? 'نفدت' : 'Sold out')
                      : '${section.freeCount} ${isAr ? 'متاح' : 'free'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: section.soldOut
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
