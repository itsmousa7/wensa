import 'package:flutter/material.dart';

/// Per-outcome color system: background gradient, primary text ("ink"),
/// glow accent, and frosted-panel tints — so the same layout works on both
/// the white success page and the dark failure page.
class PaymentResultPalette {
  const PaymentResultPalette({
    required this.gradient,
    required this.ink,
    required this.glow,
    required this.panelFill,
    required this.panelBorder,
    required this.orbOpacityScale,
  });

  final List<Color> gradient;
  final Color ink;
  final Color glow;
  final Color panelFill;
  final Color panelBorder;

  /// Orbs read stronger on white, so success dampens them.
  final double orbOpacityScale;

  /// Palette for the given outcome + platform brightness. Follows the app
  /// theme: airy white with dark ink in light mode, deep charcoal with light
  /// ink in dark mode — success tinted green, failure tinted red.
  factory PaymentResultPalette.forOutcome({
    required bool success,
    required Brightness brightness,
  }) {
    final dark = brightness == Brightness.dark;
    if (success) return dark ? successDark : successLight;
    return dark ? failureDark : failureLight;
  }

  static const successLight = PaymentResultPalette(
    gradient: [Colors.white, Color(0xFFF6FCF9), Color(0xFFE9F8F0)],
    ink: Color(0xFF0B2B20),
    glow: Color(0xFF2DC182),
    panelFill: Color(0x0D0B2B20), // ink 5%
    panelBorder: Color(0x1F0B2B20), // ink 12%
    orbOpacityScale: 0.7,
  );

  static const failureLight = PaymentResultPalette(
    gradient: [Colors.white, Color(0xFFFDF7F7), Color(0xFFFBECEC)],
    ink: Color(0xFF33100F),
    glow: Color(0xFFE5484D),
    panelFill: Color(0x0D33100F), // ink 5%
    panelBorder: Color(0x1F33100F), // ink 12%
    orbOpacityScale: 0.7,
  );

  static const successDark = PaymentResultPalette(
    gradient: [Color(0xFF0C1211), Color(0xFF0E1B16), Color(0xFF11251C)],
    ink: Color(0xFFEAF6F0),
    glow: Color(0xFF3DDC97),
    panelFill: Color(0x14FFFFFF), // white 8%
    panelBorder: Color(0x1FFFFFFF), // white 12%
    orbOpacityScale: 1,
  );

  static const failureDark = PaymentResultPalette(
    gradient: [Color(0xFF141010), Color(0xFF1E1213), Color(0xFF291516)],
    ink: Color(0xFFF7EDED),
    glow: Color(0xFFFF6B6B),
    panelFill: Color(0x14FFFFFF), // white 8%
    panelBorder: Color(0x1FFFFFFF), // white 12%
    orbOpacityScale: 1,
  );
}
