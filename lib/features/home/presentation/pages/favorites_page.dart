import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_list_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FavoritesPage
//  Uses FeedListSection → same skeleton, card, error, empty as AllPlaces
//  and SeeAll. No custom shimmer here — zero duplication.
// ─────────────────────────────────────────────────────────────────────────────
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final feed = ref.watch(favoritesFeedProvider);
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
              // ── Title ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                  child: Text(
                    isAr ? 'المفضلة' : 'Favorites',
                    style: tt.headlineMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // ── Feed — skeleton/error/empty/list all handled by FeedListSection
              FeedListSection(
                feed: feed,
                // Favorites are not paginated — no onLoadMore
                emptyTitleEn: 'No favorites yet',
                emptyTitleAr: 'لا توجد مفضلات بعد',
                emptySubtitleEn: 'Tap the ♡ on any place to save it here',
                emptySubtitleAr: 'اضغط على ♡ في أي مكان لحفظه هنا',
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
