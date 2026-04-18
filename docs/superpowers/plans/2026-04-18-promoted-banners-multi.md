# Promoted Banners — Multi-Banner Carousel & Multi-Placement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-banner display with an auto-scrolling carousel at the top of the home page, and add non-intrusive inline banner slots in the home feed and the favorites page.

**Architecture:** The existing `promotedBannersProvider` already fetches all banners from Supabase — no backend or model changes are needed. The `PromotedBanner` widget is updated to a `PageView` carousel. A new `PromotedBannerInline` widget is added in the same file to render a single banner at a given slot index (`banners[slotIndex % banners.length]`), enabling placement between feed sections without repeating the same ad everywhere.

**Tech Stack:** Flutter, Riverpod (`promotedBannersProvider`), `cached_network_image`, `skeletonizer`, `go_router`, Dart `Timer` for auto-scroll.

---

## File Map

| Action | File |
|--------|------|
| Modify | `lib/features/home/presentation/widgets/promoted_banner.dart` |
| Modify | `lib/features/home/presentation/pages/home_page.dart` |
| Modify | `lib/features/favorites/presentation/pages/favorites_page.dart` |

---

## Task 1: Update `PromotedBanner` to an Auto-Scrolling Carousel

**Files:**
- Modify: `lib/features/home/presentation/widgets/promoted_banner.dart`

This task converts the top banner from `banners.first` into a `PageView` that cycles through all banners automatically. It adds a dots indicator below the image strip. The widget becomes a `ConsumerStatefulWidget` so it can own a `PageController` and a `Timer`.

- [ ] **Step 1: Read the current file**

  Read `lib/features/home/presentation/widgets/promoted_banner.dart` to confirm the current content before editing.

- [ ] **Step 2: Replace the widget with the carousel implementation**

  Replace the entire content of `lib/features/home/presentation/widgets/promoted_banner.dart` with:

  ```dart
  import 'dart:async';

  import 'package:cached_network_image/cached_network_image.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
  import 'package:future_riverpod/core/constants/locale/locale_state.dart';
  import 'package:future_riverpod/core/constants/theme/app_colors.dart';
  import 'package:future_riverpod/core/router/router_names.dart';
  import 'package:future_riverpod/features/home/models/promoted_banner.dart';
  import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
  import 'package:go_router/go_router.dart';
  import 'package:skeletonizer/skeletonizer.dart';

  // ── Top carousel ──────────────────────────────────────────────────────────────

  class PromotedBanner extends ConsumerStatefulWidget {
    const PromotedBanner({super.key});

    @override
    ConsumerState<PromotedBanner> createState() => _PromotedBannerState();
  }

  class _PromotedBannerState extends ConsumerState<PromotedBanner> {
    late final PageController _ctrl;
    Timer? _timer;
    int _current = 0;

    @override
    void initState() {
      super.initState();
      _ctrl = PageController();
    }

    void _startTimer(int count) {
      _timer?.cancel();
      if (count < 2) return; // no need to auto-scroll a single banner
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_current + 1) % count;
        _ctrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }

    @override
    void dispose() {
      _timer?.cancel();
      _ctrl.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final bannersAsync = ref.watch(promotedBannersProvider);
      final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
      final theme = Theme.of(context);

      return bannersAsync.when(
        skipLoadingOnRefresh: false,
        loading: () => _buildSkeleton(theme),
        error: (_, _) => const SizedBox.shrink(),
        data: (banners) {
          if (banners.isEmpty) return const SizedBox.shrink();

          // Start timer once data is available
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _startTimer(banners.length),
          );

          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 82,
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: banners.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (context, index) =>
                        _BannerCard(banner: banners[index], isAr: isAr),
                  ),
                ),
                if (banners.length > 1) ...[
                  const SizedBox(height: 6),
                  _DotsIndicator(count: banners.length, current: _current),
                ],
              ],
            ),
          );
        },
      );
    }
  }

  // ── Inline single-banner slot ────────────────────────────────────────────────

  /// Displays one banner chosen by [slotIndex] (wraps around if fewer banners
  /// than slots). Drop this anywhere you want a non-intrusive ad placement.
  class PromotedBannerInline extends ConsumerWidget {
    const PromotedBannerInline({super.key, required this.slotIndex});

    final int slotIndex;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final bannersAsync = ref.watch(promotedBannersProvider);
      final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
      final theme = Theme.of(context);

      return bannersAsync.when(
        skipLoadingOnRefresh: true, // inline slots don't show skeleton on refresh
        loading: () => _buildSkeleton(theme),
        error: (_, _) => const SizedBox.shrink(),
        data: (banners) {
          if (banners.isEmpty) return const SizedBox.shrink();
          final banner = banners[slotIndex % banners.length];
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: _BannerCard(banner: banner, isAr: isAr),
          );
        },
      );
    }
  }

  // ── Shared card widget ───────────────────────────────────────────────────────

  class _BannerCard extends StatelessWidget {
    const _BannerCard({required this.banner, required this.isAr});

    final PromotedBannerModel banner;
    final bool isAr;

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);

      return GestureDetector(
        onTap: banner.placeId != null
            ? () => context.pushNamed(
                RouteNames.placeDetails,
                queryParameters: {'placeId': banner.placeId!},
              )
            : banner.eventId != null
                ? () => context.pushNamed(
                    RouteNames.eventDetails,
                    queryParameters: {'eventId': banner.eventId!},
                  )
                : null,
        child: SizedBox(
          height: 82,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: theme.colorScheme.primary),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.success),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.black.withValues(alpha: 0.7),
                          AppColors.black.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 30)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.displayNameFor(isAr ? 'ar' : 'en'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (banner.displayLocation != null)
                              Text(
                                banner.displayLocation!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      AppColors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ── Dots indicator ───────────────────────────────────────────────────────────

  class _DotsIndicator extends StatelessWidget {
    const _DotsIndicator({required this.count, required this.current});

    final int count;
    final int current;

    @override
    Widget build(BuildContext context) {
      final primary = Theme.of(context).colorScheme.primary;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? primary
                  : primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      );
    }
  }

  // ── Skeleton ─────────────────────────────────────────────────────────────────

  Widget _buildSkeleton(ThemeData theme) => Skeletonizer(
    enabled: true,
    effect: ShimmerEffect(
      baseColor: theme.colorScheme.surfaceContainer,
      highlightColor: theme.colorScheme.surfaceContainerHighest,
      duration: const Duration(milliseconds: 1200),
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: Bone(
        height: 82,
        width: double.infinity,
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
  ```

- [ ] **Step 3: Hot-restart the app and verify**

  Run the app and confirm:
  - The top banner on the home page now cycles through all banners automatically every 4 seconds
  - Dots appear below the carousel when there is more than 1 banner
  - Single-banner case: no dots, no auto-scroll (timer skipped)
  - Tapping a banner navigates correctly (place or event)

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/home/presentation/widgets/promoted_banner.dart
  git commit -m "feat: promoted banner carousel with dots and auto-scroll"
  ```

---

## Task 2: Add Inline Banner Between Feed Sections in Home Page

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`

Place a `PromotedBannerInline(slotIndex: 1)` between the **Featured** section and the **New Openings** section. This gives advertisers a mid-feed placement that users see naturally as they scroll, without interrupting the top of the screen.

- [ ] **Step 1: Add the import for `PromotedBannerInline`**

  `promoted_banner.dart` is already imported in `home_page.dart` as:
  ```dart
  import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';
  ```
  No new import needed — `PromotedBannerInline` is exported from the same file.

- [ ] **Step 2: Insert the inline banner after the Featured section**

  In `lib/features/home/presentation/pages/home_page.dart`, locate the block that adds `FeaturedSection`. It looks like:

  ```dart
  SliverToBoxAdapter(
    child: FeaturedSection(
      onViewAll: () => _goToSeeAll(SeeAllType.featured),
    ),
  ),
  ```

  Add `PromotedBannerInline(slotIndex: 1)` immediately after it:

  ```dart
  SliverToBoxAdapter(
    child: FeaturedSection(
      onViewAll: () => _goToSeeAll(SeeAllType.featured),
    ),
  ),

  // ── Mid-feed ad slot ─────────────────────────────────────────────────
  const SliverToBoxAdapter(
    child: PromotedBannerInline(slotIndex: 1),
  ),
  ```

- [ ] **Step 3: Hot-reload and verify**

  Scroll past the Featured section on the home page and confirm:
  - The inline banner appears between Featured and New Openings
  - It shows the second banner in the list (or wraps to the first if only one banner exists)
  - It does NOT show a loading skeleton on pull-to-refresh (because `skipLoadingOnRefresh: true`)

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/home/presentation/pages/home_page.dart
  git commit -m "feat: add mid-feed promoted banner slot between featured and new openings"
  ```

---

## Task 3: Add Banner to the Favorites Page

**Files:**
- Modify: `lib/features/favorites/presentation/pages/favorites_page.dart`

Place a `PromotedBannerInline(slotIndex: 2)` after the page title and before the feed list. Users browsing their favorites are engaged and likely to notice an ad, while the placement at the very top (below the heading) is non-intrusive.

- [ ] **Step 1: Add the import**

  In `lib/features/favorites/presentation/pages/favorites_page.dart`, add:

  ```dart
  import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';
  ```

  Place it with the other feature imports.

- [ ] **Step 2: Insert the banner after the page title sliver**

  Locate the title `SliverToBoxAdapter` in the `slivers` list:

  ```dart
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
      child: Text(
        isAr ? 'المفضلة' : 'Favorites',
        ...
      ),
    ),
  ),
  ```

  Add the banner immediately after it:

  ```dart
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
      child: Text(
        isAr ? 'المفضلة' : 'Favorites',
        style: tt.headlineMedium?.copyWith(
          color: theme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  ),

  // ── Ad slot ─────────────────────────────────────────────────────────
  const SliverToBoxAdapter(
    child: PromotedBannerInline(slotIndex: 2),
  ),
  ```

- [ ] **Step 3: Hot-reload and verify**

  Open the Favorites tab and confirm:
  - The banner appears below the "Favorites" / "المفضلة" title
  - It shows a different banner from the one at the top of the home page (slot index 2 vs 0/1), wrapping correctly if fewer banners exist
  - The banner does not appear when `promotedBannersProvider` returns an empty list

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/favorites/presentation/pages/favorites_page.dart
  git commit -m "feat: add promoted banner slot to favorites page"
  ```

---

## Self-Review

### Spec coverage

| Requirement | Covered by |
|-------------|-----------|
| Show more than one banner (not just the first) | Task 1 — `PageView` carousel iterates `banners` list |
| Banners appear in more than one location | Task 2 (home mid-feed) + Task 3 (favorites) |
| Non-annoying / viewable | Auto-scroll only (no modal, no overlay), inline slots fit naturally in the scroll flow, `skipLoadingOnRefresh: true` on inline slots avoids flicker |

### Placeholder scan

No TBDs, no "handle edge cases" language, no missing code blocks. All steps contain exact code.

### Type consistency

- `PromotedBannerInline` is defined in Task 1 and used in Tasks 2 & 3 with the same constructor signature `PromotedBannerInline(slotIndex: int)`.
- `_BannerCard`, `_DotsIndicator`, `_buildSkeleton` are all defined in Task 1 and not referenced again externally.
- `banner.displayNameFor(...)` and `banner.displayLocation` come from the `PromotedBannerX` extension in `lib/features/home/models/promoted_banner.dart`, which is already imported inside `promoted_banner.dart`.
