import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/slot.dart';
import 'package:future_riverpod/features/booking/domain/models/slot_availability.dart';
import 'package:future_riverpod/features/discounts/domain/models/merchant_discount.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
    required this.slots,
    required this.selectedStartTimes,
    required this.onTap,
    this.discount,
  });

  final List<Slot> slots;
  final Set<String> selectedStartTimes;
  final void Function(Slot) onTap;
  final MerchantDiscount? discount;

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
        childAspectRatio: 1.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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

        int? discountPercent;
        if (discount != null && availability == SlotAvailability.available) {
          try {
            final dt = DateTime.parse(slot.startsAt).toLocal();
            if (discount!.appliesOnDate(dt) &&
                discount!.appliesAtHour(dt.hour)) {
              discountPercent = discount!.percent.round();
            }
          } catch (_) {}
        }

        return _SlotTile(
          isSelected: isSelected,
          availability: availability,
          startLabel: _formatTime(slot.startsAt),
          endLabel: slot.endsAt.isNotEmpty ? _formatTime(slot.endsAt) : '',
          discountPercent: discountPercent,
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
    this.discountPercent,
    this.onTap,
  });

  final bool isSelected;
  final SlotAvailability availability;
  final String startLabel;
  final String endLabel;
  final int? discountPercent;
  final VoidCallback? onTap;

  /// Renders a time like "7:00 AM" with the am/pm part as a small superscript.
  Widget _timeText(
    String label, {
    required Color color,
    required double numSize,
    required FontWeight weight,
    TextDecoration? decoration,
  }) {
    final parts = label.split(' ');
    final time = parts.first;
    final period = parts.length > 1 ? parts[1].toLowerCase() : '';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: time,
            style: TextStyle(
              fontSize: numSize,
              fontWeight: weight,
              color: color,
              decoration: decoration,
              decorationColor: color,
            ),
          ),
          if (period.isNotEmpty)
            WidgetSpan(
              alignment: PlaceholderAlignment.bottom,
              child: Padding(
                padding: const EdgeInsets.only(left: 1.5),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: numSize * 0.62,
                    fontWeight: FontWeight.w700,
                    color: color,
                    decoration: decoration,
                    decorationColor: color,
                  ),
                ),
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isUnavailable = availability != SlotAvailability.available;
    final hasDiscount = discountPercent != null && !isUnavailable;
    const dealColor = Color(0xFFE5484D);

    String? statusLabel;
    if (availability == SlotAvailability.booked) {
      statusLabel = isAr ? 'محجوز' : 'Booked';
    } else if (availability == SlotAvailability.expired) {
      statusLabel = isAr ? 'منتهي' : 'Expired';
    } else if (availability == SlotAvailability.closed) {
      statusLabel = isAr ? 'مغلق' : 'Closed';
    }

    final startColor = isUnavailable
        ? cs.onSurface.withValues(alpha: 0.28)
        : cs.onSurface;
    final endColor = isUnavailable
        ? cs.onSurface.withValues(alpha: 0.20)
        : cs.onSurface.withValues(alpha: 0.5);
    final strike = isUnavailable ? TextDecoration.lineThrough : null;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isUnavailable ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(
          color: isSelected
              ? cs.primary
              : isUnavailable
                  ? cs.outline.withValues(alpha: 0.12)
                  : cs.outlineVariant.withValues(alpha: 0.7),
          width: isSelected ? 2 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMD,
          splashColor: cs.primary.withValues(alpha: 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timeText(
                startLabel,
                color: startColor,
                numSize: 17,
                weight: FontWeight.w800,
                decoration: strike,
              ),
              if (statusLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: availability == SlotAvailability.booked
                        ? cs.error.withValues(alpha: 0.7)
                        : availability == SlotAvailability.expired
                            ? const Color(0xFF92400E).withValues(alpha: 0.8)
                            : cs.onSurface.withValues(alpha: 0.40),
                  ),
                ),
              ] else if (endLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                _timeText(
                  endLabel,
                  color: endColor,
                  numSize: 13,
                  weight: FontWeight.w600,
                  decoration: strike,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!hasDiscount) return tile;

    // Tile stays identical to a normal slot; the deal badge floats as a
    // separate pill stacked above the top-right corner.
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        tile,
        Positioned(
          top: -8,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: dealColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: dealColor.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '$discountPercent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
