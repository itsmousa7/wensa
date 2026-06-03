import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/slot_availability.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final bool isUnavailable = availability != SlotAvailability.available;

    // ── State tokens ─────────────────────────────────────────────────────────
    final Color borderColor;
    final double borderWidth;
    final Color iconBgColor;
    final Color iconColor;
    final Color textColor;
    final Color subtextColor;
    final Color priceColor;
    final Color currencyColor;
    final double cardOpacity;

    if (isUnavailable) {
      // Same surface, same border — just fade the entire content
      borderColor = cs.onSurface.withValues(alpha: 0.08);
      borderWidth = 0.5;
      iconBgColor = cs.onSurface.withValues(alpha: 0.05);
      iconColor = cs.onSurface.withValues(alpha: 0.22);
      textColor = cs.onSurface.withValues(alpha: 0.32);
      subtextColor = cs.onSurface.withValues(alpha: 0.20);
      priceColor = cs.onSurface.withValues(alpha: 0.25);
      currencyColor = cs.onSurface.withValues(alpha: 0.18);
      cardOpacity = 0.7;
    } else if (isSelected) {
      borderColor = cs.primary;
      borderWidth = 1.5;
      iconBgColor = cs.primary.withValues(alpha: 0.12);
      iconColor = cs.primary;
      textColor = cs.primary;
      subtextColor = cs.primary.withValues(alpha: 0.65);
      priceColor = cs.primary;
      currencyColor = cs.primary.withValues(alpha: 0.55);
      cardOpacity = 1.0;
    } else {
      borderColor = cs.outlineVariant;
      borderWidth = 0.5;
      iconBgColor = cs.onSurface.withValues(alpha: 0.05);
      iconColor = cs.onSurface.withValues(alpha: 0.45);
      textColor = cs.onSurface;
      subtextColor = cs.onSurface.withValues(alpha: 0.50);
      priceColor = cs.onSurface;
      currencyColor = cs.onSurface.withValues(alpha: 0.40);
      cardOpacity = 1.0;
    }

    final timeStr =
        '${_toTime12h(shift.startsTime)} – ${_toTime12h(shift.endsTime)}';

    return GestureDetector(
      onTap: isUnavailable ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: cardOpacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              if (!isUnavailable)
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // ── Icon badge ─────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Icon(
                  isUnavailable
                      ? switch (availability) {
                          SlotAvailability.booked =>
                            Icons.lock_outline_rounded,
                          SlotAvailability.expired =>
                            Icons.schedule_rounded,
                          SlotAvailability.closed => Icons.block_rounded,
                          _ => _icon(),
                        }
                      : _icon(),
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),

              // ── Label + badge + time ───────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: (tt.titleSmall ?? const TextStyle()).copyWith(
                              color: textColor,
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
                          _StatusBadge(availability: availability),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: (tt.bodySmall ?? const TextStyle()).copyWith(
                        color: subtextColor,
                        letterSpacing: 0.15,
                      ),
                      child: Text(timeStr),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Price ──────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (tt.titleMedium ?? const TextStyle()).copyWith(
                      color: priceColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    child: Text(_formattedPrice()),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (tt.labelSmall ?? const TextStyle()).copyWith(
                      color: currencyColor,
                      letterSpacing: 1.0,
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
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.availability});

  final SlotAvailability availability;

  // Hardcoded colors — theme error/warning tokens are non-standard in this app
  static const _red = AppColors.danger;
  static const _amber = Color(0xFFE6A20C);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final String label;
    final Color bg;
    final Color fg;

    switch (availability) {
      case SlotAvailability.booked:
        label = isAr ? 'محجوز' : 'Booked';
        bg = _red.withValues(alpha: 0.10);
        fg = _red;
      case SlotAvailability.expired:
        label = isAr ? 'منتهي' : 'Expired';
        bg = _amber.withValues(alpha: 0.10);
        fg = _amber;
      case SlotAvailability.closed:
        label = isAr ? 'مغلق' : 'Closed';
        bg = cs.onSurface.withValues(alpha: 0.06);
        fg = cs.onSurface.withValues(alpha: 0.45);
      case SlotAvailability.available:
        label = '';
        bg = Colors.transparent;
        fg = Colors.transparent;
    }

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
