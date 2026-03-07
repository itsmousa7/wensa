import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  WensaBadgeType
//  Single source of truth for every badge in the app
// ─────────────────────────────────────────────────────────────────────────────
enum WensaBadgeType {
  trending, // 🔥 رائج  — feed cards & see-all trending
  event, // 🎉 حدث  — feed cards & hot events
  newOpening, // افتتح مؤخراً — new opening cards & full-width cards
  hotEvent, // 🔥 الأكثر سخونة — hot events section (same look, different label)
}

// ─────────────────────────────────────────────────────────────────────────────
//  WensaBadge  — stateless widget, drop it anywhere
// ─────────────────────────────────────────────────────────────────────────────
class WensaBadge extends StatelessWidget {
  const WensaBadge({super.key, required this.type, required this.isAr});

  final WensaBadgeType type;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final (color, text) = _resolve(type, isAr, Theme.of(context).colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: AppTypography.getBodyFontFamily(isAr ? 'ar' : 'en'),
          height: 1.4,
        ),
      ),
    );
  }

  /// Centralised color + label — change once, updates everywhere
  static (Color, String) _resolve(
    WensaBadgeType type,
    bool isAr,
    ColorScheme cs,
  ) {
    return switch (type) {
      WensaBadgeType.trending => (
        AppColors.darkRedSecondary,
        isAr ? '🔥 رائج' : '🔥 Hot',
      ),
      WensaBadgeType.event => (
        const Color(0xFF3E3E9B),
        isAr ? '🎉 حدث' : '🎉 Event',
      ),
      WensaBadgeType.newOpening => (
        cs.primary,
        isAr ? 'افتتح مؤخراً' : 'Just Opened',
      ),
      WensaBadgeType.hotEvent => (
        AppColors.darkRedSecondary,
        isAr ? '🔥 الأكثر سخونة' : '🔥 Hot',
      ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Convenience — keeps old call sites compiling with zero changes
// ─────────────────────────────────────────────────────────────────────────────
/// @deprecated  Use WensaBadge(type: WensaBadgeType.newOpening, isAr: isAr)
Widget newOpeningBadge(bool isAr, BuildContext context) =>
    WensaBadge(type: WensaBadgeType.newOpening, isAr: isAr);
