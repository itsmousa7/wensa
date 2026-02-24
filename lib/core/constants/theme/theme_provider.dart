import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

const _themeKey = 'app_theme';

@riverpod
class AppTheme extends _$AppTheme {
  @override
  @override
  ThemeState build() {
    _loadSavedTheme();
    return const SystemTheme(); // ← system default until loaded
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    state = switch (saved) {
      'light' => const LightTheme(),
      'dark' => const DarkTheme(),
      _ => const SystemTheme(), // ← null or unknown = system
    };
  }

  Future<void> switchTheme(ThemeState themeState) async {
    state = themeState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      switch (themeState) {
        LightTheme() => 'light',
        DarkTheme() => 'dark',
        SystemTheme() => 'system',
      },
    );
  }

  void toggle() {
    switchTheme(
      switch (state) {
        LightTheme() => const DarkTheme(),
        DarkTheme() => const LightTheme(),
        SystemTheme() => const DarkTheme(), // system → go dark first
      },
    );
  }
}
