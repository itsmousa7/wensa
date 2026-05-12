import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/slot_availability.dart';

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.shift,
    required this.isSelected,
    required this.availability,
    required this.onTap,
  });

  final FarmShift shift;
  final bool isSelected;
  final SlotAvailability availability;
  final VoidCallback onTap;

  // Vivid accent — borders, strip, icon fill bg, dark-theme text
  Color _accent() {
    switch (shift.shiftType) {
      case FarmShiftType.day:
        return const Color(0xFFF59E0B); // amber-400
      case FarmShiftType.night:
        return const Color(0xFF6366F1); // indigo-500
      case FarmShiftType.full:
        return const Color(0xFF10B981); // emerald-500
    }
  }

  // Darker variant — text on light surfaces (passes WCAG AA contrast)
  Color _accentDark() {
    switch (shift.shiftType) {
      case FarmShiftType.day:
        return const Color(0xFF92400E); // amber-900
      case FarmShiftType.night:
        return const Color(0xFF3730A3); // indigo-800
      case FarmShiftType.full:
        return const Color(0xFF065F46); // emerald-900
    }
  }

  IconData _icon() {
    switch (shift.shiftType) {
      case FarmShiftType.day:
        return Icons.wb_sunny_rounded;
      case FarmShiftType.night:
        return Icons.nightlight_round;
      case FarmShiftType.full:
        return Icons.brightness_4_rounded;
    }
  }

  String _label({required bool isAr}) {
    switch (shift.shiftType) {
      case FarmShiftType.day:
        return isAr ? 'نهار' : 'Day';
      case FarmShiftType.night:
        return isAr ? 'ليل' : 'Night';
      case FarmShiftType.full:
        return isAr ? 'يوم كامل' : 'Full Day';
    }
  }

  // HH:MM:SS → 12h format (e.g. 21:00 → 9:00 PM)
  static String _toTime12h(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  String _formattedPrice() {
    return shift.priceIqd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final accent = _accent();
    // On dark surfaces the vivid accent is readable; on light surfaces use
    // the darkened variant to satisfy contrast requirements.
    final textAccent = isDark ? accent : _accentDark();

    // ── State tokens ──────────────────────────────────────────────────────────
    final Color cardBg;
    final Color borderColor;
    final double borderWidth;
    final List<BoxShadow> shadows;
    final Color iconBg;
    final Color iconColor;
    final Color labelColor;
    final Color timeColor;
    final Color priceColor;
    final Color currencyColor;

    final bool isUnavailable = availability != SlotAvailability.available;

    if (isUnavailable) {
      cardBg = cs.surfaceContainerLowest;
      borderColor = cs.outlineVariant.withValues(alpha: 0.50);
      borderWidth = 1.0;
      shadows = [];
      iconBg = cs.surfaceContainerHighest;
      iconColor = cs.onSurface.withValues(alpha: 0.28);
      labelColor = cs.onSurface.withValues(alpha: 0.35);
      timeColor = cs.onSurface.withValues(alpha: 0.24);
      priceColor = cs.onSurface.withValues(alpha: 0.35);
      currencyColor = cs.onSurface.withValues(alpha: 0.22);
    } else if (isSelected) {
      cardBg = cs.primary.withValues(alpha: isDark ? 0.16 : 0.07);
      borderColor = cs.primary;
      borderWidth = 1.8;
      shadows = [
        BoxShadow(
          color: cs.primary.withValues(alpha: isDark ? 0.38 : 0.22),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
      ];
      iconBg = cs.primary;
      iconColor = Colors.white;
      labelColor = cs.primary;
      timeColor = cs.primary.withValues(alpha: 0.62);
      priceColor = cs.primary;
      currencyColor = cs.primary.withValues(alpha: 0.50);
    } else {
      cardBg = cs.surface;
      borderColor = cs.outlineVariant;
      borderWidth = 1.0;
      shadows = [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
      iconBg = accent.withValues(alpha: isDark ? 0.18 : 0.10);
      iconColor = textAccent;
      labelColor = cs.onSurface;
      timeColor = cs.onSurface.withValues(alpha: 0.50);
      priceColor = cs.onSurface;
      currencyColor = cs.onSurface.withValues(alpha: 0.40);
    }

    final timeStr =
        '${_toTime12h(shift.startsTime)} – ${_toTime12h(shift.endsTime)}';

    return GestureDetector(
      onTap: isUnavailable ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: ClipRRect(
          // Slightly inset so clip follows the border exactly
          borderRadius: BorderRadius.circular(15.2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Body ────────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        // Icon badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            switch (availability) {
                              SlotAvailability.booked  => Icons.lock_outline_rounded,
                              SlotAvailability.expired => Icons.schedule_rounded,
                              SlotAvailability.closed  => Icons.block_rounded,
                              _                        => _icon(),
                            },
                            size: 22,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Label + status chip + time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      style: (tt.titleSmall ??
                                              const TextStyle())
                                          .copyWith(
                                        color: labelColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.1,
                                      ),
                                      child: Text(
                                        _label(isAr: isAr),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  if (isUnavailable) ...[
                                    const SizedBox(width: 6),
                                    _Chip(
                                      label: switch (availability) {
                                        SlotAvailability.booked  => isAr ? 'محجوز'  : 'Booked',
                                        SlotAvailability.expired => isAr ? 'منتهي'  : 'Expired',
                                        SlotAvailability.closed  => isAr ? 'مغلق'   : 'Closed',
                                        _                        => '',
                                      },
                                      bg: switch (availability) {
                                        SlotAvailability.booked  => cs.errorContainer.withValues(alpha: 0.75),
                                        SlotAvailability.expired => const Color(0xFFF59E0B).withValues(alpha: 0.18),
                                        SlotAvailability.closed  => cs.surfaceContainerHighest,
                                        _                        => cs.surfaceContainerHighest,
                                      },
                                      fg: switch (availability) {
                                        SlotAvailability.booked  => cs.onErrorContainer,
                                        SlotAvailability.expired => const Color(0xFF92400E),
                                        SlotAvailability.closed  => cs.onSurface.withValues(alpha: 0.55),
                                        _                        => cs.onSurface,
                                      },
                                    ),
                                  ] else if (shift.shiftType == FarmShiftType.full) ...[
                                    const SizedBox(width: 6),
                                    _Chip(
                                      label: isAr
                                          ? 'يحجب اليوم كاملاً'
                                          : 'Blocks full day',
                                      bg: isSelected
                                          ? cs.primary.withValues(alpha: 0.12)
                                          : cs.primaryContainer
                                              .withValues(alpha: 0.55),
                                      fg: isSelected
                                          ? cs.primary
                                          : cs.onPrimaryContainer,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: (tt.bodySmall ?? const TextStyle())
                                    .copyWith(
                                  color: timeColor,
                                  letterSpacing: 0.2,
                                ),
                                child: Text(timeStr),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Price
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: (tt.titleMedium ?? const TextStyle())
                                  .copyWith(
                                color: priceColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              child: Text(_formattedPrice()),
                            ),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: (tt.labelSmall ?? const TextStyle())
                                  .copyWith(
                                color: currencyColor,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                              child: const Text('IQD'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badge chip ────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}
