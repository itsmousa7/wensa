import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CategoryFeedSection
//
//  ✅ BUG 2 FIX: دائماً يرجع Sliver — حتى في الـ loading/empty/error states
//               لأن CustomScrollView يحتاج Slivers فقط
// ─────────────────────────────────────────────────────────────────────────────
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
    final theme = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    // ── First load skeleton ────────────────────────────────────────────────
    if (feed.isFirstLoad) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Skeletonizer(
              enabled: true,
              effect: ShimmerEffect(
                baseColor: theme.surfaceContainer,
                highlightColor: theme.surfaceContainerHighest,
              ),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: theme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
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
                color: theme.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'تعذّر تحميل البيانات' : 'Failed to load',
                style: tt.bodyMedium?.copyWith(
                  color: theme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── ✅ BUG 2 FIX: Empty state — يظهر رسالة واضحة ─────────────────────
    if (feed.isEmpty) {
      final catName = isAr ? categoryNameAr : categoryNameEn;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 22),
          child: Column(
            children: [
              Text('🔍', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? 'لا توجد أماكن في فئة "$catName" حالياً'
                    : 'No places found in "$catName" yet',
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(
                  color: theme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'تحقق لاحقاً!' : 'Check back later!',
                style: tt.bodySmall?.copyWith(
                  color: theme.onSurface.withValues(alpha: 0.3),
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
        // آخر slot = load more indicator أو end caption
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
                    color: theme.primary,
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
                  color: theme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: _FullWidthFeedCard(
            item: feed.items[index],
            isAr: isAr,
            theme: theme,
            tt: tt,
          ),
        );
      }, childCount: feed.items.length + 1),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _FullWidthFeedCard
//  ✅ BUG 4: حذف الـ Explore button — الكارد كاملاً قابل للنقر
//  ✅ BUG 5: ألوان من theme + AppTypography
// ─────────────────────────────────────────────────────────────────────────────
class _FullWidthFeedCard extends StatelessWidget {
  const _FullWidthFeedCard({
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
        decoration: BoxDecoration(
          // ✅ BUG 5: theme colors
          color: theme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image + overlays ────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: item.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: theme.surfaceContainerHighest),
                            errorWidget: (_, __, ___) =>
                                Container(color: theme.surfaceContainerHighest),
                          )
                        : Container(color: theme.surfaceContainerHighest),
                  ),
                ),

                // Gradient overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Verified badge — top end
                if (item.isVerified)
                  Positioned(
                    top: 12,
                    right: isAr ? null : 12,
                    left: isAr ? 12 : null,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '✓',
                          style: tt.labelMedium?.copyWith(
                            color: theme.tertiary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                // "Just Opened" badge — top start
                Positioned(
                  top: 12,
                  left: isAr ? null : 12,
                  right: isAr ? 12 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // ✅ BUG 5: theme.tertiary للـ "New" badge
                      color: theme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAr ? '✦ افتتح مؤخراً' : '✦ Just Opened',
                      style: tt.labelSmall?.copyWith(
                        color: theme.onTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Text area — NO explore button ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    isAr ? item.titleAr : item.titleEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(color: theme.onSurface),
                  ),

                  // Subtitle (area)
                  if ((isAr ? item.subtitleAr : item.subtitleEn) != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: theme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isAr ? item.subtitleAr! : item.subtitleEn!,
                          style: tt.bodySmall?.copyWith(
                            color: theme.onSurface.withValues(alpha: 0.5),
                          ),
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
