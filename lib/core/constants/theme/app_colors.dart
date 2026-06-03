import 'package:flutter/material.dart';

/// App color palette. All hex literals used across the app are funneled
/// through this class — widgets must not declare raw `Color(0x…)` values.
class AppColors {
  AppColors._();

  // ==================== Brand / Light Theme ====================

  static const Color alert = Color(0xFFFF2929);
  static const Color headline = Color(0xFFFF6F3C);
  static const Color headline2 = Color(0xFFFFD93D);
  static const Color balance2 = Color(0xFF957DAD);

  static const Color lightGraySecondary = Color(0xFFA8A8A8);
  static const Color darkGraySecondary = Color(0xFF737373);

  static const Color lightPrimary = Color(0xFFF8F8F8);
  static const Color disableGray = Color(0xFFA0A0B8);
  static const Color lightSecondary = Color.fromARGB(255, 231, 231, 231);

  static const Color lightGreenPrimary = Color.fromARGB(219, 52, 144, 162);
  static const Color lightGreenSecondary = Color(0xFF155b6a);

  static const Color lightRedPrimary = Color(0xFFFFD8D3);
  static const Color lightRedSecondary = Color(0xFFE54D2E);

  // ==================== Dark Theme ====================

  static const Color darkPrimary = Color(0xFF121212);
  static const Color darkSecondary = Color(0xFF313131);

  static const Color darkGreenPrimary = Color(0xEE06778D);
  static const Color darkGreenSecondary = Color(0xFF124e5b);

  static const Color darkRedPrimary = Color(0xFF7E3222);
  static const Color darkRedSecondary = Color(0xFFE54D2E);

  static const Color lightTextField = Color(0xFFf5f6f7);

  // ==================== Common ====================

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ==================== Text ====================

  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextDisabled = Color(0xFFAAAAAA);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextDisabled = Color(0xFF666666);

  // ==================== Semantic ====================

  static const Color success = Color(0xFF2DC182);
  static const Color info = Color(0xFF3B82F6);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color darkDivider = Color(0xFF404040);

  // ==================== Extended Palette ====================
  // Pre-existing brand/semantic hex values used across the app, exposed
  // here so widgets can stop hardcoding raw Color(0x…) literals.

  /// Material Blue 500 — used by plans/paywall/booking accents.
  static const Color brandBlue = Color(0xFF2196F3);

  /// Material Red 600 — used by booking errors and destructive actions.
  static const Color danger = Color(0xFFE53935);

  /// Material Gray 500 — used as a neutral muted gray.
  static const Color neutralGray = Color(0xFF9E9E9E);

  /// Material Gray 600 — used as a secondary muted text.
  static const Color mutedText = Color(0xFF757575);

  /// Material Green 800 — used by discount/success darker tone.
  static const Color successDark = Color(0xFF2E7D32);
}
