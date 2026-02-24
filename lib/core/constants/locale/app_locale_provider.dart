// lib/core/constants/locale/locale_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_state.dart';

part 'app_locale_provider.g.dart';

const _localeKey = 'app_locale';

@riverpod
class AppLocale extends _$AppLocale {
  @override
  LocaleState build() {
    _loadSavedLocale();
    return const SystemLocale(); // follow device language by default
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_localeKey);
    state = switch (saved) {
      'en' => const EnglishLocale(),
      'ar' => const ArabicLocale(),
      _ => const SystemLocale(),
    };
  }

  Future<void> switchLocale(LocaleState localeState) async {
    state = localeState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localeKey,
      switch (localeState) {
        EnglishLocale() => 'en',
        ArabicLocale() => 'ar',
        SystemLocale() => 'system',
      },
    );
  }

  void toggle() {
    switchLocale(
      switch (state) {
        EnglishLocale() => const ArabicLocale(),
        ArabicLocale() => const EnglishLocale(),
        SystemLocale() => const ArabicLocale(),
      },
    );
  }
}