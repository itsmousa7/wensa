import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_provider.dart';
import 'package:future_riverpod/features/places/domain/models/event_model.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _kOrange = Color(0xFFFF5E2C);
const _kOrange2 = Color(0xFFFF8A5C);

const _kSurface2 = Color(0xFF1E1E2E);
const _kText = Color(0xFFFFFFFF);

// ─────────────────────────────────────────────────────────────────────────────
//  HotEventsSection
//  ✅ الـ dots داخل هذا الـ widget — لا تضف dots في home_page
// ─────────────────────────────────────────────────────────────────────────────
class HotEventsSection extends ConsumerStatefulWidget {
  const HotEventsSection({super.key});

  @override
  ConsumerState<HotEventsSection> createState() => _HotEventsSectionState();
}

class _HotEventsSectionState extends ConsumerState<HotEventsSection> {
  static const _kInfiniteOffset = 10000;

  late final PageController _pageCtrl;
  Timer? _autoScrollTimer;
  int _eventIndex = 0;

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

  bool get _isAr => ref.watch(appLocaleProvider) is ArabicLocale;

  TextTheme get _tt => AppTypography.getTextTheme(_isAr ? 'ar' : 'en', context);

  @override
  Widget build(BuildContext context) {
    final hotEventsAsync = ref.watch(hotEventsProvider);
    final theme = Theme.of(context);

    return hotEventsAsync.when(
      loading: () => _buildSkeleton(theme),
      error: (e, _) => _buildError(e.toString()),
      // ✅ الـ dots داخل الـ Column هنا — لا تعيدها في home_page
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCarousel(events),
            _buildDots(events.length), // ← الـ dots مرة واحدة هنا فقط
          ],
        );
      },
    );
  }

  // ── CAROUSEL ──────────────────────────────────────────────────────────────
  Widget _buildCarousel(List<EventModel> events) => SizedBox(
    height: 200,
    child: PageView.builder(
      controller: _pageCtrl,
      itemCount: null,
      onPageChanged: (abs) => setState(() => _eventIndex = abs % events.length),
      itemBuilder: (_, abs) {
        final i = abs % events.length;
        final event = events[i];
        return Padding(
          padding: EdgeInsets.only(
            left: _isAr ? 0 : 22,
            right: _isAr ? 22 : 14,
          ),
          child: i == 0
              ? _HeroEventCard(event: event, isAr: _isAr, tt: _tt)
              : _SmallEventCard(event: event, isAr: _isAr, tt: _tt),
        );
      },
    ),
  );

  // ── DOTS ──────────────────────────────────────────────────────────────────
  Widget _buildDots(int count) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == _eventIndex ? 20 : 6,
          height: 4,
          decoration: BoxDecoration(
            color: i == _eventIndex
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ),
  );

  // ── SKELETON — نفس أسلوب PromotedBanner بالضبط ────────────────────────────
  //  PromotedBanner:  surfaceContainer bg + surfaceContainerHighest للعناصر
  //  هنا نطبق نفس الفكرة على كارد أكبر (200px height)
  Widget _buildSkeleton(ThemeData theme) => Skeletonizer(
    enabled: true,
    effect: ShimmerEffect(
      baseColor: theme.colorScheme.surfaceContainer,
      highlightColor: theme.colorScheme.surfaceContainerHighest,
      duration: const Duration(milliseconds: 1200),
    ),
    child: SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => Container(
          width: i == 0 ? 300 : 155,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              // ── صورة الخلفية ──────────────────────────────────────────
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              // ── gradient مثل الكارد الحقيقي ──────────────────────────
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
                          theme.colorScheme.surfaceContainer.withValues(
                            alpha: 0.9,
                          ),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // ── badge في الأعلى ───────────────────────────────────────
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 55,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // ── النصوص في الأسفل ──────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // date + city
                      Row(
                        children: [
                          Container(
                            height: 10,
                            width: 59,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 10,
                            width: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // title
                      Container(
                        height: 16,
                        width: i == 0 ? 180 : 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      if (i == 0) ...[
                        const SizedBox(height: 10),
                        // book now button shape
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 90,
                            height: 30,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildError(String msg) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    child: Text(
      'Error: $msg',
      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  _HeroEventCard
// ─────────────────────────────────────────────────────────────────────────────
class _HeroEventCard extends StatelessWidget {
  const _HeroEventCard({
    required this.event,
    required this.isAr,
    required this.tt,
  });

  final EventModel event;
  final bool isAr;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _kSurface2,
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
                        placeholder: (_, _) => Container(color: _kSurface2),
                        errorWidget: (_, _, _) => Container(color: _kSurface2),
                      )
                    : Container(color: _kSurface2),
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
            // Hot badge
            Positioned(
              top: 12,
              left: isAr ? null : 12,
              right: isAr ? 12 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _kOrange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  isAr ? '🔥 رائج' : '🔥 Hot',
                  style: tt.labelSmall?.copyWith(
                    color: _kText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? event.titleAr : event.titleEn,
                      style: tt.titleLarge?.copyWith(
                        color: _kText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📅 ${_formatDate(event.startDate)}',
                          style: tt.bodySmall?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '📍 ${event.city ?? ''}',
                          style: tt.bodySmall?.copyWith(color: Colors.white70),
                        ),

                        Spacer(),
                        if (event.ticketUrl != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kOrange, _kOrange2],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _kOrange.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Text(
                              isAr ? 'احجز الآن' : 'Book Now',
                              style: tt.labelMedium?.copyWith(
                                color: _kText,
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _SmallEventCard
// ─────────────────────────────────────────────────────────────────────────────
class _SmallEventCard extends StatelessWidget {
  const _SmallEventCard({
    required this.event,
    required this.isAr,
    required this.tt,
  });

  final EventModel event;
  final bool isAr;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _kSurface2,
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
                        placeholder: (_, _) => Container(color: _kSurface2),
                        errorWidget: (_, _, _) => Container(color: _kSurface2),
                      )
                    : Container(color: _kSurface2),
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
                      style: tt.titleSmall?.copyWith(color: _kText),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatDate(event.startDate)} · ${event.city ?? ''}',
                      style: tt.bodySmall?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
