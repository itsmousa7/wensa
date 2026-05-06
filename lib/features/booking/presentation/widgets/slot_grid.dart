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
      final hour = dt.hour;
      final minute = dt.minute;
      final period = hour < 12 ? 'AM' : 'PM';
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final m = minute.toString().padLeft(2, '0');
      return '$h:$m $period';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedStartTimes.contains(slot.startsAt);
        final isAvailable = slot.available;
        return _SlotTile(
          isSelected: isSelected,
          isAvailable: isAvailable,
          startLabel: _formatTime(slot.startsAt),
          endLabel: slot.endsAt.isNotEmpty ? _formatTime(slot.endsAt) : '',
          onTap: isAvailable ? () => onTap(slot) : null,
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.isSelected,
    required this.isAvailable,
    required this.startLabel,
    required this.endLabel,
    this.onTap,
  });

  final bool isSelected;
  final bool isAvailable;
  final String startLabel;
  final String endLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected
            ? null
            : isAvailable
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? null
            : Border.all(
                color: isAvailable
                    ? colorScheme.outline.withValues(alpha: 0.35)
                    : colorScheme.outline.withValues(alpha: 0.15),
              ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : colorScheme.primary.withValues(alpha: 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                startLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : isAvailable
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.3),
                  decoration: isAvailable ? null : TextDecoration.lineThrough,
                  decorationColor: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              if (endLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Container(
                  height: 1,
                  width: 20,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.5)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  endLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : isAvailable
                            ? colorScheme.onSurface.withValues(alpha: 0.6)
                            : colorScheme.onSurface.withValues(alpha: 0.25),
                    decoration: isAvailable ? null : TextDecoration.lineThrough,
                    decorationColor: colorScheme.onSurface.withValues(alpha: 0.25),
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
