import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_theme.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart'
    hide AppTheme;
import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:future_riverpod/core/router/router_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ✅ runApp immediately — no awaits blocking the UI
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) => runApp(const ProviderScope(child: MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(appThemeProvider);
    final localeState = ref.watch(appLocaleProvider);

    final locale = switch (localeState) {
      EnglishLocale() => const Locale('en'),
      ArabicLocale() => const Locale('ar'),
      SystemLocale() => null,
    };

    final languageCode = switch (localeState) {
      ArabicLocale() => 'ar',
      _ => 'en',
    };

    return MaterialApp.router(
      title: 'Wensa',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme(languageCode: languageCode, context: context),
      darkTheme: AppTheme.darkTheme(
        languageCode: languageCode,
        context: context,
      ),
      themeMode: switch (themeState) {
        LightTheme() => ThemeMode.light,
        DarkTheme() => ThemeMode.dark,
        SystemTheme() => ThemeMode.system,
      },
      routerConfig: router,
    );
  }
}
