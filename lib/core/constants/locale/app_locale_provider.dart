// lib/core/constants/locale/locale_provider.dart
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final localeCode = switch (localeState) {
      EnglishLocale() => 'en',
      ArabicLocale() => 'ar',
      SystemLocale() => 'system',
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, localeCode);

    // Sync to Supabase so backend sends notifications in the right language.
    // Only sync 'ar'/'en'; skip 'system' (no canonical value to store).
    if (localeCode != 'system') {
      _syncLocaleToSupabase(localeCode);
    }
  }

  void _syncLocaleToSupabase(String localeCode) {
    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      supabase
          .schema('profiles')
          .from('app_users')
          .update({'preferred_locale': localeCode})
          .eq('id', uid)
          .then((_) => debugPrint('[Locale] Synced preferred_locale=$localeCode to Supabase'))
          .catchError((e) => debugPrint('[Locale] Failed to sync locale: $e'));
    } catch (e) {
      debugPrint('[Locale] Supabase sync error: $e');
    }
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