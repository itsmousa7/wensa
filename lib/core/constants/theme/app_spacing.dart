import 'package:flutter/material.dart';

/// App spacing and sizing constants
/// Defines consistent spacing, border radius, and sizing throughout the app
class AppSpacing {
  AppSpacing._();

  // ==================== Spacing Values ====================

  /// Extra extra small spacing (2px)
  static const double xxs = 2.0;

  /// Extra small spacing (4px)
  static const double xs = 4.0;

  /// Small spacing (8px)
  static const double sm = 8.0;

  /// Medium spacing (12px)
  static const double md = 12.0;

  /// Medium-large spacing (16px) - Most commonly used
  static const double mlg = 16.0;

  /// Large spacing (24px)
  static const double lg = 24.0;

  /// Extra large spacing (32px)
  static const double xl = 32.0;

  /// Extra extra large spacing (40px)
  static const double xxl = 40.0;

  /// Extra extra extra large spacing (48px)
  static const double xxxl = 48.0;

  // ==================== Padding Presets ====================

  /// Zero padding
  static const EdgeInsets paddingZero = EdgeInsets.zero;

  /// All sides XXS padding
  static const EdgeInsets paddingAllXXS = EdgeInsets.all(xxs);

  /// All sides XS padding
  static const EdgeInsets paddingAllXS = EdgeInsets.all(xs);

  /// All sides small padding
  static const EdgeInsets paddingAllSM = EdgeInsets.all(sm);

  /// All sides medium padding
  static const EdgeInsets paddingAllMD = EdgeInsets.all(md);

  /// All sides medium-large padding (most common)
  static const EdgeInsets paddingAllMLG = EdgeInsets.all(mlg);

  /// All sides large padding
  static const EdgeInsets paddingAllLG = EdgeInsets.all(lg);

  /// All sides extra large padding
  static const EdgeInsets paddingAllXL = EdgeInsets.all(xl);

  /// Horizontal medium-large padding
  static const EdgeInsets paddingH = EdgeInsets.symmetric(horizontal: mlg);

  /// Vertical medium-large padding
  static const EdgeInsets paddingV = EdgeInsets.symmetric(vertical: mlg);

  /// Screen edge padding (horizontal)
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: lg);

  /// Card content padding
  static const EdgeInsets paddingCard = EdgeInsets.all(mlg);

  /// Bottom navigation bar padding
  static const EdgeInsets paddingBottomNav = EdgeInsets.symmetric(
    horizontal: mlg,
    vertical: sm,
  );

  // ==================== Border Radius ====================

  /// No border radius
  static const double radiusNone = 0.0;

  /// Extra small border radius (4px)
  static const double radiusXS = 4.0;

  /// Small border radius (8px)
  static const double radiusSM = 8.0;

  /// Medium border radius (12px) - Most commonly used
  static const double radiusMD = 12.0;

  /// Large border radius (16px)
  static const double radiusLG = 16.0;

  /// Extra large border radius (20px)
  static const double radiusXL = 20.0;

  /// Extra extra large border radius (24px)
  static const double radiusXXL = 24.0;

  /// Full/circular border radius (9999px)
  static const double radiusFull = 9999.0;

  // ==================== BorderRadius Presets ====================

  /// No border radius
  static const BorderRadius borderRadiusNone = BorderRadius.zero;

  /// Extra small border radius
  static BorderRadius borderRadiusXS = BorderRadius.circular(radiusXS);

  /// Small border radius
  static BorderRadius borderRadiusSM = BorderRadius.circular(radiusSM);

  /// Medium border radius (most common)
  static BorderRadius borderRadiusMD = BorderRadius.circular(radiusMD);

  /// Large border radius
  static BorderRadius borderRadiusLG = BorderRadius.circular(radiusLG);

  /// Extra large border radius
  static BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);

  /// Extra extra large border radius
  static BorderRadius borderRadiusXXL = BorderRadius.circular(radiusXXL);

  /// Full/circular border radius
  static BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  /// Top only medium border radius
  static BorderRadius borderRadiusTopMD = const BorderRadius.only(
    topLeft: Radius.circular(radiusMD),
    topRight: Radius.circular(radiusMD),
  );

  /// Bottom only medium border radius
  static BorderRadius borderRadiusBottomMD = const BorderRadius.only(
    bottomLeft: Radius.circular(radiusMD),
    bottomRight: Radius.circular(radiusMD),
  );

  // ==================== Icon Sizes ====================

  /// Extra small icon size (16px)
  static const double iconXS = 16.0;

  /// Small icon size (20px)
  static const double iconSM = 20.0;

  /// Medium icon size (24px) - Most commonly used
  static const double iconMD = 24.0;

  /// Large icon size (32px)
  static const double iconLG = 32.0;

  /// Extra large icon size (48px)
  static const double iconXL = 48.0;

  /// Extra extra large icon size (64px)
  static const double iconXXL = 64.0;

  // ==================== Component Sizes ====================

  /// Button height
  static const double buttonHeight = 56.0;

  /// Small button height
  static const double buttonHeightSM = 40.0;

  /// Large button height
  static const double buttonHeightLG = 64.0;

  /// Input field height
  static const double inputHeight = 56.0;

  /// Small input field height
  static const double inputHeightSM = 40.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 72.0;

  /// Avatar size small
  static const double avatarSM = 32.0;

  /// Avatar size medium
  static const double avatarMD = 48.0;

  /// Avatar size large
  static const double avatarLG = 64.0;

  /// Avatar size extra large
  static const double avatarXL = 96.0;

  // ==================== Elevation/Shadow ====================

  /// No elevation
  static const double elevationNone = 0.0;

  /// Small elevation
  static const double elevationSM = 2.0;

  /// Medium elevation
  static const double elevationMD = 4.0;

  /// Large elevation
  static const double elevationLG = 8.0;

  /// Extra large elevation
  static const double elevationXL = 16.0;

  // ==================== Border Width ====================

  /// Thin border (1px)
  static const double borderThin = 1.0;

  /// Medium border (2px)
  static const double borderMedium = 2.0;

  /// Thick border (3px)
  static const double borderThick = 3.0;

  // ==================== Opacity ====================

  /// Disabled opacity
  static const double opacityDisabled = 0.38;

  /// Medium opacity
  static const double opacityMedium = 0.60;

  /// High opacity
  static const double opacityHigh = 0.87;
}
