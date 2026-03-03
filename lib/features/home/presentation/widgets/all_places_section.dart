import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/category_feed_section.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AllPlacesSection
//  يعرض كل الأماكن بدون فلتر — يظهر فقط لما لا يوجد category مختار
//  يستخدم نفس _FullWidthFeedCard من CategoryFeedSection
// ─────────────────────────────────────────────────────────────────────────────
class AllPlacesSection extends ConsumerWidget {
  const AllPlacesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(allPlacesFeedProvider);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    // ── Skeleton (first load) ──────────────────────────────────────────────
    if (feed.isFirstLoad) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: _buildSkeleton(theme),
          ),
          childCount: 3,
        ),
      );
    }

    // ── Error ──────────────────────────────────────────────────────────────
    if (feed.hasError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 22),
          child: Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: cs.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 10),
              Text(
                isAr ? 'تعذّر التحميل' : 'Failed to load',
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
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 22),
          child: Center(
            child: Text(
              isAr ? 'لا توجد أماكن حالياً' : 'No places yet',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
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
              ref.read(allPlacesFeedProvider.notifier).loadMore();
            });
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

        // ✅ نستخدم نفس _FullWidthFeedCard من category_feed_section
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: FullWidthFeedCard(
            item: feed.items[index],
            isAr: isAr,
            theme: cs,
            tt: tt,
          ),
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
            Container(
              height: 16,
              width: 160,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
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
      ),
    ],
  ),
);
