import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/full_width_feed_card.dart';
import 'package:lottie/lottie.dart';

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
    final cs = Theme.of(context).colorScheme;
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
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/animation/no_internet.json',
                height: 300,
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'حدث خطأ!' : 'Something went wrong!',
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
      final catName = isAr ? categoryNameAr : categoryNameEn;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'تحقق لاحقاً!' : 'Check back later!',
                textAlign: TextAlign.center,
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: FullWidthFeedCard(item: feed.items[index]),
        );
      }, childCount: feed.items.length + 1),
    );
  }
}
