import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/new_opening_badge.dart';
import 'package:gap/gap.dart';
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

    // ── First load skeleton ────────────────────────────────────────────────
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

    // ── Error state ────────────────────────────────────────────────────────
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

    // ── Empty state ────────────────────────────────────────────────────────
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Feed list (infinite scroll) ────────────────────────────────────────
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: FullWidthFeedCard(
            item: feed.items[index],
            isAr: isAr,
            theme: theme.colorScheme,
            tt: tt,
          ),
        );
      }, childCount: feed.items.length + 1),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FullWidthFeedCard  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class FullWidthFeedCard extends StatelessWidget {
  const FullWidthFeedCard({
    super.key,
    required this.item,
    required this.isAr,
    required this.theme,
    required this.tt,
  });

  final CategoryFeedItem item;
  final bool isAr;
  final ColorScheme theme;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        /* TODO: Navigate to place detail */
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: item.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                Container(color: theme.outline),
                            errorWidget: (_, _, _) =>
                                Container(color: theme.outline),
                          )
                        : Container(color: theme.outline),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: const DecoratedBox(decoration: BoxDecoration()),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: isAr ? null : 12,
                  right: isAr ? 12 : null,
                  child: newOpeningBadge(isAr, context),
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
                      Text(
                        isAr ? item.titleAr : item.titleEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(color: theme.onSurface),
                      ),
                      Gap(10),
                      if (item.isVerified)
                        SizedBox(
                          height: 16,
                          child: Image.asset('assets/icons/verify.png'),
                        ),
                    ],
                  ),
                  if ((isAr ? item.subtitleAr : item.subtitleEn) != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          height: 10,
                          child: Image.asset('assets/icons/location.png'),
                        ),
                        Gap(4),
                        Text(
                          isAr ? item.subtitleAr! : item.subtitleEn!,
                          style: tt.bodySmall?.copyWith(color: theme.onSurface),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
      // ── Cover image: matches SizedBox(height:200), borderRadius:20 ──
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
          // ── Badge pill: matches "Just Opened" chip ───────────────────
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
      // ── Text block: matches padding fromLTRB(16, 14, 16, 16) ─────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row: titleMedium ~h16 + verify icon 16×16
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
            const SizedBox(height: 4),
            // Subtitle row: location icon 12×12 + bodySmall text ~h12
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
                const SizedBox(width: 3),
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
