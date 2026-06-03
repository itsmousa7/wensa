// lib/features/bookings_history/presentation/pages/bookings_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_card.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/bookings_scroll_signal.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: kBookingHistoryTabsEn.length,
      vsync: this,
    );
    _scrollCtrls = List.generate(
      kBookingHistoryTabsEn.length,
      (_) => ScrollController(),
    );
  }

  @override
  void dispose() {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final selected = _tabController.index == i;
                  return GestureDetector(
                    onTap: () => _tabController.animateTo(i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 6,
                              ),
                              child: Text(
                                tabs[i],
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: selected
                                          ? cs.primary
                                          : cs.onSurface.withValues(
                                              alpha: 0.40,
                                            ),
                                    ),
                              ),
                            ),
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: selected
                                    ? cs.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 1),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
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
          ),
          // Tab 2: Farm
          _BookingsTab(
            scrollController: _scrollCtrls[2],
            asyncValue: ref.watch(
              userBookingsProvider(categories: const ['farm']),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 3: Concert
          _BookingsTab(
            scrollController: _scrollCtrls[3],
            asyncValue: ref.watch(
              userBookingsProvider(categories: const ['concert']),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 4: Restaurant
          _BookingsTab(
            scrollController: _scrollCtrls[4],
            asyncValue: ref.watch(
              userBookingsProvider(categories: const ['restaurant']),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 5: Memberships
          _MembershipsTab(
            scrollController: _scrollCtrls[5],
            asyncValue: ref.watch(userMembershipsProvider),
            onTap: (id) => _navigateToDetail(context, 'm_$id'),
          ),
        ],
      ),
    );
  }
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
  });

  final ScrollController scrollController;
  final AsyncValue<List<Booking>> asyncValue;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      loading: () => _BookingsSkeleton(),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(userBookingsProvider),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const _EmptyView();
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(top: 8, bottom: 110),
          itemCount: bookings.length,
          itemBuilder: (_, i) => TicketCard.booking(
            booking: bookings[i],
            onTap: () => onTap(bookings[i].id),
          ),
        );
      },
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
  });

  final ScrollController scrollController;
  final AsyncValue<List<Booking>> bookingsAsync;
  final AsyncValue<List<Membership>> membershipsAsync;
  final void Function(String id) onBookingTap;
  final void Function(String id) onMembershipTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookingsAsync.isLoading || membershipsAsync.isLoading) {
      return _BookingsSkeleton();
    }

    final bookingsError = bookingsAsync.error;
    if (bookingsError != null) {
      return _ErrorView(
        message: bookingsError.toString(),
        onRetry: () {
          ref.invalidate(userBookingsProvider);
          ref.invalidate(userMembershipsProvider);
        },
      );
    }

    final membershipsError = membershipsAsync.error;
    if (membershipsError != null) {
      return _ErrorView(
        message: membershipsError.toString(),
        onRetry: () {
          ref.invalidate(userBookingsProvider);
          ref.invalidate(userMembershipsProvider);
        },
      );
    }

    final bookings = bookingsAsync.value ?? [];
    final memberships = membershipsAsync.value ?? [];

    final List<_TicketItem> items = [
      ...bookings.map(_BookingItem.new),
      ...memberships.map(_MembershipItem.new),
    ]..sort((a, b) => b.sortKey.compareTo(a.sortKey));

    if (items.isEmpty) return const _EmptyView();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 110),
      itemCount: items.length,
      itemBuilder: (_, i) {
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
  });

  final ScrollController scrollController;
  final AsyncValue<List<Membership>> asyncValue;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      loading: () => _BookingsSkeleton(),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(userMembershipsProvider),
      ),
      data: (memberships) {
        if (memberships.isEmpty) {
          return const _EmptyView();
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(top: 8, bottom: 110),
          itemCount: memberships.length,
          itemBuilder: (_, i) => TicketCard.membership(
            membership: memberships[i],
            onTap: () => onTap(memberships[i].id),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton
// ─────────────────────────────────────────────────────────────────────────────
class _BookingsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 110),
      itemCount: 8,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        // Card frame is outside Skeletonizer so it always renders as a real
        // card — not a flat bone — between shimmer pulses.
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
                // Icon square — mirrors actual 48×48 r12 icon container
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
                      // Row 1: name + status badge
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
                      // Row 2: date (left) + amount (right)
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'لا توجد حجوزات.' : 'No bookings found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
