// lib/bottom_bar/widgets/android_nav_shell.dart
//
// Android shell — 4 bar tabs, but only 3 shell branches.
//
// Branch layout (matches router exactly):
//   branch 0 = Home      ↔  bar index 0
//   branch 1 = Favorites ↔  bar index 2   ← NOT 1
//   branch 2 = Profile   ↔  bar index 3   ← NOT 2
//
// Search (bar index 1) is a push route, NOT a shell branch.
// Calling goBranch(1) would navigate to Favorites.
// Calling goBranch(3) would crash (index out of range).
//
// Mapping:
//   bar 0 → goBranch(0)   Home
//   bar 1 → pushNamed      Search  (push on top of current branch)
//   bar 2 → goBranch(1)   Favorites
//   bar 3 → goBranch(2)   Profile

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/bottom_bar/pages/bottom_bar.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_scroll_controller.dart';
import 'package:go_router/go_router.dart';

// Maps bar visual index → shell branch index.
// Returns null for Search (bar 1) because it is a push route, not a branch.
int? _barToBranch(int barIndex) => switch (barIndex) {
  0 => 0, // Home
  1 => null, // Search — push route
  2 => 1, // Favorites
  3 => 2, // Profile
  _ => null,
};

// Maps shell branch index → bar visual index (for highlighting the active tab).
int _branchToBar(int branchIndex) => switch (branchIndex) {
  0 => 0, // Home
  1 => 2, // Favorites
  2 => 3, // Profile
  _ => 0,
};

class AndroidNavShell extends ConsumerWidget {
  const AndroidNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _handleTap(int barIndex, BuildContext context, WidgetRef ref) {
    // Re-tapping the active Home tab scrolls to top.
    if (barIndex == 0 && navigationShell.currentIndex == 0) {
      final ctrl = ref.read(homeScrollControllerProvider);
      if (ctrl.hasClients) {
        ctrl.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
      return;
    }

    final branchIndex = _barToBranch(barIndex);

    if (branchIndex == null) {
      // Search: push on top of whatever branch is active.
      context.pushNamed(RouteNames.search);
      return;
    }

    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Convert branch index → bar index so the correct tab is highlighted.
    final activeBarIndex = _branchToBar(navigationShell.currentIndex);

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
                // FIX: removed Material(type: MaterialType.transparency).
                // That wrapper created a new ink/splash surface that forwarded
                // ripple events from nav bar taps upward into the page content,
                // causing circular ink artifacts to appear over the screen.
                child: BottomBar(
                  currentIndex: activeBarIndex,
                  isAr: isAr,
                  onTap: (i) => _handleTap(i, context, ref),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
