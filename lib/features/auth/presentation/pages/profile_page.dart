import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart';
import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInformation = ref.watch(userProfileProvider);
    final currentTheme = ref.watch(appThemeProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.goNamed(RouteNames.home),
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        title: const Text('Profile'),
        actions: [
          AppButton.icon(
            onPressed: () => ref.read(appThemeProvider.notifier).toggle(),
            icon: Icon(
              switch (currentTheme) {
                LightTheme() => CupertinoIcons.sun_max,
                DarkTheme() => CupertinoIcons.moon,
                SystemTheme() =>
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark
                      ? CupertinoIcons.moon
                      : CupertinoIcons.sun_max,
              },
            ),
          ),
          IconButton(
            onPressed: () => ref.read(appLocaleProvider.notifier).toggle(),
            icon: Icon(
              switch (ref.watch(appLocaleProvider)) {
                ArabicLocale() => Icons.language, // showing AR → tap for EN
                _ => Icons.language_outlined, // showing EN → tap for AR
              },
            ),
          ),
        ],
      ),
      body: userInformation.when(
        data: (data) {
          final user = data.first;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Welcome back ${user.firstName} ${user.secondName}!'),
                TextButton(
                  onPressed: () {
                    context.goNamed(RouteNames.changePassword);
                  },
                  child: const Text(
                    'Reset Password',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.goNamed(RouteNames.changeName);
                  },
                  child: const Text(
                    'Change Name',
                    style: TextStyle(color: Color.fromARGB(255, 54, 244, 54)),
                  ),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text('Error loading profile: $error'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
