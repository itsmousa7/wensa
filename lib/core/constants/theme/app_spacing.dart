import 'package:flutter/material.dart';

/// Centralized spacing, radius, icon, button-height and elevation scale.
/// All numeric layout values used across the app should reference these
/// tokens rather than hardcoded numbers.
class AppSpacing {
  AppSpacing._();

  // ==================== Spacing Scale ====================

  /// Small spacing (8px)
  static const double sm = 8.0;

  /// Medium spacing (12px)
  static const double md = 12.0;

  /// Medium-large spacing (16px) — most commonly used
  static const double mlg = 16.0;

  /// Large spacing (24px)
  static const double lg = 24.0;

  /// Extra large spacing (32px)
  static const double xl = 32.0;

  // ==================== Padding Presets ====================

  /// Zero padding
  static const EdgeInsets paddingZero = EdgeInsets.zero;

  /// All sides small padding
  static const EdgeInsets paddingAllSM = EdgeInsets.all(sm);

  /// Screen edge padding (horizontal)
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: lg);

  // ==================== Border Radius Scale ====================

  /// Extra small (4px)
  static const double radiusXS = 4.0;

  /// Small (8px)
  static const double radiusSM = 8.0;

  /// Medium (12px) — most common
  static const double radiusMD = 12.0;

  /// Large (16px)
  static const double radiusLG = 16.0;

  /// Extra large (20px)
  static const double radiusXL = 20.0;

  // ==================== BorderRadius Presets ====================

  static final BorderRadius borderRadiusXS = BorderRadius.circular(radiusXS);
  static final BorderRadius borderRadiusSM = BorderRadius.circular(radiusSM);
  static final BorderRadius borderRadiusMD = BorderRadius.circular(radiusMD);
  static final BorderRadius borderRadiusLG = BorderRadius.circular(radiusLG);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);

  // ==================== Icon Sizes ====================

  /// Medium icon size (24px) — default
  static const double iconMD = 24.0;

  // ==================== Component Sizes ====================

  /// Button height (default)
  static const double buttonHeight = 56.0;

  /// Small button height
  static const double buttonHeightSM = 40.0;

  /// Large button height
  static const double buttonHeightLG = 64.0;

  // ==================== Elevation / Shadow ====================

  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;

  // ==================== Border Width ====================

  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;
  static const double borderThick = 3.0;
}
