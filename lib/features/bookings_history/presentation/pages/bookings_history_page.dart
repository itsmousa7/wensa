// lib/features/bookings_history/presentation/pages/bookings_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_card.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Semantic tab labels for the bookings history filter bar.
/// Order must match the [TabController] index assignments in [_BookingsHistoryPageState].
const kBookingHistoryTabs = [
  'All',
  'Sports',
  'Farm',
  'Concert',
  'Restaurant',
  'Memberships',
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: kBookingHistoryTabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToDetail(BuildContext context, String id) {
    context.push('/bookings/$id');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          'My Bookings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.40),
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.1),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3, color: cs.primary),
            borderRadius: BorderRadius.circular(3),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: kBookingHistoryTabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: All
          _BookingsTab(
            asyncValue: ref.watch(userBookingsProvider()),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 1: Hourly (courts / padel / football)
          _BookingsTab(
            asyncValue: ref.watch(
              userBookingsProvider(category: BookingCategory.hourly),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 2: Shift (farm)
          _BookingsTab(
            asyncValue: ref.watch(
              userBookingsProvider(category: BookingCategory.shift),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 3: Venue / Seat (concerts)
          _BookingsTab(
            asyncValue: ref.watch(
              userBookingsProvider(category: BookingCategory.venueSeat),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 4: Reservation (restaurant)
          _BookingsTab(
            asyncValue: ref.watch(
              userBookingsProvider(category: BookingCategory.reservation),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 5: Memberships
          _MembershipsTab(
            asyncValue: ref.watch(userMembershipsProvider),
            onTap: (id) => _navigateToDetail(context, 'm_$id'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _BookingsTab
// ─────────────────────────────────────────────────────────────────────────────
class _BookingsTab extends ConsumerWidget {
  const _BookingsTab({required this.asyncValue, required this.onTap});

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
          return const _EmptyView(message: 'No bookings found.');
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
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
//  _MembershipsTab
// ─────────────────────────────────────────────────────────────────────────────
class _MembershipsTab extends ConsumerWidget {
  const _MembershipsTab({required this.asyncValue, required this.onTap});

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
          return const _EmptyView(message: 'No memberships found.');
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
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
    final cardColor = Theme.of(context).cardTheme.color ?? cs.surface;
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: cs.surfaceContainer,
        highlightColor: cs.surfaceContainerHighest,
        duration: const Duration(milliseconds: 1200),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 5,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Container(
            height: 82,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                // icon panel placeholder
                Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 13,
                        width: 150,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 11,
                        width: 90,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
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
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
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
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              message,
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
