import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/full_width_feed_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SeeAllPage
//  صفحة "عرض الكل" — vertical infinite scroll بنفس تصميم FullWidthFeedCard
//  تُستخدم لـ Trending This Week و New Openings
// ─────────────────────────────────────────────────────────────────────────────
class SeeAllPage extends ConsumerWidget {
  const SeeAllPage({
    super.key,
    required this.type,
    required this.titleEn,
    required this.titleAr,
  });

  final SeeAllType type;
  final String titleEn;
  final String titleAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final feed = ref.watch(seeAllFeedProvider(type));
    final theme = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── App bar ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 22, 4),
                  child: Row(
                    children: [
                      CupertinoButton(
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          isAr
                              ? CupertinoIcons.chevron_right
                              : CupertinoIcons.chevron_left,
                          color: theme.onSurface,
                          size: 20,
                        ),
                      ),
                      Text(
                        isAr ? titleAr : titleEn,
                        style: tt.headlineSmall?.copyWith(
                          color: theme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Loading skeletons ──────────────────────────────────────────
              if (feed.isFirstLoad)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
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
                    childCount: 4,
                  ),
                )
              // ── Error ──────────────────────────────────────────────────────
              else if (feed.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 40,
                          color: theme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAr ? 'تعذّر التحميل' : 'Failed to load',
                          style: tt.bodyMedium?.copyWith(
                            color: theme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // ── Empty ──────────────────────────────────────────────────────
              else if (feed.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      isAr ? 'لا توجد نتائج' : 'Nothing here yet',
                      style: tt.bodyMedium?.copyWith(
                        color: theme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                )
              // ── Infinite list ──────────────────────────────────────────────
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == feed.items.length) {
                      if (feed.hasMore) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(seeAllFeedProvider(type).notifier)
                              .loadMore();
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
                            isAr
                                ? '— لقد وصلت للنهاية —'
                                : '— You\'ve reached the end —',
                            style: tt.labelSmall?.copyWith(
                              color: theme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      child: FullWidthFeedCard(item: feed.items[index]),
                    );
                  }, childCount: feed.items.length + 1),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
