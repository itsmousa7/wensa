import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/slot.dart';
import 'package:future_riverpod/features/booking/domain/models/slot_availability.dart';

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
        crossAxisCount: 4,
        childAspectRatio: 1.9,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedStartTimes.contains(slot.startsAt);

        SlotAvailability availability;
        try {
          final slotTime = DateTime.parse(slot.startsAt).toLocal();
          if (!slotTime.isAfter(DateTime.now())) {
            availability = SlotAvailability.expired;
          } else if (!slot.available) {
            availability = SlotAvailability.booked;
          } else {
            availability = SlotAvailability.available;
          }
        } catch (_) {
          availability = slot.available
              ? SlotAvailability.available
              : SlotAvailability.booked;
        }

        return _SlotTile(
          isSelected: isSelected,
          availability: availability,
          startLabel: _formatTime(slot.startsAt),
          endLabel: slot.endsAt.isNotEmpty ? _formatTime(slot.endsAt) : '',
          onTap: availability == SlotAvailability.available
              ? () => onTap(slot)
              : null,
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.isSelected,
    required this.availability,
    required this.startLabel,
    required this.endLabel,
    this.onTap,
  });

  final bool isSelected;
  final SlotAvailability availability;
  final String startLabel;
  final String endLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isUnavailable = availability != SlotAvailability.available;

    String? statusLabel;
    if (availability == SlotAvailability.booked) {
      statusLabel = isAr ? 'محجوز' : 'Booked';
    } else if (availability == SlotAvailability.expired) {
      statusLabel = isAr ? 'منتهي' : 'Expired';
    } else if (availability == SlotAvailability.closed) {
      statusLabel = isAr ? 'مغلق' : 'Closed';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected
            ? null
            : isUnavailable
                ? cs.surfaceContainerHighest
                : cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? null
            : Border.all(
                color: isUnavailable
                    ? cs.outline.withValues(alpha: 0.12)
                    : cs.outline.withValues(alpha: 0.3),
              ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : cs.primary.withValues(alpha: 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                startLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : isUnavailable
                          ? cs.onSurface.withValues(alpha: 0.28)
                          : cs.onSurface,
                  decoration: isSelected
                      ? null
                      : isUnavailable
                          ? TextDecoration.lineThrough
                          : null,
                  decorationColor: cs.onSurface.withValues(alpha: 0.28),
                ),
              ),
              if (statusLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : availability == SlotAvailability.booked
                            ? cs.error.withValues(alpha: 0.7)
                            : availability == SlotAvailability.expired
                                ? const Color(0xFF92400E).withValues(alpha: 0.8)
                                : cs.onSurface.withValues(alpha: 0.40),
                  ),
                ),
              ] else if (endLabel.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  endLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.75)
                        : isUnavailable
                            ? cs.onSurface.withValues(alpha: 0.20)
                            : cs.onSurface.withValues(alpha: 0.45),
                    decoration: isSelected
                        ? null
                        : isUnavailable
                            ? TextDecoration.lineThrough
                            : null,
                    decorationColor: cs.onSurface.withValues(alpha: 0.25),
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
