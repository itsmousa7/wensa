import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // Font families
  static const String _roboto = 'Roboto';
  static const String _hrof = 'Zain';
  // static const String _hrof = 'Hazm';
  static const String _rubik = 'Rubik'; // Google font — body (Arabic)

  /// Title font: Hrof (ar) | Roboto (en)
  static String getTitleFontFamily(String languageCode) {
    return languageCode == 'ar' ? _hrof : _roboto;
  }

  /// Body font: Rubik (ar) | Roboto (en)
  static String getBodyFontFamily(String languageCode) {
    return languageCode == 'ar' ? _rubik : _roboto;
  }

  /// Create TextTheme for the given language
  static TextTheme getTextTheme(String languageCode, BuildContext context) {
    final titleFont = getTitleFontFamily(languageCode);

    final baseTextTheme = languageCode == 'ar'
        ? GoogleFonts.rubikTextTheme() // base theme from Rubik for Arabic
        : GoogleFonts.robotoTextTheme();

    final textColor = Theme.of(context).colorScheme.onSurface;

    return baseTextTheme.copyWith(
      // ── Display — Hrof (ar) / Roboto (en) ────────────────
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: textColor,
        fontFamily: titleFont,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),

      // ── Headline — Hrof (ar) / Roboto (en) ───────────────
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),

      // ── Title — Hrof (ar) / Roboto (en) ──────────────────
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textColor,
        fontFamily: titleFont,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textColor,
        fontFamily: titleFont,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: titleFont,
      ),

      // ── Body — Rubik (ar) / Roboto (en) ──────────────────
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: languageCode == 'ar'
            ? GoogleFonts.rubik()
                  .fontFamily // ✅ correct internal path
            : GoogleFonts.roboto().fontFamily,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
        color: textColor,
        fontFamily: languageCode == 'ar'
            ? GoogleFonts.rubik().fontFamily
            : GoogleFonts.roboto().fontFamily,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: textColor,
        fontFamily: languageCode == 'ar'
            ? GoogleFonts.rubik().fontFamily
            : GoogleFonts.roboto().fontFamily,
      ),

      // ── Label — Rubik (ar) / Roboto (en) ─────────────────
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: languageCode == 'ar'
            ? GoogleFonts.rubik().fontFamily
            : GoogleFonts.roboto().fontFamily,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: languageCode == 'ar'
            ? GoogleFonts.rubik().fontFamily
            : GoogleFonts.roboto().fontFamily,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: languageCode == 'ar'
            ? GoogleFonts.rubik().fontFamily
            : GoogleFonts.roboto().fontFamily,
      ),
    );
  }

  // ==================== Custom Text Styles ====================

  /// Button text style — body font
  static TextStyle button({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: isDark ? Colors.white : Colors.black,
      fontFamily: getBodyFontFamily(languageCode),
    );
  }

  /// Input field text style — body font
  static TextStyle input({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
      fontFamily: getBodyFontFamily(languageCode),
    );
  }

  /// Hint text style — body font
  static TextStyle hint({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA),
      fontFamily: getBodyFontFamily(languageCode),
    );
  }

  /// Error text style — body font
  static TextStyle error({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: const Color(0xFFE54D2E),
      fontFamily: getBodyFontFamily(languageCode),
    );
  }

  /// Caption text style — body font
  static TextStyle caption({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B),
      fontFamily: getBodyFontFamily(languageCode),
    );
  }

  /// Link text style — body font
  static TextStyle link({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: isDark ? const Color(0xFF138353) : const Color(0xFF2DC182),
      decoration: TextDecoration.underline,
      fontFamily: getBodyFontFamily(languageCode),
    );
  }
}
