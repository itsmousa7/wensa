import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/full_width_feed_card.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CategoryFeedSection extends ConsumerWidget {
  const CategoryFeedSection({
    super.key,
    required this.categoryId,
    required this.categoryNameEn,
    required this.categoryNameAr,
  });

  final String categoryId;
  final String categoryNameEn;
  final String categoryNameAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(categoryFeedProvider(categoryId));
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context);
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    // ── Skeleton ───────────────────────────────────────────────────────────
    if (feed.isFirstLoad) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: buildFullWidthSkeleton(context),
          ),
          childCount: 3,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'تعذّر تحميل البيانات' : 'Failed to load',
                style: tt.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ──────────────────────────────────────────────────────────────
    if (feed.isEmpty) {
      final catName = isAr ? categoryNameAr : categoryNameEn;
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
                isAr
                    ? 'لا توجد أماكن في فئة "$catName" حالياً'
                    : 'No places found in "$catName" yet',
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'تحقق لاحقاً!' : 'Check back later!',
                style: tt.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
        if (index == feed.items.length) {
          if (feed.hasMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(categoryFeedProvider(categoryId).notifier).loadMore();
            });
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          // ✅ Uses shared FullWidthFeedCard with heart + favorites
          child: FullWidthFeedCard(item: feed.items[index]),
        );
      }, childCount: feed.items.length + 1),
    );
  }
}

Widget _buildSkeleton(ThemeData theme) => Skeletonizer(
  enabled: true,
  effect: ShimmerEffect(
    baseColor: theme.colorScheme.surfaceContainer,
    highlightColor: theme.colorScheme.surfaceContainerHighest,
    duration: const Duration(milliseconds: 1200),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 200,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 90,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 16,
                  width: 160,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
);
