import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_list_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SeeAllPage
//  Uses FeedListSection so the skeleton, error, empty, and cards are
//  identical to AllPlacesSection and FavoritesSection — zero duplication.
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
    final cs = Theme.of(context).colorScheme;
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
              // ── App bar ──────────────────────────────────────────────────
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
                          color: cs.onSurface,
                          size: 20,
                        ),
                      ),
                      Text(
                        isAr ? titleAr : titleEn,
                        style: tt.headlineSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Feed — skeleton / error / empty / list all handled inside ─
              FeedListSection(
                feed: feed,
                onLoadMore: () =>
                    ref.read(seeAllFeedProvider(type).notifier).loadMore(),
                emptyTitleEn: type == SeeAllType.trending
                    ? 'Nothing trending right now'
                    : 'No new openings yet',
                emptyTitleAr: type == SeeAllType.trending
                    ? 'لا يوجد شيء رائج الآن'
                    : 'لا توجد افتتاحات جديدة',
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
