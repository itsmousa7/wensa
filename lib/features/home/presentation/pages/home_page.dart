import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/app_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/home_search_bar.dart';
import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';
import 'package:future_riverpod/features/places/domain/models/event_model.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/domain/models/trending_feed_item_model.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  int _eventIndex = 0;
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

  String get _bookNow => isAr ? 'احجز الآن' : 'Book Now';
  String get _trendingBadge => isAr ? '🔥 رائج' : '🔥 Hot';
  String get _justOpened => isAr ? '✦ افتُتح حديثاً' : '✦ Just Opened';
  String get _eventBadge => isAr ? '🎉 حدث' : '🎉 Event';

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
                  SliverToBoxAdapter(child: _buildHotEventsSection()),
                  SliverToBoxAdapter(child: _buildEventDots()),
                  SliverToBoxAdapter(child: _sectionTitle(_categoryLabel)),
                  SliverToBoxAdapter(child: _buildCategoriesSection()),
                  SliverToBoxAdapter(
                    child: _sectionTitle(_trendingLabel, more: true),
                  ),
                  SliverToBoxAdapter(child: _buildTrendingSection()),
                  SliverToBoxAdapter(
                    child: _sectionTitle(_newOpeningsLabel, more: true),
                  ),
                  SliverToBoxAdapter(child: _buildNewOpeningsSection()),
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
          style: const TextStyle(
            color: kText,
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

  // ── PROMOTED BANNERS ──────────────────────────────────────────────────────

  // ── HOT EVENTS — Infinite Carousel ────────────────────────────────────────
  Widget _buildHotEventsSection() {
    final hotEventsAsync = ref.watch(hotEventsProvider);

    return hotEventsAsync.when(
      // ✅ Skeletonizer للـ loading
      loading: () => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(
          baseColor: kSurface2,
          highlightColor: kBorder,
        ),
        child: SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => Container(
              width: i == 0 ? 300 : 155,
              decoration: BoxDecoration(
                color: kSurface2,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => _buildErrorWidget(e.toString()),
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageCtrl,
            // ✅ itemCount: null = لا نهاية للـ carousel
            // المستخدم يقدر يسكرول يميناً ويساراً إلى ما لا نهاية
            itemCount: null,
            onPageChanged: (absoluteIndex) {
              // نحوّل الـ absolute index إلى real index باستخدام modulo
              setState(() => _eventIndex = absoluteIndex % events.length);
            },
            itemBuilder: (_, absoluteIndex) {
              // ✅ modulo يضمن إن الـ events تتكرر بشكل دائري
              final realIndex = absoluteIndex % events.length;
              final event = events[realIndex];
              return Padding(
                padding: EdgeInsets.only(
                  left: isAr ? 0 : 22,
                  right: isAr ? 22 : 14,
                ),
                child: realIndex == 0
                    ? _buildHeroEventCard(event)
                    : _buildSmallEventCard(event),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeroEventCard(EventModel event) => GestureDetector(
    onTap: () {
      /* TODO: Navigate to event detail */
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: kSurface2,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: event.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: kSurface2),
                      errorWidget: (_, __, ___) => Container(color: kSurface2),
                    )
                  : Container(color: kSurface2),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: isAr ? null : 12,
            right: isAr ? 12 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: kOrange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kOrange.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                _trendingBadge,
                style: const TextStyle(
                  color: kText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '📅 ${_formatDate(event.startDate)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📍 ${event.city ?? ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr ? event.titleAr : event.titleEn,
                    style: const TextStyle(
                      color: kText,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (event.ticketPrice != null)
                        Text(
                          '🎟 ${event.ticketPrice!.toStringAsFixed(0)} IQD',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      if (event.ticketUrl != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kOrange, kOrange2],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: kOrange.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            _bookNow,
                            style: const TextStyle(
                              color: kText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSmallEventCard(EventModel event) => GestureDetector(
    onTap: () {
      /* TODO: Navigate to event detail */
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: kSurface2,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: event.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: kSurface2),
                      errorWidget: (_, __, ___) => Container(color: kSurface2),
                    )
                  : Container(color: kSurface2),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? event.titleAr : event.titleEn,
                    style: const TextStyle(
                      color: kText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatDate(event.startDate)} · ${event.city ?? ''}',
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ── EVENT DOTS ────────────────────────────────────────────────────────────
  Widget _buildEventDots() {
    final hotEventsAsync = ref.watch(hotEventsProvider);
    return hotEventsAsync.maybeWhen(
      data: (events) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            events.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _eventIndex ? 20 : 6,
              height: 4,
              decoration: BoxDecoration(
                color: i == _eventIndex ? kOrange : kBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  // ── CATEGORIES ────────────────────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedIndex = ref.watch(selectedCategoryProvider);

    return categoriesAsync.when(
      loading: () => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(
          baseColor: kSurface2,
          highlightColor: kBorder,
        ),
        child: SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: kSurface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 48, height: 10, color: kSurface2),
              ],
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (cats) => SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final isActive = i == selectedIndex;
            final cat = cats[i];
            return GestureDetector(
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).select(i),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isActive
                          ? kOrange.withValues(alpha: 0.15)
                          : kSurface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? kOrange : kBorder,
                        width: 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: kOrange.withValues(alpha: 0.3),
                                blurRadius: 14,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        _categoryEmoji(cat.nameEn),
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? cat.nameAr : cat.nameEn,
                    style: TextStyle(
                      color: isActive ? kOrange : kText2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── TRENDING FEED ─────────────────────────────────────────────────────────
  Widget _buildTrendingSection() {
    final trendingAsync = ref.watch(trendingFeedProvider);
    return trendingAsync.when(
      loading: () => _buildCardRowSkeleton(),
      error: (e, _) => _buildErrorWidget(e.toString()),
      data: (items) => SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) => _buildTrendingCard(items[i]),
        ),
      ),
    );
  }

  Widget _buildTrendingCard(TrendingFeedItemModel item) {
    final isEvent = item.isEvent;
    final badgeColor = isEvent ? kEventBlue : kOrange;
    final badgeText = isEvent ? _eventBadge : _trendingBadge;

    return GestureDetector(
      onTap: () {
        /* TODO: Navigate based on item.type */
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEvent ? kEventBlue.withValues(alpha: 0.35) : kBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SizedBox(
                height: 112,
                width: double.infinity,
                child: item.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: kSurface2),
                        errorWidget: (_, __, ___) =>
                            Container(color: kSurface2),
                      )
                    : Container(color: kSurface2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: kText,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? item.titleAr : item.titleEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (isAr ? item.subtitleAr : item.subtitleEn) ?? '',
                    maxLines: 1,
                    style: TextStyle(
                      color: isEvent ? kOrange : kText3,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── NEW OPENINGS ──────────────────────────────────────────────────────────
  Widget _buildNewOpeningsSection() {
    final newOpeningsAsync = ref.watch(newOpeningsProvider);
    return newOpeningsAsync.when(
      loading: () => _buildCardRowSkeleton(),
      error: (e, _) => _buildErrorWidget(e.toString()),
      data: (places) => SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: places.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
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
                          placeholder: (_, __) => Container(color: kSurface2),
                          errorWidget: (_, __, ___) =>
                              Container(color: kSurface2),
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
        color: kBg.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: kBorder)),
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
  Widget _buildCardRowSkeleton() => Skeletonizer(
    enabled: true,
    effect: const ShimmerEffect(baseColor: kSurface2, highlightColor: kBorder),
    child: SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Container(
          width: 170,
          decoration: BoxDecoration(
            color: kSurface2,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة
              Container(
                height: 112,
                width: 170,
                decoration: const BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              // badge
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Container(
                  width: 50,
                  height: 16,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(height: 13, width: 130, color: kBorder),
              ),
              const SizedBox(height: 6),
              // subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(height: 10, width: 80, color: kBorder),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildErrorWidget(String message) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    child: Text(
      'Error: $message',
      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
    ),
  );

  // ── HELPERS ───────────────────────────────────────────────────────────────
  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return isoDate;
    }
  }

  String _categoryEmoji(String nameEn) {
    const map = {
      'Restaurants': '🍽️',
      'Music': '🎵',
      'Malls': '🛍️',
      'Cafes': '☕',
      'Cinema': '🎬',
      'Festivals': '🎪',
      'Sports': '🏋️',
    };
    return map[nameEn] ?? '📍';
  }
}
