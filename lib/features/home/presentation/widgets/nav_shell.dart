import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_scroll_controller.dart';
import 'package:future_riverpod/features/home/presentation/widgets/bottom_bar.dart';
import 'package:go_router/go_router.dart';

class NavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const NavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final homeScroll = ref.read(homeScrollControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      // ✅ Scaffold بدون bottomNavigationBar نهائياً
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // ✅ Stack يجعل الـ BottomBar يطفو فوق المحتوى
        body: Stack(
          children: [
            // ── Layer 1: الصفحات ─────────────────────────────────────
            navigationShell,

            // ── Layer 2: الـ BottomBar فوق كل شيء ───────────────────
            AnimatedPositioned(
              duration: Duration(microseconds: 250),
              bottom: bottomInset > 0 ? -100 : 10,
              left: 0,
              right: 0,
              child: Material(
                type: MaterialType.transparency,
                child: BottomBar(
                  currentIndex: navigationShell.currentIndex,
                  isAr: isAr,
                  onTap: (index) {
                    if (index == 0 && navigationShell.currentIndex == 0) {
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
