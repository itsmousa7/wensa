// lib/bottom_bar/widgets/android_nav_shell.dart
//
// Android shell — 4 bar tabs, 4 shell branches, 1:1 mapping.
//
// Branch layout (matches router exactly):
//   branch 0 = Home      ↔  bar 0
//   branch 1 = Search    ↔  bar 1
//   branch 2 = Favorites ↔  bar 2
//   branch 3 = Profile   ↔  bar 3
//
// No index conversion needed — bar index == branch index directly.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/bottom_bar/pages/bottom_bar.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_scroll_controller.dart';
import 'package:go_router/go_router.dart';

class AndroidNavShell extends ConsumerWidget {
  const AndroidNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _handleTap(int barIndex, WidgetRef ref) {
    // Re-tapping the active Home tab scrolls back to the top.
    if (barIndex == 0 && navigationShell.currentIndex == 0) {
      final scrollCtrl = ref.read(homeScrollControllerProvider);
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
      return;
    }

    // Every tab (including Search) is a real shell branch on Android —
    // no special-casing, no pushNamed.
    navigationShell.goBranch(
      barIndex,
      initialLocation: barIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            navigationShell,

            if (!keyboardOpen)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Material(
                  type: MaterialType.transparency,
                  child: BottomBar(
                    // shell branch index == bar visual index — pass directly.
                    currentIndex: navigationShell.currentIndex,
                    isAr: isAr,
                    onTap: (i) => _handleTap(i, ref),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
