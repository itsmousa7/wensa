import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_scroll_controller.dart';
import 'package:future_riverpod/features/home/presentation/widgets/app_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/category_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/category_feed_section.dart';
import 'package:future_riverpod/features/home/presentation/widgets/home_search_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/hot_event_section.dart';
import 'package:future_riverpod/features/home/presentation/widgets/new_opening.dart';
import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';
import 'package:future_riverpod/features/home/presentation/widgets/trending_feed.dart';

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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isRefreshing = false;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ref.read(homeScrollControllerProvider);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(hotEventsProvider);
      ref.invalidate(trendingFeedProvider);
      ref.invalidate(newOpeningsProvider);
      ref.invalidate(promotedBannersProvider);
      ref.invalidate(categoriesProvider);
      // لو في فئة محددة نعيد تحميل بياناتها
      final selectedIdx = ref.read(selectedCategoryProvider);
      if (selectedIdx != null) {
        final cats = ref.read(categoriesProvider).value;
        if (cats != null && selectedIdx < cats.length) {
          ref.invalidate(categoryFeedProvider(cats[selectedIdx].id));
        }
      }
      await Future.delayed(const Duration(milliseconds: 1200));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  bool get isAr => ref.watch(appLocaleProvider) is ArabicLocale;

  String get _hotEventsLabel => isAr ? 'الأحداث الساخنة' : 'Hot Events';
  String get _categoryLabel => isAr ? 'تصفح حسب الفئة' : 'Browse by Category';
  String get _trendingLabel =>
      isAr ? 'الأكثر رواجاً هذا الأسبوع' : 'Trending This Week';
  String get _newOpeningsLabel => isAr ? 'افتتاحات جديدة' : 'New Openings';
  String get _seeAll => isAr ? 'عرض الكل ›' : 'See all ›';

  @override
  Widget build(BuildContext context) {
    ref.watch(appLocaleProvider);

    // ✅ نراقب الـ selectedCategory — يعيد بناء الـ slivers عند كل تغيير
    final selectedIdx = ref.watch(selectedCategoryProvider);

    // نجلب الفئات لنعرف اسم الفئة المحددة
    final categories = ref.watch(categoriesProvider).value;

    // الفئة المحددة حالياً — null لو لا يوجد اختيار
    final selectedCat =
        (selectedIdx != null &&
            categories != null &&
            selectedIdx < categories.length)
        ? categories[selectedIdx]
        : null;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Pull to refresh ──────────────────────────────────────────
              CupertinoSliverRefreshControl(
                refreshTriggerPullDistance: 80,
                refreshIndicatorExtent: 50,
                onRefresh: _onRefresh,
                builder:
                    (
                      context,
                      mode,
                      pulledExtent,
                      triggerDistance,
                      indicatorExtent,
                    ) {
                      final progress = (pulledExtent / triggerDistance).clamp(
                        0.0,
                        1.0,
                      );
                      final scheme = Theme.of(context).colorScheme;
                      final isLoading =
                          mode == RefreshIndicatorMode.refresh ||
                          mode == RefreshIndicatorMode.armed;
                      return Center(
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : Opacity(
                                opacity: progress,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 24,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                      );
                    },
              ),

              // ── ثابت دائماً ──────────────────────────────────────────────
              const SliverToBoxAdapter(child: HomeAppBar()),
              SliverToBoxAdapter(child: HomeSearchBar()),
              SliverToBoxAdapter(child: PromotedBanner()),
              SliverToBoxAdapter(
                child: _sectionTitle(_hotEventsLabel, more: true),
              ),
              const SliverToBoxAdapter(child: HotEventsSection()),

              // ── Category bar — دائماً مرئي ───────────────────────────────
              SliverToBoxAdapter(child: _sectionTitle(_categoryLabel)),
              SliverToBoxAdapter(child: CategoryBar(isAr: isAr)),

              // ── مشروط: إذا لا يوجد اختيار → عادي ، يوجد اختيار → Feed ──
              if (selectedCat == null) ...[
                // ── الصفحة الطبيعية ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: _sectionTitle(_trendingLabel, more: true),
                ),
                const SliverToBoxAdapter(child: TrendingFeed()),
                SliverToBoxAdapter(
                  child: _sectionTitle(_newOpeningsLabel, more: true),
                ),
                const SliverToBoxAdapter(child: NewOpening()),
              ] else ...[
                // ── Category feed ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _sectionTitle(
                    isAr ? selectedCat.nameAr : selectedCat.nameEn,
                  ),
                ),
                // ✅ CategoryFeedSection ترجع SliverList مباشرة
                CategoryFeedSection(
                  categoryId: selectedCat.id,
                  categoryNameEn: selectedCat.nameEn,
                  categoryNameAr: selectedCat.nameAr,
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

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
