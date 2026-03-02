import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelEn;
  final String labelAr;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelEn,
    required this.labelAr,
  });
}

const kNavItems = [
  NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    labelEn: 'Home',
    labelAr: 'الرئيسية',
  ),
  NavItem(
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore_rounded,
    labelEn: 'Explore',
    labelAr: 'استكشف',
  ),
  NavItem(
    icon: Icons.map_outlined,
    activeIcon: Icons.map_rounded,
    labelEn: 'Map',
    labelAr: 'الخريطة',
  ),
  NavItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    labelEn: 'Profile',
    labelAr: 'حسابي',
  ),
];

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
    final scheme = Theme.of(context).colorScheme;
    final langCode = isAr ? 'ar' : 'en';

    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurface.withValues(alpha: 0.45);
    final bgColor = scheme.surface.withValues(alpha: 0.55);
    final pillColor = scheme.primary.withValues(alpha: 0.15);

    // ════════════════════════════════════════════════════
    // 📐 HEIGHT CONTROLS — adjust these to resize the bar
    // ════════════════════════════════════════════════════

    // ① The bar capsule height in pixels
    const barHeight = 62.0;

    // ② Pill height = barHeight minus this gap (top + bottom combined).
    //    Smaller number → pill fills more of the bar height.
    const pillGap = 8.5;
    const pillHeight = barHeight - pillGap;

    // ③ How far the pill sits from the top edge of the bar
    const pillVerticalOffset = pillGap / 2; // keeps it centred

    // ④ Outer spacing around the bar capsule.
    //    • bottom → how high the bar floats above the screen edge.
    //      Increase to push it further up. Currently 30 (was 10, +20 as requested).
    //    • top    → gap between bar and the page content above it.
    //    • horizontal → left/right margin from screen edges.
    const double paddingBottom = 25; // ← ✏️ raise / lower the bar here
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

          // Pill width = slot width minus side gap
          final pillWidth = itemWidth - 6;
          final pillOffset =
              currentIndex * itemWidth + (itemWidth - pillWidth) / 2;

          return ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: totalWidth,
                height: barHeight, // ← controlled by ① above
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.10),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: totalWidth,
                  height: barHeight,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // ── Sliding pill indicator ───────────────────────────
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

                      // ── Tab items ────────────────────────────────────────
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
                                            ? FontWeight.w700
                                            : FontWeight.w400,
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
