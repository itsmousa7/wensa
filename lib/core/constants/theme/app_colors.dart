import 'package:flutter/material.dart';

/// App color palette
/// Defines all colors used throughout the application
class AppColors {
  AppColors._();

  // ==================== Light Theme Colors ====================

  static const Color alert = Color(0xFFFF2929);
  static const Color headline = Color(0xFFFF6F3C);
  static const Color headline2 = Color(0xFFFFD93D);
  static const Color secondary = Color(0xFF4FC3F7);
  static const Color secondary2 = Color(0xFF81C784);
  static const Color balance = Color(0xFFFF9EAA);
  static const Color balance2 = Color(0xFF957DAD);
  static const Color background = Color(0xFFFFF7E3);
  static const Color background2 = Color(0xFFF5F5F5);

  static const Color circle = Color(0xFFE9E9E9);
  static const Color shadegrey = Color(0xFFE9E9E9);
  static const Color shadegrey2 = Color(0xFF303030);
  static const Color fieldhover = Color(0xFFf0f5f7);
  static const Color blackground = Color(0xFF181818);

  /// Primary background color for light theme
  static const Color lightPrimary = Color(0xFFF8F8F8);

  /// Secondary background color for light theme
  static const Color lightSecondary = Color(0xFFEDEDED);

  /// Primary green color for buttons and actions (light theme)
  static const Color lightGreenPrimary = Color.fromARGB(219, 52, 144, 162);

  /// Secondary green color for button borders (light theme)
  static const Color lightGreenSecondary = Color(0xFF155b6a);

  /// Primary red color for errors and deletion (light theme)
  static const Color lightRedPrimary = Color(0xFFFFD8D3);

  /// Secondary red color for error borders (light theme)
  static const Color lightRedSecondary = Color(0xFFE54D2E);

  // ==================== Dark Theme Colors ====================

  /// Primary background color for dark theme
  static const Color darkPrimary = Color(0xFF121212);

  /// Secondary background color for dark theme
  static const Color darkSecondary = Color(0xFF313131);

  /// Primary green color for buttons and actions (dark theme)

  static const Color darkGreenPrimary = Color.fromARGB(239, 6, 119, 141);

  /// Secondary green color for button borders (dark theme)
  static const Color darkGreenSecondary = Color(0xFF124e5b);

  /// Primary red color for errors and deletion (dark theme)
  static const Color darkRedPrimary = Color(0xFF7E3222);

  /// Secondary red color for error borders (dark theme)
  static const Color darkRedSecondary = Color(0xFFE54D2E);
  static const Color lightTextField = Color(0xFFf5f6f7);
  static const Color darkTextField = Color(0xFF242d35);

  // ==================== Common Colors ====================

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black
  static const Color black = Color(0xFF000000);

  /// Transparent
  static const Color transparent = Colors.transparent;

  // ==================== Text Colors ====================

  /// Primary text color for light theme
  static const Color lightTextPrimary = Color(0xFF1A1A1A);

  /// Secondary text color for light theme (muted)
  static const Color lightTextSecondary = Color(0xFF6B6B6B);

  /// Disabled text color for light theme
  static const Color lightTextDisabled = Color(0xFFAAAAAA);

  /// Primary text color for dark theme
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// Secondary text color for dark theme (muted)
  static const Color darkTextSecondary = Color(0xFFB3B3B3);

  /// Disabled text color for dark theme
  static const Color darkTextDisabled = Color(0xFF666666);

  // ==================== Utility Colors ====================

  /// Success color (can use green variants)
  static const Color success = Color(0xFF2DC182);

  /// Warning color
  static const Color warning = Color(0xFFFFB020);

  /// Info color
  static const Color info = Color(0xFF3B82F6);

  /// Divider color for light theme
  static const Color lightDivider = Color(0xFFE0E0E0);

  /// Divider color for dark theme
  static const Color darkDivider = Color(0xFF404040);
}
