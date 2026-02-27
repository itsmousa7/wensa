import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_typography.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Main theme configuration for the app
class AppTheme {
  AppTheme._();

  /// Get light theme
  static ThemeData lightTheme({
    String languageCode = 'en',
    required BuildContext context,
  }) {
    final textTheme = AppTypography.getTextTheme(languageCode, context);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightGreenPrimary,
        onPrimary: AppColors.white,
        secondary: AppColors.lightGreenSecondary,
        onSecondary: AppColors.black,
        error: AppColors.lightRedPrimary,
        onError: AppColors.white,
        surface: AppColors.lightPrimary,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightSecondary,
        errorContainer: AppColors.lightRedSecondary, // ← add
        onErrorContainer: AppColors.black,
        surfaceContainer: AppColors.lightTextField,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.white,

      // Typography
      textTheme: textTheme,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: AppSpacing.elevationSM,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: AppSpacing.elevationSM,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLG),
        margin: AppSpacing.paddingZero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.mlg,
          vertical: AppSpacing.mlg,
        ),

        // Border styles
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.lightSecondary,
            width: AppSpacing.borderMedium,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.lightSecondary,
            width: AppSpacing.borderMedium,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.lightGreenSecondary,
            width: AppSpacing.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.lightRedSecondary,
            width: AppSpacing.borderMedium,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.lightRedSecondary,
            width: AppSpacing.borderThick,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: AppColors.lightSecondary.withOpacity(0.5),
            width: AppSpacing.borderThin,
          ),
        ),

        // Text styles
        hintStyle: AppTypography.hint(
          isDark: false,
          languageCode: languageCode,
        ),
        errorStyle: AppTypography.error(
          isDark: false,
          languageCode: languageCode,
        ),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.lightGreenSecondary,
        ),

        // Error settings
        errorMaxLines: 2,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightGreenPrimary,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.lightSecondary,
          disabledForegroundColor: AppColors.lightTextDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.mlg,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMD,
            side: const BorderSide(
              color: AppColors.lightGreenSecondary,
              width: AppSpacing.borderMedium,
            ),
          ),
          textStyle: AppTypography.button(
            isDark: false,
            languageCode: languageCode,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightGreenSecondary,
          disabledForegroundColor: AppColors.lightTextDisabled,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.mlg,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMD,
          ),
          side: const BorderSide(
            color: AppColors.lightGreenSecondary,
            width: AppSpacing.borderMedium,
          ),
          textStyle: AppTypography.button(
            isDark: false,
            languageCode: languageCode,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightGreenSecondary,
          disabledForegroundColor: AppColors.lightTextDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mlg,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTypography.button(
            isDark: false,
            languageCode: languageCode,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          disabledForegroundColor: AppColors.lightTextDisabled,
          iconSize: AppSpacing.iconMD,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightGreenPrimary,
        foregroundColor: AppColors.black,
        elevation: AppSpacing.elevationMD,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLG),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.lightGreenSecondary,
        unselectedItemColor: AppColors.lightTextSecondary,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: AppSpacing.elevationMD,
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.lightGreenPrimary.withOpacity(0.2),
        elevation: AppSpacing.elevationSM,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: AppColors.lightGreenSecondary,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: AppColors.lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.lightGreenSecondary);
          }
          return const IconThemeData(color: AppColors.lightTextSecondary);
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: AppSpacing.borderThin,
        space: AppSpacing.mlg,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: AppSpacing.elevationLG,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXL),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSecondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMD),
        behavior: SnackBarBehavior.floating,
        elevation: AppSpacing.elevationMD,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSecondary,
        selectedColor: AppColors.lightGreenPrimary,
        disabledColor: AppColors.lightSecondary.withOpacity(0.5),
        labelStyle: textTheme.bodySmall,
        padding: AppSpacing.paddingAllSM,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSM),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightGreenSecondary;
          }
          return AppColors.lightTextDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightGreenPrimary;
          }
          return AppColors.lightSecondary;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightGreenSecondary;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: const BorderSide(
          color: AppColors.lightSecondary,
          width: AppSpacing.borderMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXS),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightGreenSecondary;
          }
          return AppColors.lightSecondary;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lightGreenSecondary,
        linearTrackColor: AppColors.lightSecondary,
        circularTrackColor: AppColors.lightSecondary,
      ),
    );
  }

  /// Get dark theme
  static ThemeData darkTheme({
    String languageCode = 'en',
    required BuildContext context,
  }) {
    final textTheme = AppTypography.getTextTheme(languageCode, context);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkGreenPrimary,
        onPrimary: AppColors.white,
        secondary: AppColors.darkGreenSecondary,
        onSecondary: AppColors.white,
        error: AppColors.darkRedPrimary,
        onError: AppColors.white,
        surface: AppColors.darkPrimary,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSecondary,
        errorContainer: AppColors.darkRedSecondary, // ← add
        onErrorContainer: AppColors.white,
        surfaceContainer: AppColors.darkTextField,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.darkPrimary,

      // Typography
      textTheme: textTheme,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: AppSpacing.elevationSM,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkSecondary,
        elevation: AppSpacing.elevationSM,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLG),
        margin: AppSpacing.paddingZero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.mlg,
          vertical: AppSpacing.mlg,
        ),

        // Border styles
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.darkSecondary,
            width: AppSpacing.borderMedium,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.darkSecondary,
            width: AppSpacing.borderMedium,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.darkGreenSecondary,
            width: AppSpacing.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.darkRedSecondary,
            width: AppSpacing.borderMedium,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.darkRedSecondary,
            width: AppSpacing.borderThick,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMD,
          borderSide: BorderSide(
            color: AppColors.darkSecondary.withOpacity(0.5),
            width: AppSpacing.borderThin,
          ),
        ),

        // Text styles
        hintStyle: AppTypography.hint(isDark: true, languageCode: languageCode),
        errorStyle: AppTypography.error(
          isDark: true,
          languageCode: languageCode,
        ),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.darkGreenSecondary,
        ),

        // Error settings
        errorMaxLines: 2,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkGreenPrimary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.darkSecondary,
          disabledForegroundColor: AppColors.darkTextDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.mlg,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMD,
            side: const BorderSide(
              color: AppColors.darkGreenSecondary,
              width: AppSpacing.borderMedium,
            ),
          ),
          textStyle: AppTypography.button(
            isDark: true,
            languageCode: languageCode,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGreenSecondary,
          disabledForegroundColor: AppColors.darkTextDisabled,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.mlg,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMD,
          ),
          side: const BorderSide(
            color: AppColors.darkGreenSecondary,
            width: AppSpacing.borderMedium,
          ),
          textStyle: AppTypography.button(
            isDark: true,
            languageCode: languageCode,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkGreenSecondary,
          disabledForegroundColor: AppColors.darkTextDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mlg,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTypography.button(
            isDark: true,
            languageCode: languageCode,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          disabledForegroundColor: AppColors.darkTextDisabled,
          iconSize: AppSpacing.iconMD,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: AppSpacing.elevationMD,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLG),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSecondary,
        selectedItemColor: AppColors.darkGreenSecondary,
        unselectedItemColor: AppColors.darkTextSecondary,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: AppSpacing.elevationMD,
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSecondary,
        indicatorColor: AppColors.darkGreenPrimary.withOpacity(0.3),
        elevation: AppSpacing.elevationSM,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: AppColors.darkGreenSecondary,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: AppColors.darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.darkGreenSecondary);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary);
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: AppSpacing.borderThin,
        space: AppSpacing.mlg,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSecondary,
        elevation: AppSpacing.elevationLG,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXL),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSecondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMD),
        behavior: SnackBarBehavior.floating,
        elevation: AppSpacing.elevationMD,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSecondary,
        selectedColor: AppColors.darkGreenPrimary,
        disabledColor: AppColors.darkSecondary.withOpacity(0.5),
        labelStyle: textTheme.bodySmall,
        padding: AppSpacing.paddingAllSM,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSM),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkGreenSecondary;
          }
          return AppColors.darkTextDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkGreenPrimary;
          }
          return AppColors.darkSecondary;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkGreenSecondary;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: const BorderSide(
          color: AppColors.darkSecondary,
          width: AppSpacing.borderMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXS),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkGreenSecondary;
          }
          return AppColors.darkSecondary;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkGreenSecondary,
        linearTrackColor: AppColors.darkSecondary,
        circularTrackColor: AppColors.darkSecondary,
      ),
    );
  }
}
