// lib/features/bookings_history/presentation/pages/bookings_history_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/widgets/section_tab_bar.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_card.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/bookings_scroll_signal.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

/// Semantic tab labels for the bookings history filter bar.
/// Order must match the [TabController] index assignments in [_BookingsHistoryPageState].
const kBookingHistoryTabsEn = [
  'All',
  'Sports',
  'Farm',
  'Concert',
  'Restaurant',
  'Memberships',
];

const kBookingHistoryTabsAr = [
  'الكل',
  'الرياضة',
  'المزرعة',
  'الحفلات',
  'المطعم',
  'العضويات',
];

class BookingsHistoryPage extends ConsumerStatefulWidget {
  const BookingsHistoryPage({super.key});

  @override
  ConsumerState<BookingsHistoryPage> createState() =>
      _BookingsHistoryPageState();
}

class _BookingsHistoryPageState extends ConsumerState<BookingsHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<ScrollController> _scrollCtrls;
  bool _isRefreshing = false;

  // Segment shown as selected by the native control. Driven by the tab's
  // animation value (not its settled index) so the indicator flips at the
  // swipe's midpoint and tracks the gesture instead of lagging behind it.
  int _segIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: kBookingHistoryTabsEn.length,
      vsync: this,
    );
    _tabController.animation?.addListener(_onTabAnim);
    _scrollCtrls = List.generate(
      kBookingHistoryTabsEn.length,
      (_) => ScrollController(),
    );
  }

  void _onTabAnim() {
    final i = _tabController.animation!.value.round();
    if (i != _segIndex && mounted) {
      setState(() => _segIndex = i);
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(userBookingsProvider);
      ref.invalidate(userMembershipsProvider);
      await Future.delayed(const Duration(milliseconds: 800));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_onTabAnim);
    _tabController.dispose();
    for (final c in _scrollCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _scrollActiveTabToTop() {
    final ctrl = _scrollCtrls[_tabController.index];
    if (ctrl.hasClients) {
      ctrl.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToDetail(BuildContext context, String id) {
    context.push('/bookings/$id');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bookingsScrollToTopProvider, (_, _) => _scrollActiveTabToTop());

    final cs = Theme.of(context).colorScheme;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final tabs = isArabic ? kBookingHistoryTabsAr : kBookingHistoryTabsEn;

    // When any booking is made, invalidate all list providers from inside this page.
    ref.listen(bookingsRefreshProvider, (_, _) {
      ref.invalidate(userBookingsProvider);
      ref.invalidate(userMembershipsProvider);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          isArabic ? 'حجوزاتي' : 'My Bookings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
        ),
        bottom: SectionTabBar(
          tabs: tabs,
          controller: _tabController,
          selectedIndex: _segIndex,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: All — bookings + memberships combined
          _CombinedTab(
            scrollController: _scrollCtrls[0],
            bookingsAsync: ref.watch(userBookingsProvider()),
            membershipsAsync: ref.watch(userMembershipsProvider),
            onBookingTap: (id) => _navigateToDetail(context, id),
            onMembershipTap: (id) => _navigateToDetail(context, 'm_$id'),
            onRefresh: _onRefresh,
          ),
          // Tab 1: Sports — sports bookings + memberships (gym is sports)
          _CombinedTab(
            scrollController: _scrollCtrls[1],
            bookingsAsync: ref.watch(
              userBookingsProvider(categories: const ['sports']),
            ),
            membershipsAsync: ref.watch(userMembershipsProvider),
            onBookingTap: (id) => _navigateToDetail(context, id),
            onMembershipTap: (id) => _navigateToDetail(context, 'm_$id'),
            onRefresh: _onRefresh,
          ),
          // Tab 2: Farm
          _BookingsTab(
            scrollController: _scrollCtrls[2],
            asyncValue: ref.watch(
              userBookingsProvider(categories: const ['farm']),
            ),
            onTap: (id) => _navigateToDetail(context, id),
            onRefresh: _onRefresh,
          ),
          // Tab 3: Concert
          _BookingsTab(
            scrollController: _scrollCtrls[3],
            asyncValue: ref.watch(
              userBookingsProvider(categories: const ['concert']),
            ),
            onTap: (id) => _navigateToDetail(context, id),
            onRefresh: _onRefresh,
          ),
          // Tab 4: Restaurant
          _BookingsTab(
            scrollController: _scrollCtrls[4],
            asyncValue: ref.watch(
              userBookingsProvider(categories: const ['restaurant']),
            ),
            onTap: (id) => _navigateToDetail(context, id),
            onRefresh: _onRefresh,
          ),
          // Tab 5: Memberships
          _MembershipsTab(
            scrollController: _scrollCtrls[5],
            asyncValue: ref.watch(userMembershipsProvider),
            onTap: (id) => _navigateToDetail(context, 'm_$id'),
            onRefresh: _onRefresh,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared refresh control builder
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildRefreshIndicator(
  BuildContext context,
  RefreshIndicatorMode mode,
  double pulledExtent,
  double triggerDistance,
  double refreshIndicatorExtent,
) {
  final cs = Theme.of(context).colorScheme;
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
              color: cs.primary,
            ),
          )
        : Opacity(
            opacity: progress,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 24,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  _TicketItem — union type for combined booking + membership lists
// ─────────────────────────────────────────────────────────────────────────────
sealed class _TicketItem {
  String get sortKey;
}

final class _BookingItem extends _TicketItem {
  _BookingItem(this.booking);
  final Booking booking;
  @override
  String get sortKey => booking.createdAt ?? booking.startsAt;
}

final class _MembershipItem extends _TicketItem {
  _MembershipItem(this.membership);
  final Membership membership;
  @override
  String get sortKey => membership.createdAt ?? membership.startsAt;
}

// ─────────────────────────────────────────────────────────────────────────────
//  _BookingsTab — bookings only (Farm, Concert, Restaurant)
// ─────────────────────────────────────────────────────────────────────────────
class _BookingsTab extends ConsumerWidget {
  const _BookingsTab({
    required this.scrollController,
    required this.asyncValue,
    required this.onTap,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final AsyncValue<List<Booking>> asyncValue;
  final void Function(String id) onTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = asyncValue.value;
    final isLoading = asyncValue.isLoading;
    final hasError = asyncValue.hasError && bookings == null;

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 80,
          refreshIndicatorExtent: 50,
          onRefresh: onRefresh,
          builder: _buildRefreshIndicator,
        ),
        if (isLoading && bookings == null)
          const SliverPadding(
            padding: EdgeInsets.only(top: 8, bottom: 110),
            sliver: _SkeletonSliver(),
          )
        else if (hasError)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorView(
              message: asyncValue.error.toString(),
              onRetry: () => ref.invalidate(userBookingsProvider),
            ),
          )
        else if (bookings == null || bookings.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => TicketCard.booking(
                  booking: bookings[i],
                  onTap: () => onTap(bookings[i].id),
                ),
                childCount: bookings.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _CombinedTab — bookings + memberships merged (All, Sports)
// ─────────────────────────────────────────────────────────────────────────────
class _CombinedTab extends ConsumerWidget {
  const _CombinedTab({
    required this.scrollController,
    required this.bookingsAsync,
    required this.membershipsAsync,
    required this.onBookingTap,
    required this.onMembershipTap,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final AsyncValue<List<Booking>> bookingsAsync;
  final AsyncValue<List<Membership>> membershipsAsync;
  final void Function(String id) onBookingTap;
  final void Function(String id) onMembershipTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        (bookingsAsync.isLoading && bookingsAsync.value == null) ||
        (membershipsAsync.isLoading && membershipsAsync.value == null);

    final bookingsError = bookingsAsync.hasError && bookingsAsync.value == null
        ? bookingsAsync.error
        : null;
    final membershipsError =
        membershipsAsync.hasError && membershipsAsync.value == null
        ? membershipsAsync.error
        : null;

    final bookings = bookingsAsync.value ?? [];
    final memberships = membershipsAsync.value ?? [];

    final List<_TicketItem> items = [
      ...bookings.map(_BookingItem.new),
      ...memberships.map(_MembershipItem.new),
    ]..sort((a, b) => b.sortKey.compareTo(a.sortKey));

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 80,
          refreshIndicatorExtent: 50,
          onRefresh: onRefresh,
          builder: _buildRefreshIndicator,
        ),
        if (isLoading)
          const SliverPadding(
            padding: EdgeInsets.only(top: 8, bottom: 110),
            sliver: _SkeletonSliver(),
          )
        else if (bookingsError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorView(
              message: bookingsError.toString(),
              onRetry: () {
                ref.invalidate(userBookingsProvider);
                ref.invalidate(userMembershipsProvider);
              },
            ),
          )
        else if (membershipsError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorView(
              message: membershipsError.toString(),
              onRetry: () {
                ref.invalidate(userBookingsProvider);
                ref.invalidate(userMembershipsProvider);
              },
            ),
          )
        else if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final item = items[i];
                  return switch (item) {
                    _BookingItem(:final booking) => TicketCard.booking(
                      booking: booking,
                      onTap: () => onBookingTap(booking.id),
                    ),
                    _MembershipItem(:final membership) => TicketCard.membership(
                      membership: membership,
                      onTap: () => onMembershipTap(membership.id),
                    ),
                  };
                },
                childCount: items.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _MembershipsTab
// ─────────────────────────────────────────────────────────────────────────────
class _MembershipsTab extends ConsumerWidget {
  const _MembershipsTab({
    required this.scrollController,
    required this.asyncValue,
    required this.onTap,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final AsyncValue<List<Membership>> asyncValue;
  final void Function(String id) onTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = asyncValue.value;
    final isLoading = asyncValue.isLoading && memberships == null;
    final hasError = asyncValue.hasError && memberships == null;

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 80,
          refreshIndicatorExtent: 50,
          onRefresh: onRefresh,
          builder: _buildRefreshIndicator,
        ),
        if (isLoading)
          const SliverPadding(
            padding: EdgeInsets.only(top: 8, bottom: 110),
            sliver: _SkeletonSliver(),
          )
        else if (hasError)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorView(
              message: asyncValue.error.toString(),
              onRetry: () => ref.invalidate(userMembershipsProvider),
            ),
          )
        else if (memberships == null || memberships.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => TicketCard.membership(
                  membership: memberships[i],
                  onTap: () => onTap(memberships[i].id),
                ),
                childCount: memberships.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton — sliver version (stays inside CustomScrollView)
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonSliver extends StatelessWidget {
  const _SkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, _) => const _BookingSkeletonItem(),
        childCount: 8,
      ),
    );
  }
}

class _BookingSkeletonItem extends StatelessWidget {
  const _BookingSkeletonItem();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: AppSpacing.borderRadiusLG,
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
        ),
        padding: const EdgeInsets.all(14),
        child: Skeletonizer(
          enabled: true,
          effect: ShimmerEffect(
            baseColor: cs.surfaceContainerHighest,
            highlightColor: cs.surface,
            duration: const Duration(milliseconds: 1200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Bone(
                width: 48,
                height: 48,
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Bone(
                              height: 13,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Bone(
                            width: 72,
                            height: 24,
                            borderRadius: AppSpacing.borderRadiusXL,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Bone(
                            width: 110,
                            height: 11,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const Spacer(),
                          Bone(
                            width: 70,
                            height: 11,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Bone(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Error view
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'حدث خطأ ما' : 'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty view
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final tt = AppTypography.getTextTheme(isArabic ? 'ar' : 'en', context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            child: Lottie.asset('assets/lottie/animation/empty.json'),
          ),
          Text(
            isArabic ? 'لا توجد حجوزات بعد' : 'No bookings yet',
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'ستظهر حجوزاتك هنا' : 'Your bookings will appear here',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
