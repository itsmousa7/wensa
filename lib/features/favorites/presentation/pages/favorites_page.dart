import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/favorites/presentation/providers/favorites_scroll_signal.dart';
import 'package:future_riverpod/features/favorites/presentation/widgets/feed_list_section.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final List<ScrollController> _scrollCtrls;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _scrollCtrls = List.generate(3, (_) => ScrollController());
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in _scrollCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _scrollActiveTabToTop() {
    final ctrl = _scrollCtrls[_tab.index];
    if (ctrl.hasClients) {
      ctrl.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

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
    ref.listen(favoritesScrollToTopProvider, (_, _) => _scrollActiveTabToTop());

    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final feed = ref.watch(favoritesFeedProvider);
    final theme = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    final places = feed.items.where((i) => i.type == 'place').toList();
    final events = feed.items.where((i) => i.type == 'event').toList();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Title ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    isAr ? 'المفضلة' : 'Favorites',
                    style: tt.headlineMedium?.copyWith(
                      color: theme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // ── Tabs (custom, no ripple) ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _tabLabel(isAr ? 'الكل' : 'All', 0, tt, theme),
                    _tabLabel(isAr ? 'الأماكن' : 'Places', 1, tt, theme),
                    _tabLabel(isAr ? 'الفعاليات' : 'Events', 2, tt, theme),
                  ],
                ),
              ),

              // ── Swipeable pages ──────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildList(feed, feed.items, isAr, theme, _scrollCtrls[0]),
                    _buildList(
                      feed,
                      places,
                      isAr,
                      theme,
                      _scrollCtrls[1],
                      emptyTitleEn: 'No favorited places yet',
                      emptyTitleAr: 'لا توجد أماكن مفضلة بعد',
                      emptySubtitleEn:
                          'Double tap on any place to save it here',
                      emptySubtitleAr: 'اضغط مرتين على أي مكان لحفظه هنا',
                    ),
                    _buildList(
                      feed,
                      events,
                      isAr,
                      theme,
                      _scrollCtrls[2],
                      emptyTitleEn: 'No favorited events yet',
                      emptyTitleAr: 'لا توجد فعاليات مفضلة بعد',
                      emptySubtitleEn: 'Save an event to find it here',
                      emptySubtitleAr: 'احفظ فعالية لتجدها هنا',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    CategoryFeedState feed,
    List<CategoryFeedItem> items,
    bool isAr,
    ColorScheme theme,
    ScrollController scrollController, {
    String emptyTitleEn = 'No favorites yet',
    String emptyTitleAr = 'لا توجد مفضلات بعد',
    String emptySubtitleEn = 'Double tap on any place to save it here',
    String emptySubtitleAr = 'اضغط مرتين في أي مكان لحفظه هنا',
  }) {
    // Mirror the parent feed's loading / error state for this tab, but
    // narrow the item list to the tab's slice.
    final tabFeed = feed.isFirstLoad || feed.hasError
        ? feed
        : CategoryFeedState(items: items, isLoading: false, hasMore: false);

    return CustomScrollView(
      key: PageStorageKey(emptyTitleEn),
      controller: scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 80,
          refreshIndicatorExtent: 50,
          onRefresh: _onRefresh,
          builder: (context, mode, pulledExtent, triggerDistance, _) {
            final progress = (pulledExtent / triggerDistance).clamp(0.0, 1.0);
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
        const SliverToBoxAdapter(child: PromotedBannerInline(slotIndex: 0)),
        FeedListSection(
          feed: tabFeed,
          onRetry: () => ref.invalidate(favoritesFeedProvider),
          emptyTitleEn: emptyTitleEn,
          emptyTitleAr: emptyTitleAr,
          emptySubtitleEn: emptySubtitleEn,
          emptySubtitleAr: emptySubtitleAr,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _tabLabel(String text, int index, TextTheme tt, ColorScheme theme) {
    final selected = _tab.index == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tab.animateTo(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: selected
                  ? theme.primary
                  : theme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 2,
            width: selected ? 22 : 0,
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
