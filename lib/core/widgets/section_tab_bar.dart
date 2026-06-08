// lib/core/widgets/section_tab_bar.dart

import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';

/// Platform-aware horizontal section bar shared across pages (Bookings,
/// Favorites, …).
///
/// * iOS — a horizontally-scrollable [CNSegmentedControl] that reserves
///   [minSegmentWidth] per segment. When the content is narrower than the
///   available width the bar fills the width (no scroll); otherwise it scrolls.
/// * Android — underline-style tabs that track the active index.
///
/// Pass the already-localized [tabs], the page's [controller] and the
/// [selectedIndex] driven by the controller's animation value (so the iOS
/// indicator flips at the swipe's midpoint instead of lagging behind).
class SectionTabBar extends StatelessWidget implements PreferredSizeWidget {
  const SectionTabBar({
    super.key,
    required this.tabs,
    required this.controller,
    required this.selectedIndex,
    this.minSegmentWidth = 104.0,
    this.horizontalPadding = 16.0,
  });

  /// Localized labels, one per [controller] index.
  final List<String> tabs;

  /// Drives selection; tapping/swiping a segment animates this controller.
  final TabController controller;

  /// Segment shown as selected by the native control. Usually driven by the
  /// controller's animation value rather than its settled index.
  final int selectedIndex;

  /// Width reserved per segment on iOS so labels never squeeze.
  final double minSegmentWidth;

  /// Leading/trailing inset for the iOS segmented control.
  final double horizontalPadding;

  static const double _iosHeight = 56;
  static const double _androidHeight = 48;

  @override
  Size get preferredSize =>
      Size.fromHeight(Platform.isIOS ? _iosHeight : _androidHeight);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return SizedBox(
        height: _iosHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth - horizontalPadding * 2;
            final contentWidth = tabs.length * minSegmentWidth;
            final barWidth = contentWidth < available
                ? available
                : contentWidth;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                12,
              ),
              child: SizedBox(
                width: barWidth,
                child: CNSegmentedControl(
                  height: 40,
                  labels: tabs,
                  selectedIndex: selectedIndex,
                  onValueChanged: (i) => controller.animateTo(i),
                ),
              ),
            );
          },
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    Widget tab(int i) {
      final selected = controller.index == i;
      return GestureDetector(
        onTap: () => controller.animateTo(i),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(
                    tabs[i],
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.40),
                    ),
                  ),
                ),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 1),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _androidHeight,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth - 4; // horizontal: 2 inset
            final fits = tabs.length * minSegmentWidth < available;

            // When the tabs fit, spread them across the full width
            // (space-between); otherwise fall back to a scrollable row.
            if (fits) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(tabs.length, tab),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(children: List.generate(tabs.length, tab)),
            );
          },
        ),
      ),
    );
  }
}
