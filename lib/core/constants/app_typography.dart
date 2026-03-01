import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // ── Font families ──────────────────────────────────────────────────────────
  static const String _roboto = 'Roboto';
  static const String _graphikBold = 'Graphik-Bold'; // Arabic titles
  static const String _graphikLight = 'Graphik-Light'; // Arabic body

  /// Title font: Graphik-Bold (ar) | Roboto (en)
  static String getTitleFontFamily(String languageCode) =>
      languageCode == 'ar' ? _graphikBold : _roboto;

  /// Body font: Graphik-Light (ar) | Roboto (en)
  static String getBodyFontFamily(String languageCode) =>
      languageCode == 'ar' ? _graphikLight : _roboto;

  // ── Main TextTheme ─────────────────────────────────────────────────────────
  static TextTheme getTextTheme(String languageCode, BuildContext context) {
    final titleFont = getTitleFontFamily(languageCode);
    final bodyFont = getBodyFontFamily(languageCode);

    // Base theme — Roboto for both (we override fontFamily per style below)
    final base = GoogleFonts.robotoTextTheme();
    final textColor = Theme.of(context).colorScheme.onSurface;

    return base.copyWith(
      // ── Display — Graphik-Bold (ar) / Roboto (en) ─────────────────────────
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: textColor,
        fontFamily: titleFont,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),

      // ── Headline — Graphik-Bold (ar) / Roboto (en) ────────────────────────
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),

      // ── Title — Graphik-Bold (ar) / Roboto (en) ───────────────────────────
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textColor,
        fontFamily: titleFont,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: titleFont,
      ),

      // ── Body — Graphik-Light (ar) / Roboto (en) ───────────────────────────
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: bodyFont,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textColor,
        fontFamily: bodyFont,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.4,
        color: textColor,
        fontFamily: bodyFont,
      ),

      // ── Label — Graphik-Light (ar) / Roboto (en) ──────────────────────────
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: bodyFont,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: bodyFont,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: bodyFont,
      ),
    );
  }

  // ── Custom Text Styles ─────────────────────────────────────────────────────

  static TextStyle button({
    required BuildContext context,
    String languageCode = 'en',
  }) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Theme.of(context).colorScheme.onPrimary,
    fontFamily: getBodyFontFamily(languageCode),
  );

  static TextStyle input({
    required BuildContext context,
    String languageCode = 'en',
  }) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: getBodyFontFamily(languageCode),
  );

  static TextStyle hint({
    required BuildContext context,
    String languageCode = 'en',
  }) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.15,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
    fontFamily: getBodyFontFamily(languageCode),
  );

  static TextStyle error({
    required BuildContext context,
    String languageCode = 'en',
  }) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: Theme.of(context).colorScheme.error,
    fontFamily: getBodyFontFamily(languageCode),
  );

  static TextStyle caption({
    required BuildContext context,
    String languageCode = 'en',
  }) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.4,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    fontFamily: getBodyFontFamily(languageCode),
  );

  static TextStyle link({
    required BuildContext context,
    String languageCode = 'en',
  }) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: Theme.of(context).colorScheme.primary,
    decoration: TextDecoration.underline,
    fontFamily: getBodyFontFamily(languageCode),
  );
}
