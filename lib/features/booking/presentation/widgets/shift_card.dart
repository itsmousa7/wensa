import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.shift,
    required this.isSelected,
    required this.isBooked,
    required this.onTap,
  });

  final FarmShift shift;
  final bool isSelected;
  final bool isBooked;
  final VoidCallback onTap;

  IconData _icon() {
    switch (shift.shiftType) {
      case FarmShiftType.day:
        return Icons.wb_sunny;
      case FarmShiftType.night:
        return Icons.nightlight_round;
      case FarmShiftType.full:
        return Icons.brightness_4;
    }
  }

  String _label() {
    switch (shift.shiftType) {
      case FarmShiftType.day:
        return 'Day';
      case FarmShiftType.night:
        return 'Night';
      case FarmShiftType.full:
        return 'Full Day';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final Color backgroundColor;
    final Color foregroundColor;
    final Color subtextColor;

    if (isBooked) {
      backgroundColor =
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      foregroundColor = colorScheme.onSurface.withValues(alpha: 0.38);
      subtextColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else if (isSelected) {
      backgroundColor = colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
      subtextColor = colorScheme.onPrimary.withValues(alpha: 0.8);
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      foregroundColor = colorScheme.onSurface;
      subtextColor = colorScheme.outline;
    }

    return GestureDetector(
      onTap: isBooked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected && !isBooked
              ? Border.all(color: colorScheme.primary, width: 2)
              : Border.all(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(_icon(), color: foregroundColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _label(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      // "Booked" chip — takes priority over "Blocks the full day"
                      if (isBooked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAr ? 'محجوز' : 'Booked',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                    ),
                          ),
                        ),
                      ] else if (shift.shiftType == FarmShiftType.full) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(alpha: 0.2)
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAr ? 'يحجب اليوم كاملاً' : 'Blocks the full day',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.onPrimaryContainer,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shift.startsTime} – ${shift.endsTime}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtextColor,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${shift.priceIqd} IQD',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
