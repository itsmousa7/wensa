// lib/features/bookings_history/presentation/pages/bookings_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/presentation/pages/ticket_detail_page.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookingsHistoryPage extends ConsumerStatefulWidget {
  const BookingsHistoryPage({super.key});

  @override
  ConsumerState<BookingsHistoryPage> createState() =>
      _BookingsHistoryPageState();
}

class _BookingsHistoryPageState extends ConsumerState<BookingsHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'All',
    'Padel/Football',
    'Farm',
    'Concerts',
    'Restaurant',
    'Memberships',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToDetail(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TicketDetailPage(id: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          indicatorColor: cs.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
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
          // Tab 1: Padel / Football — combine both
          _CombinedSportsTab(
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 2: Farm
          _BookingsTab(
            asyncValue: ref.watch(
              userBookingsProvider(category: BookingCategory.farm),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 3: Concerts
          _BookingsTab(
            asyncValue: ref.watch(
              userBookingsProvider(category: BookingCategory.concert),
            ),
            onTap: (id) => _navigateToDetail(context, id),
          ),
          // Tab 4: Restaurant
          _BookingsTab(
            asyncValue: ref.watch(
              userBookingsProvider(category: BookingCategory.restaurant),
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
  const _BookingsTab({
    required this.asyncValue,
    required this.onTap,
  });

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
  const _MembershipsTab({
    required this.asyncValue,
    required this.onTap,
  });

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
//  _CombinedSportsTab  (padel + football)
// ─────────────────────────────────────────────────────────────────────────────
class _CombinedSportsTab extends ConsumerWidget {
  const _CombinedSportsTab({required this.onTap});

  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padelAsync =
        ref.watch(userBookingsProvider(category: BookingCategory.padel));
    final footballAsync =
        ref.watch(userBookingsProvider(category: BookingCategory.football));

    if (padelAsync.isLoading || footballAsync.isLoading) {
      return _BookingsSkeleton();
    }
    if (padelAsync.hasError) {
      return _ErrorView(
        message: padelAsync.error.toString(),
        onRetry: () {
          ref.invalidate(
            userBookingsProvider(category: BookingCategory.padel),
          );
          ref.invalidate(
            userBookingsProvider(category: BookingCategory.football),
          );
        },
      );
    }
    if (footballAsync.hasError) {
      return _ErrorView(
        message: footballAsync.error.toString(),
        onRetry: () {
          ref.invalidate(
            userBookingsProvider(category: BookingCategory.padel),
          );
          ref.invalidate(
            userBookingsProvider(category: BookingCategory.football),
          );
        },
      );
    }

    final combined = [
      ...(padelAsync.value ?? []),
      ...(footballAsync.value ?? []),
    ]..sort((a, b) => b.startsAt.compareTo(a.startsAt));

    if (combined.isEmpty) {
      return const _EmptyView(message: 'No padel or football bookings found.');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: combined.length,
      itemBuilder: (_, i) => TicketCard.booking(
        booking: combined[i],
        onTap: () => onTap(combined[i].id),
      ),
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
        itemBuilder: (_, _) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: cs.surfaceContainerHighest,
            ),
            title: Container(
              height: 14,
              width: 160,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                height: 20,
                width: 100,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
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
