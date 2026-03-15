import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PlaceStatisticChip extends StatelessWidget {
  const PlaceStatisticChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.highlighted = false,
    this.accentColor,
    required this.textColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlighted;
  final Color? accentColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color =
        accentColor ??
        (highlighted ? cs.primary : cs.onSurface.withValues(alpha: 0.5));
    final bg = accentColor != null
        ? accentColor!.withValues(alpha: 0.08)
        : highlighted
        ? cs.primary.withValues(alpha: 0.08)
        : cs.surfaceContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          Row(
            children: [
              Icon(icon, size: 16, color: color),
              Gap(10),
              Text(
                label,
                style: tt.titleMedium?.copyWith(color: textColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
