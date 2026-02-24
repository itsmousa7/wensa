import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography system
/// Defines all text styles used throughout the application
class AppTypography {
  AppTypography._();

  // Font families
  static const String _roboto = 'Roboto';
  static const String _ibmPlexSansArabic = 'IBM Plex Sans Arabic';

  /// Get the appropriate font family based on locale
  static String getFontFamily(String languageCode) {
    return languageCode == 'ar' ? _ibmPlexSansArabic : _roboto;
  }

  /// Create TextTheme for the given language
  static TextTheme getTextTheme(String languageCode, {required bool isDark}) {
    final fontFamily = getFontFamily(languageCode);
    final baseTextTheme = languageCode == 'ar'
        ? GoogleFonts.ibmPlexSansArabicTextTheme()
        : GoogleFonts.robotoTextTheme();

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return baseTextTheme.copyWith(
      // Display styles (largest)
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: textColor,
        fontFamily: fontFamily,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
        fontFamily: fontFamily,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: fontFamily,
      ),

      // Headline styles
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
        fontFamily: fontFamily,
      ),

      // Title styles
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: fontFamily,
      ),

      // Body styles (most common)
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: textColor,
        fontFamily: fontFamily,
      ),

      // Label styles (buttons, etc.)
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textColor,
        fontFamily: fontFamily,
      ),
    );
  }

  // ==================== Custom Text Styles ====================

  /// Button text style
  static TextStyle button({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: isDark ? Colors.white : Colors.black,
      fontFamily: getFontFamily(languageCode),
    );
  }

  /// Input field text style
  static TextStyle input({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
      fontFamily: getFontFamily(languageCode),
    );
  }

  /// Hint text style
  static TextStyle hint({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA),
      fontFamily: getFontFamily(languageCode),
    );
  }

  /// Error text style
  static TextStyle error({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: isDark ? const Color(0xFFE54D2E) : const Color(0xFFE54D2E),
      fontFamily: getFontFamily(languageCode),
    );
  }

  /// Caption text style
  static TextStyle caption({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B),
      fontFamily: getFontFamily(languageCode),
    );
  }

  /// Link text style
  static TextStyle link({required bool isDark, String languageCode = 'en'}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: isDark ? const Color(0xFF138353) : const Color(0xFF2DC182),
      decoration: TextDecoration.underline,
      fontFamily: getFontFamily(languageCode),
    );
  }
}
