import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/supabase_constants.dart';
import 'package:future_riverpod/core/constants/theme/app_theme.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart'
    hide AppTheme;
import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:future_riverpod/core/router/router_provider.dart';
import 'package:future_riverpod/features/notifications/fcm_service.dart';
import 'package:future_riverpod/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background Message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Firebase (will fail gracefully until native config is added)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Initialization skipped: $e');
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 2),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  // Initialize FCM after Supabase is ready (non-critical, wrapped in try/catch)
  try {
    await FcmService.instance.initialize(Supabase.instance.client);
  } catch (e) {
    debugPrint('[FCM] Initialization error (non-fatal): $e');
  }

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
