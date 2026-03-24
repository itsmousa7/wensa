import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/favorites/presentation/widgets/feed_list_section.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(favoritesFeedProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final feed = ref.watch(favoritesFeedProvider);
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
              // ── Pull to refresh ─────────────────────────────────────────
              CupertinoSliverRefreshControl(
                refreshTriggerPullDistance: 80,
                refreshIndicatorExtent: 50,
                onRefresh: _onRefresh,
                builder: (context, mode, pulledExtent, triggerDistance, _) {
                  final progress = (pulledExtent / triggerDistance).clamp(
                    0.0,
                    1.0,
                  );
                  final loading =
                      mode == RefreshIndicatorMode.refresh ||
                      mode == RefreshIndicatorMode.armed;
                  return Center(
                    child: loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primary,
                            ),
                          )
                        : Opacity(
                            opacity: progress,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 24,
                              color: theme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                  );
                },
              ),

              // ── Title ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                  child: Text(
                    isAr ? 'المفضلة' : 'Favorites',
                    style: tt.headlineMedium?.copyWith(
                      color: theme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // ── Feed ─────────────────────────────────────────────────────
              FeedListSection(
                feed: feed,
                emptyTitleEn: 'No favorites yet',
                emptyTitleAr: 'لا توجد مفضلات بعد',
                emptySubtitleEn: 'Double tap on any place to save it here',
                emptySubtitleAr: 'اضغط مرتين في أي مكان لحفظه هنا',
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}