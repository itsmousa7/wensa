import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/widgets/app_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/category_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/home_search_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/hot_event_section.dart';
import 'package:future_riverpod/features/home/presentation/widgets/nav_shell.dart';
import 'package:future_riverpod/features/home/presentation/widgets/new_opening.dart';
import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';
import 'package:future_riverpod/features/home/presentation/widgets/trending_feed.dart';

// ── Color Tokens ──────────────────────────────────────────────────────────────
const kBg = Color(0xFF0B0B12);
const kSurface = Color(0xFF14141F);
const kSurface2 = Color(0xFF1E1E2E);
const kBorder = Color(0xFF2A2A3E);
const kOrange = Color(0xFFFF5E2C);
const kOrange2 = Color(0xFFFF8A5C);
const kGold = Color(0xFFF5C518);
const kTeal = Color(0xFF00D4AA);
const kText = Color(0xFFFFFFFF);
const kText2 = Color(0xFFA0A0B8);
const kText3 = Color(0xFF5A5A72);
const kNewGreen = Color(0xFF22C55E);
const kEventBlue = Color(0xFF4C6EF5);

const _kInfiniteOffset = 10000;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageCtrl;
  Timer? _autoScrollTimer;

  // Track whether a refresh is in progress
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(
      viewportFraction: 0.88,
      initialPage: _kInfiniteOffset,
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageCtrl.hasClients) return;
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get isAr => ref.watch(appLocaleProvider) is ArabicLocale;

  // ── Pull-to-refresh ────────────────────────────────────────────────────────
  // Replace the body of this method with your real data-refresh calls.
  // e.g.: ref.invalidate(hotEventsProvider); ref.invalidate(trendingProvider);
  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      // ↓ Invalidate your Riverpod providers here so they re-fetch:
      // ref.invalidate(hotEventsProvider);
      // ref.invalidate(trendingFeedProvider);
      // ref.invalidate(newOpeningsProvider);
      // ref.invalidate(promotedBannerProvider);

      // Minimum visual delay so the spinner doesn't flash
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // ── Localized strings ──────────────────────────────────────────────────────
  String get _hotEventsLabel => isAr ? '🔥 الأحداث الساخنة' : '🔥 Hot Events';
  String get _categoryLabel => isAr ? 'تصفح حسب الفئة' : 'Browse by Category';
  String get _trendingLabel =>
      isAr ? 'الأكثر رواجاً هذا الأسبوع' : 'Trending This Week';
  String get _newOpeningsLabel => isAr ? 'افتتاحات جديدة' : 'New Openings';
  String get _seeAll => isAr ? 'عرض الكل ›' : 'See all ›';

  @override
  Widget build(BuildContext context) {
    ref.watch(appLocaleProvider);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // The scroll controller is shared with NavShell so that re-tapping
    // the Home tab scrolls back to the top.
    final scrollController = ref.read(homeScrollControllerProvider);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            // Called when the user swipes down past the top edge
            onRefresh: _onRefresh,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            displacement: 60,
            child: CustomScrollView(
              // ← Wire the shared controller so NavShell can scroll us to top
              controller: scrollController,
              // physics must allow over-scroll for RefreshIndicator to trigger
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: HomeAppBar()),
                SliverToBoxAdapter(child: HomeSearchBar()),
                SliverToBoxAdapter(child: PromotedBanner()),
                SliverToBoxAdapter(
                  child: _sectionTitle(_hotEventsLabel, more: true),
                ),
                SliverToBoxAdapter(child: HotEventsSection()),
                SliverToBoxAdapter(child: _sectionTitle(_categoryLabel)),
                SliverToBoxAdapter(child: CategoryBar(isAr: isAr)),
                SliverToBoxAdapter(
                  child: _sectionTitle(_trendingLabel, more: true),
                ),
                SliverToBoxAdapter(child: TrendingFeed()),
                SliverToBoxAdapter(
                  child: _sectionTitle(_newOpeningsLabel, more: true),
                ),
                SliverToBoxAdapter(child: NewOpening()),
                // Extra space so last items aren't hidden behind the nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, {bool more = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
    child: Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (more)
          Text(
            _seeAll,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    ),
  );
}

                      