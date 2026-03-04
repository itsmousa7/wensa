import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/category_feed_section.dart';
import 'package:future_riverpod/features/home/presentation/widgets/full_width_feed_card.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final feed = ref.watch(favoritesFeedProvider);
    final theme = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Title ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 4),
                  child: Text(
                    isAr ? 'المفضلة' : 'Favorites',
                    style: tt.headlineMedium?.copyWith(
                      color: theme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // ── Loading ───────────────────────────────────────────────────
              if (feed.isFirstLoad)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 8),
                      child: Skeletonizer(
                        enabled: true,
                        effect: ShimmerEffect(
                          baseColor: theme.surfaceContainer,
                          highlightColor: theme.surfaceContainerHighest,
                        ),
                        child: Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: theme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    childCount: 3,
                  ),
                )

              // ── Error ────────────────────────────────────────────────────
              else if (feed.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 44,
                          color: theme.onSurface.withValues(alpha: 0.25)),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? 'تعذّر التحميل' : 'Failed to load',
                        style: tt.bodyMedium?.copyWith(
                            color: theme.onSurface.withValues(alpha: 0.4)),
                      ),
                    ]),
                  ),
                )

              // ── Empty ────────────────────────────────────────────────────
              else if (feed.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        height: 180,
                        child: Lottie.asset(
                          'assets/lottie/animation/empty.json',
                          repeat: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'لا توجد أماكن مفضّلة بعد' : 'No favorites yet',
                        style: tt.bodyLarge?.copyWith(
                          color: theme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'اضغط على القلب أو انقر مرتين على أي مكان'
                            : 'Tap the heart or double-tap any place to save',
                        textAlign: TextAlign.center,
                        style: tt.bodySmall?.copyWith(
                          color: theme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ]),
                  ),
                )

              // ── Favorites list ────────────────────────────────────────────
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == feed.items.length) {
                        return const SizedBox(height: 100);
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 8),
                        child: FullWidthFeedCard(item: feed.items[index]),
                      );
                    },
                    childCount: feed.items.length + 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}