import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/full_width_feed_card.dart';
import 'package:lottie/lottie.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FeedListSection
//
//  A single reusable sliver widget that renders a paginated CategoryFeedState.
//  Used by:
//    • AllPlacesSection   → pass feed + onLoadMore from allPlacesFeedProvider
//    • SeeAllSection      → pass feed + onLoadMore from seeAllFeedProvider
//    • FavoritesSection   → pass feed (no pagination, onLoadMore = null)
//
//  Usage example:
//
//    FeedListSection(
//      feed: ref.watch(allPlacesFeedProvider),
//      onLoadMore: () => ref.read(allPlacesFeedProvider.notifier).loadMore(),
//      emptyTitleEn: 'No places yet',
//      emptyTitleAr: 'لا توجد أماكن',
//    )
// ─────────────────────────────────────────────────────────────────────────────
class FeedListSection extends ConsumerWidget {
  const FeedListSection({
    super.key,
    required this.feed,
    this.onLoadMore,
    this.onTapItem,
    this.emptyTitleEn = 'Nothing here yet',
    this.emptyTitleAr = 'لا يوجد شيء هنا بعد',
    this.emptySubtitleEn = 'Check back later!',
    this.emptySubtitleAr = 'تحقق لاحقاً!',
    this.skeletonCount = 3,
  });

  /// The state from any CategoryFeed-based provider.
  final CategoryFeedState feed;

  /// Called when the list reaches the bottom and [feed.hasMore] is true.
  /// Pass null for non-paginated feeds (e.g. Favorites).
  final VoidCallback? onLoadMore;

  /// Optional tap callback forwarded to each card.
  final void Function(CategoryFeedItem item)? onTapItem;

  final String emptyTitleEn;
  final String emptyTitleAr;
  final String emptySubtitleEn;
  final String emptySubtitleAr;

  /// How many skeleton cards to show while loading the first page.
  final int skeletonCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    // ── Skeleton (first load) ──────────────────────────────────────────────
    if (feed.isFirstLoad) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: buildFullWidthSkeleton(context),
          ),
          childCount: skeletonCount,
        ),
      );
    }

    // ── Error ──────────────────────────────────────────────────────────────
    if (feed.hasError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 22),
          child: Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: cs.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'تعذّر تحميل البيانات' : 'Failed to load',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ──────────────────────────────────────────────────────────────
    if (feed.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Lottie.asset('assets/lottie/animation/empty.json'),
              ),
              Text(
                isAr ? emptyTitleAr : emptyTitleEn,
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? emptySubtitleAr : emptySubtitleEn,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Infinite list ──────────────────────────────────────────────────────
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        // Footer: loading spinner or end-of-list label
        if (index == feed.items.length) {
          if (feed.hasMore && onLoadMore != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore!());
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                isAr ? '— لقد وصلت للنهاية —' : '— You\'ve reached the end —',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        }

        // Card
        final item = feed.items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: FullWidthFeedCard(
            item: item,
            onTap: onTapItem != null ? () => onTapItem!(item) : null,
          ),
        );
      }, childCount: feed.items.length + 1),
    );
  }
}
