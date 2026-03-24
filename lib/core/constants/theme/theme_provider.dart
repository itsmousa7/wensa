import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

const _themeKey = 'app_theme';

@riverpod
class AppTheme extends _$AppTheme {
  @override
  ThemeState build() {
    _loadSavedTheme();
    return const SystemTheme(); // safe default — matches device until prefs load
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    state = switch (saved) {
      'light' => const LightTheme(),
      'dark' => const DarkTheme(),
      _ => const SystemTheme(), // 'system' or null → follow device
    };
  }

  Future<void> switchTheme(ThemeState themeState) async {
    state = themeState; // update UI immediately (synchronous)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, switch (themeState) {
      LightTheme() => 'light',
      DarkTheme() => 'dark',
      SystemTheme() => 'system',
    });
  }

  /// Toggle between light ↔ dark explicitly.
  ///
  /// [currentIsDark] is the ACTUAL visual brightness (resolves SystemTheme →
  /// device brightness via MediaQuery), so the switch always flips correctly.
  void toggle(bool currentIsDark) {
    switchTheme(currentIsDark ? const LightTheme() : const DarkTheme());
  }

  /// Reset to system/device-controlled theme.
  void followSystem() => switchTheme(const SystemTheme());

  bool get isFollowingSystem => state is SystemTheme;
}
