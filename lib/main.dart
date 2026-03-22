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
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2b3pqd2xrem9yZHVka2hhbWN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwOTA4MzksImV4cCI6MjA4NjY2NjgzOX0'
        '.VYsaJ7TST2PuHQFmalwRuENxpeUGylkHI59YiRyjxzc',
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 2),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static Locale? _toLocale(LocaleState state) => switch (state) {
    EnglishLocale() => const Locale('en'),
    ArabicLocale() => const Locale('ar'),
    SystemLocale() => null,
  };

  static String _toLangCode(LocaleState state) => switch (state) {
    ArabicLocale() => 'ar',
    _ => 'en',
  };

  // FIX: was hardcoded to ThemeMode.system — dark mode never applied.
  // Now reads appThemeProvider and maps ThemeState → ThemeMode.
  static ThemeMode _toThemeMode(ThemeState state) => switch (state) {
    LightTheme() => ThemeMode.light,
    DarkTheme() => ThemeMode.dark,
    SystemTheme() => ThemeMode.system,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);
    final themeState = ref.watch(appThemeProvider);
    final langCode = _toLangCode(locale);
    final themeMode = _toThemeMode(themeState);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme(languageCode: langCode, context: context),
      darkTheme: AppTheme.darkTheme(languageCode: langCode, context: context),
      themeMode: themeMode,
      locale: _toLocale(locale),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
