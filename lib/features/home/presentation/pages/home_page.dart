import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/app_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_card_row_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_error_widget.dart';
import 'package:future_riverpod/features/home/presentation/widgets/category_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/home_search_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/hot_event_section.dart';
import 'package:future_riverpod/features/home/presentation/widgets/new_opening.dart';
import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';
import 'package:future_riverpod/features/home/presentation/widgets/trending_feed.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';

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

// ── Infinite carousel offset ──────────────────────────────────────────────────
// نبدأ من صفحة 10000 حتى الـ carousel يقدر يسكرول للخلف وللأمام بلا نهاية
const _kInfiniteOffset = 10000;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _navIndex = 0;

  late final PageController _pageCtrl;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    // ✅ نبدأ من _kInfiniteOffset حتى يكون عندنا مساحة للسكرول للخلف أيضاً
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

  // ── Localized strings ──────────────────────────────────────────────────────
  String get _hotEventsLabel => isAr ? '🔥 الأحداث الساخنة' : '🔥 Hot Events';
  String get _categoryLabel => isAr ? 'تصفح حسب الفئة' : 'Browse by Category';
  String get _trendingLabel =>
      isAr ? 'الأكثر رواجاً هذا الأسبوع' : 'Trending This Week';
  String get _newOpeningsLabel => isAr ? 'افتتاحات جديدة' : 'New Openings';
  String get _seeAll => isAr ? 'عرض الكل ›' : 'See all ›';

  String get trendingBadge => isAr ? '🔥 رائج' : '🔥 Hot';
  String get _justOpened => isAr ? '✦ افتُتح حديثاً' : '✦ Just Opened';
  String get eventBadge => isAr ? '🎉 حدث' : '🎉 Event';

  String _navLabel(int i) {
    const ar = ['الرئيسية', 'استكشف', 'الخريطة', 'محفوظة', 'حسابي'];
    const en = ['Home', 'Explore', 'Map', 'Saved', 'Profile'];
    return isAr ? ar[i] : en[i];
  }

  @override
  Widget build(BuildContext context) {
    // ✅ هذا السطر يجبر الـ build على إعادة التشغيل عند تغيير اللغة
    ref.watch(appLocaleProvider);

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
          child: Stack(
            children: [
              // ── CustomScrollView ─────────────────────────────────────────
              // كل قسم هو SliverToBoxAdapter — يحوّل Widget عادي إلى Sliver
              // الفايدة: scroll واحد يتحكم في كل الصفحة معاً
              CustomScrollView(
                slivers: [
                  // ✅ HomeAppBar الآن ConsumerWidget — ما تحتاج تمرر isAr
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
                  // مساحة فراغ فوق الـ bottom nav حتى المحتوى ما يختبئ تحته
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              // ── Bottom Nav فوق كل شيء ────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION TITLE ─────────────────────────────────────────────────────────
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

  // ── CATEGORIES ────────────────────────────────────────────────────────────

  // ── NEW OPENINGS ──────────────────────────────────────────────────────────
  Widget _buildNewOpeningsSection() {
    final newOpeningsAsync = ref.watch(newOpeningsProvider);
    return newOpeningsAsync.when(
      loading: () => BuildCardRowSkeleton(),
      error: (e, _) => buildErrorWidget(e.toString()),
      data: (places) => SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: places.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) => _buildPlaceCard(places[i]),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(PlaceModel place) => GestureDetector(
    onTap: () {
      /* TODO: Navigate to place detail */
    },
    child: Container(
      width: 170,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  height: 112,
                  width: double.infinity,
                  child: place.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: place.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: kSurface2),
                          errorWidget: (_, _, _) => Container(color: kSurface2),
                        )
                      : Container(color: kSurface2),
                ),
              ),
              Positioned(
                top: 9,
                left: isAr ? null : 9,
                right: isAr ? 9 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kNewGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _justOpened,
                    style: const TextStyle(
                      color: kText,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (place.isVerified == true)
                Positioned(
                  top: 9,
                  right: isAr ? null : 9,
                  left: isAr ? 9 : null,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '✓',
                        style: TextStyle(
                          color: kTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? place.nameAr : place.nameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                if (place.area != null)
                  Text(
                    '📍 ${place.area}',
                    style: const TextStyle(color: kText3, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const icons = ['🏠', '🔭', '🗺️', '❤️', '👤'];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (i) {
          final isActive = i == _navIndex;
          return GestureDetector(
            onTap: () => setState(() => _navIndex = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icons[i], style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  _navLabel(i),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? kOrange : kText3,
                  ),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: kOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── SKELETON CARD ROW ─────────────────────────────────────────────────────
  // ✅ Skeletonizer يرسم نفس شكل الـ card الحقيقي بدل مستطيلات عشوائية

  // ── HELPERS ───────────────────────────────────────────────────────────────
}
