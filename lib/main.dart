import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_theme.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart'
    hide AppTheme;
import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:future_riverpod/core/router/router_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qvozjwlkzordudkhamcu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2b3pqd2xrem9yZHVka2hhbWN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwOTA4MzksImV4cCI6MjA4NjY2NjgzOX0.VYsaJ7TST2PuHQFmalwRuENxpeUGylkHI59YiRyjxzc',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(appThemeProvider);
    final localeState = ref.watch(appLocaleProvider);

    // Convert LocaleState to Locale
    final locale = switch (localeState) {
      EnglishLocale() => const Locale('en'),
      ArabicLocale() => const Locale('ar'),
      SystemLocale() => null, // null = follow device
    };

    // Get language code for typography
    final languageCode = switch (localeState) {
      ArabicLocale() => 'ar',
      _ => 'en', // default to en for system unless device is Arabic
    };

    return MaterialApp.router(
      title: 'Flutter Demo',
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme(languageCode: languageCode),
      darkTheme: AppTheme.darkTheme(languageCode: languageCode),
      themeMode: switch (themeState) {
        LightTheme() => ThemeMode.light,
        DarkTheme() => ThemeMode.dark,
        SystemTheme() => ThemeMode.system,
      },
      routerConfig: router,
    );
  }
}
