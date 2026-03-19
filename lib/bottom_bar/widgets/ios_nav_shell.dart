// lib/bottom_bar/widgets/ios_nav_shell.dart
//
// iOS shell — CNTabBar shows 3 tabs (Home / Favorites / Profile).
// Search is pushed as a route via the CNButton beside the tab bar.
//
// The router has 4 branches:
//   branch 0 = Home
//   branch 1 = Search   ← never activated by the tab bar on iOS
//   branch 2 = Favorites
//   branch 3 = Profile
//
// Mapping tables (defined once, used in both directions):
//   bar 0 → branch 0   (Home)
//   bar 1 → branch 2   (Favorites)
//   bar 2 → branch 3   (Profile)

import 'package:cupertino_native/components/button.dart';
import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/bottom_bar/pages/bottom_bar.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_scroll_controller.dart';
import 'package:go_router/go_router.dart';

// ── Index mapping ─────────────────────────────────────────────────────────────

/// iOS bar index (0-2) → shell branch index (0,2,3).
/// Branch 1 (Search) is never a destination for the tab bar.
const _barToBranch = [0, 2, 3];

/// Shell branch index → iOS bar index.
/// Branch 1 (Search) has no bar equivalent — returns -1 (should never happen).
int _branchToBar(int branch) {
  return switch (branch) {
    0 => 0,
    2 => 1,
    3 => 2,
    _ =>
      0, // fallback: highlight Home (e.g. if Search branch is somehow active)
  };
}

// ── Shell widget ──────────────────────────────────────────────────────────────

class IosNavShell extends ConsumerWidget {
  const IosNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _handleTap(int barIndex, WidgetRef ref, BuildContext context) {
    final branch = _barToBranch[barIndex];

    // Re-tapping Home scrolls to top instead of re-navigating.
    if (branch == 0 && navigationShell.currentIndex == 0) {
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

    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Convert the current shell branch back to a bar visual index so the
    // correct tab is highlighted.
    final barIndex = _branchToBar(navigationShell.currentIndex);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            navigationShell,

            if (!keyboardOpen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                // ⚠️ No Material wrapper here.
                // Material(type: MaterialType.transparency) still creates a
                // Flutter hit-test surface that intercepts pointer events before
                // they reach the native CNTabBar (UiKitView). Taps survive
                // because they resolve instantly, but swipe/drag gestures are
                // absorbed by Flutter's gesture arena and the native view never
                // receives them — killing the liquid glass slide behaviour.
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // CNTabBar (3 tabs — Search is excluded)
                    Expanded(
                      child: BottomBar(
                        currentIndex: barIndex,
                        isAr: isAr,
                        onTap: (i) => _handleTap(i, ref, context),
                      ),
                    ),

                    // Search: pushed as a route on iOS
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 32,
                        bottom: 25,
                        left: 32,
                      ),
                      child: CNButton.icon(
                        icon: const CNSymbol('magnifyingglass'),
                        onPressed: () => context.pushNamed(RouteNames.search),
                        size: 60,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
