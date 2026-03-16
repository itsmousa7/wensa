import 'dart:io';
import 'dart:ui';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

// ── Nav items (unchanged) ─────────────────────────────────────────────────────

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelEn;
  final String labelAr;
  final String sfSymbol; // ← SF Symbol name for iOS liquid glass

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelEn,
    required this.labelAr,
    required this.sfSymbol,
  });
}

const kNavItems = [
  NavItem(
    icon: CupertinoIcons.home,
    activeIcon: CupertinoIcons.house_fill,
    labelEn: 'Home',
    labelAr: 'الرئيسية',
    sfSymbol: 'house.fill',
  ),
  NavItem(
    icon: CupertinoIcons.search,
    activeIcon: CupertinoIcons.search,
    labelEn: 'Search',
    labelAr: 'بحث',
    sfSymbol: 'magnifyingglass',
  ),
  NavItem(
    icon: CupertinoIcons.heart,
    activeIcon: CupertinoIcons.heart_fill,
    labelEn: 'Favorites',
    labelAr: 'المفضلة',
    sfSymbol: 'heart.fill',
  ),
  NavItem(
    icon: CupertinoIcons.person,
    activeIcon: CupertinoIcons.person_fill,
    labelEn: 'Profile',
    labelAr: 'حسابي',
    sfSymbol: 'person.fill',
  ),
];

// ── Public entry point — routes to platform-correct bar ──────────────────────

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAr;

  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAr = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _LiquidGlassBar(
        currentIndex: currentIndex,
        onTap: onTap,
        isAr: isAr,
      );
    }
    return _MaterialBar(currentIndex: currentIndex, onTap: onTap, isAr: isAr);
  }
}

// ── iOS — Liquid Glass CNTabBar ───────────────────────────────────────────────

class _LiquidGlassBar extends StatelessWidget {
  const _LiquidGlassBar({
    required this.currentIndex,
    required this.onTap,
    required this.isAr,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      // CNTabBar is always LTR internally — we flip labels manually
      textDirection: TextDirection.ltr,
      child: CNTabBar(
        currentIndex: currentIndex,
        tint: cs.primary,

        height: 85,
        onTap: onTap,
        items: kNavItems
            .map(
              (item) => CNTabBarItem(
                label: isAr ? item.labelAr : item.labelEn,
                icon: CNSymbol(item.sfSymbol),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Android — existing Material floating bar (unchanged) ─────────────────────

class _MaterialBar extends StatelessWidget {
  const _MaterialBar({
    required this.currentIndex,
    required this.onTap,
    required this.isAr,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final langCode = isAr ? 'ar' : 'en';

    final activeColor = scheme.primary;
    final inactiveColor = scheme.outline.withValues(alpha: 0.45);
    final bgColor = scheme.surface.withValues(alpha: 0.20);
    final pillColor = scheme.primary.withValues(alpha: 0.15);

    const barHeight = 62.0;
    const pillGap = 8.5;
    const pillHeight = barHeight - pillGap;
    const pillVerticalOffset = pillGap / 2;
    const double paddingBottom = 25;
    const double paddingTop = 10;
    const double paddingHorizontal = 16;

    return Padding(
      padding: const EdgeInsets.only(
        left: paddingHorizontal,
        right: paddingHorizontal,
        top: paddingTop,
        bottom: paddingBottom,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth - 2;
          final itemWidth = totalWidth / kNavItems.length;
          final pillWidth = itemWidth - 6;
          final pillOffset =
              currentIndex * itemWidth + (itemWidth - pillWidth) / 2;

          return ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: totalWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.10),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: totalWidth,
                  height: barHeight,
                  child: Stack(
                    children: [
                      // Sliding pill
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        left: isAr ? null : pillOffset,
                        right: isAr ? pillOffset : null,
                        top: pillVerticalOffset,
                        width: pillWidth,
                        height: pillHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: pillColor,
                            borderRadius: BorderRadius.circular(48),
                          ),
                        ),
                      ),

                      // Tab items
                      Positioned.fill(
                        child: Row(
                          children: List.generate(kNavItems.length, (i) {
                            final item = kNavItems[i];
                            final isActive = i == currentIndex;
                            final label = isAr ? item.labelAr : item.labelEn;
                            final fontFamily = AppTypography.getBodyFontFamily(
                              langCode,
                            );

                            return GestureDetector(
                              onTap: () => onTap(i),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: itemWidth,
                                height: barHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: isActive ? 1.15 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeOutBack,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Icon(
                                          isActive
                                              ? item.activeIcon
                                              : item.icon,
                                          key: ValueKey('icon_${i}_$isActive'),
                                          size: 22,
                                          color: isActive
                                              ? activeColor
                                              : inactiveColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: isAr ? 10.0 : 11.0,
                                        fontWeight: isActive
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isActive
                                            ? activeColor
                                            : inactiveColor,
                                        letterSpacing: isAr ? 0.0 : 0.1,
                                        height: 1.0,
                                      ),
                                      child: Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
