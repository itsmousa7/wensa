import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/slot.dart';

class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
    required this.slots,
    required this.selectedStartTimes,
    required this.onTap,
  });

  final List<Slot> slots;
  final Set<String> selectedStartTimes;
  final void Function(Slot) onTap;

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = selectedStartTimes.contains(slot.startsAt);
        final isAvailable = slot.available;

        Color bgColor;
        Color textColor;
        BoxBorder? border;
        TextDecoration textDecoration;

        if (!isAvailable) {
          bgColor = colorScheme.surfaceContainerHighest;
          textColor = colorScheme.onSurface.withValues(alpha: 0.38);
          border = null;
          textDecoration = TextDecoration.lineThrough;
        } else if (isSelected) {
          bgColor = colorScheme.primary;
          textColor = colorScheme.onPrimary;
          border = null;
          textDecoration = TextDecoration.none;
        } else {
          bgColor = Colors.transparent;
          textColor = colorScheme.onSurface;
          border = Border.all(color: colorScheme.outline);
          textDecoration = TextDecoration.none;
        }

        return GestureDetector(
          onTap: isAvailable ? () => onTap(slot) : null,
          child: Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              border: border,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              _formatTime(slot.startsAt),
              style: textTheme.bodyMedium?.copyWith(
                color: textColor,
                decoration: textDecoration,
                decorationColor: textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
