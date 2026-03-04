import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/full_width_feed_card.dart';

class AllPlacesSection extends ConsumerWidget {
  const AllPlacesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(allPlacesFeedProvider);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final cs = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: FullWidthFeedCard(item: feed.items[index]),
        );
      }, childCount: feed.items.length + 1),
    );
  }
}
