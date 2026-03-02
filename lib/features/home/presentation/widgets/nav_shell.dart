import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/widgets/bottom_bar.dart';
import 'package:go_router/go_router.dart';

/// Scroll controller that the HomePage registers itself with so NavShell
/// can trigger a scroll-to-top when the user re-taps the Home tab.
final homeScrollControllerProvider = Provider<ScrollController>(
  (ref) => ScrollController(),
);

class NavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const NavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final homeScroll = ref.read(homeScrollControllerProvider);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        // ── Transparent so the page content shows behind the floating bar ──
        // extendBody: true → body draws beneath the bottomNavigationBar area,
        // which makes the glass/frosted nav bar look like it truly floats.
        extendBody: true,
        // No system bottom padding needed — the bar floats above it.
        extendBodyBehindAppBar: true,
        bottomNavigationBar: BottomBar(
          currentIndex: navigationShell.currentIndex,
          isAr: isAr,
          onTap: (index) {
            if (index == 0 && navigationShell.currentIndex == 0) {
              // Already on Home — scroll to top instead of rebuilding the branch
              if (homeScroll.hasClients) {
                homeScroll.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );
              }
              return;
            }
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
        body: navigationShell,
      ),
    );
  }
}
