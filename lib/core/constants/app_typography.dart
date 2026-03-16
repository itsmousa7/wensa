import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static const String _roboto = 'Roboto';
  static const String _graphikBold = 'Graphik-Bold';
  static const String _graphikLight = 'Graphik-Light';

  // Arabic fonts are always in the fallback so Arabic characters render
  // correctly even when the app language is English.
  static const List<String> _titleFallback = [_graphikBold, _graphikLight];
  static const List<String> _bodyFallback = [_graphikLight, _graphikBold];

  static String getTitleFontFamily(String languageCode) =>
      languageCode == 'ar' ? _graphikBold : _roboto;

  static String getBodyFontFamily(String languageCode) =>
      languageCode == 'ar' ? _graphikLight : _roboto;

  static TextTheme getTextTheme(String languageCode, BuildContext context) {
    final titleFont = getTitleFontFamily(languageCode);
    final bodyFont = getBodyFontFamily(languageCode);
    final base = GoogleFonts.robotoTextTheme();
    final textColor = Theme.of(context).colorScheme.onSurface;

    return base.copyWith(
      // ── Display ───────────────────────────────────────────────────────────
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),

      // ── Headline ──────────────────────────────────────────────────────────
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),

      // ── Title ─────────────────────────────────────────────────────────────
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: titleFont,
        fontFamilyFallback: _titleFallback,
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: bodyFont,
        fontFamilyFallback: _bodyFallback,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textColor,
        fontFamily: bodyFont,
        fontFamilyFallback: _bodyFallback,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.4,
        color: textColor,
        fontFamily: bodyFont,
        fontFamilyFallback: _bodyFallback,
      ),

      // ── Label ─────────────────────────────────────────────────────────────
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: bodyFont,
        fontFamilyFallback: _bodyFallback,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: bodyFont,
        fontFamilyFallback: _bodyFallback,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: bodyFont,
        fontFamilyFallback: _bodyFallback,
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
    fontFamilyFallback: _bodyFallback,
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
    fontFamilyFallback: _bodyFallback,
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
    fontFamilyFallback: _bodyFallback,
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
    fontFamilyFallback: _bodyFallback,
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
    fontFamilyFallback: _bodyFallback,
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
    fontFamilyFallback: _bodyFallback,
  );
}
