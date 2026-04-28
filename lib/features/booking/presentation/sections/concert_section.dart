import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/event_tier.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/hold_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/bilingual_label.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/hold_countdown_banner.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/seat_map.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/tier_legend.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Tier palette
// ---------------------------------------------------------------------------

const _tierPalette = [
  Color(0xFF6C63FF), // purple (VIP)
  Color(0xFF00C896), // teal (standard)
  Color(0xFFFF6B6B), // coral
  Color(0xFFFFB547), // amber
];

Map<String, Color> _buildTierColors(List<EventTier> tiers) {
  final sorted = [...tiers]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final map = <String, Color>{};
  for (var i = 0; i < sorted.length; i++) {
    map[sorted[i].nameEn] = _tierPalette[i % _tierPalette.length];
  }
  return map;
}

// ---------------------------------------------------------------------------
// Local state — concert selection
// ---------------------------------------------------------------------------

typedef _ConcertState = ({
  Set<String> selectedSeatIds,
  Set<String> filterTierKeys,
  String? holdUntil,
});

class _ConcertSelectionNotifier extends Notifier<_ConcertState> {
  @override
  _ConcertState build() =>
      (selectedSeatIds: {}, filterTierKeys: {}, holdUntil: null);

  void toggleSeat(Seat seat) {
    final selected = Set<String>.from(state.selectedSeatIds);
    if (selected.contains(seat.seatId)) {
      selected.remove(seat.seatId);
    } else {
      selected.add(seat.seatId);
    }
    final holdUntil = selected.isEmpty
        ? null
        : DateTime.now()
            .add(const Duration(seconds: 60))
            .toIso8601String();
    state = (
      selectedSeatIds: selected,
      filterTierKeys: state.filterTierKeys,
      holdUntil: holdUntil,
    );
  }

  void toggleTierFilter(String tierKey) {
    final filters = Set<String>.from(state.filterTierKeys);
    if (filters.contains(tierKey)) {
      filters.remove(tierKey);
    } else {
      filters.add(tierKey);
    }
    state = (
      selectedSeatIds: state.selectedSeatIds,
      filterTierKeys: filters,
      holdUntil: state.holdUntil,
    );
  }

  void setHold(String holdUntil) {
    state = (
      selectedSeatIds: state.selectedSeatIds,
      filterTierKeys: state.filterTierKeys,
      holdUntil: holdUntil,
    );
  }

  void reset() =>
      state = (selectedSeatIds: {}, filterTierKeys: {}, holdUntil: null);
}

final _concertSelectionProvider =
    NotifierProvider<_ConcertSelectionNotifier, _ConcertState>(
        _ConcertSelectionNotifier.new);

// ---------------------------------------------------------------------------
// ConcertSection
// ---------------------------------------------------------------------------

class ConcertSection extends ConsumerWidget {
  const ConcertSection({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(bookingSubmitProvider);

    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil) async {
          if (paymentUrl.isNotEmpty) {
            final uri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        orElse: () {},
      );
    });

    return submitState.maybeWhen(
      success: (bookingId, paymentUrl, holdUntil) =>
          _PaymentInProgressView(holdUntil: holdUntil, eventId: eventId),
      orElse: () => _ConcertBookingView(eventId: eventId),
    );
  }
}

// ---------------------------------------------------------------------------
// Main booking view
// ---------------------------------------------------------------------------

class _ConcertBookingView extends ConsumerWidget {
  const _ConcertBookingView({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seatsAsync = ref.watch(availableSeatsProvider(eventId));
    final tiersAsync = ref.watch(eventTiersProvider(eventId));
    final selection = ref.watch(_concertSelectionProvider);

    return tiersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading tiers: $e')),
      data: (tiers) {
        final tierColors = _buildTierColors(tiers);

        return Column(
          children: [
            // Hold countdown banner (resets on each new seat tap)
            if (selection.holdUntil != null)
              _HoldBannerWithExpiry(
                holdUntil: selection.holdUntil!,
                onExpired: () {
                  ref.read(_concertSelectionProvider.notifier).reset();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Your seat hold has expired. Please reselect.',
                        ),
                      ),
                    );
                  }
                },
              ),

            // Tier filter chips
            _TierFilterChips(
              tiers: tiers,
              tierColors: tierColors,
              selectedTierKeys: selection.filterTierKeys,
              onToggle: (key) =>
                  ref.read(_concertSelectionProvider.notifier).toggleTierFilter(key),
            ),

            // Tier legend
            TierLegend(tiers: tiers, tierColors: tierColors),

            // Seat map
            Expanded(
              child: seatsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading seats: $e')),
                data: (seats) => SeatMapWidget(
                  seats: seats,
                  selectedSeatIds: selection.selectedSeatIds,
                  tierColors: tierColors,
                  filterTierKeys: selection.filterTierKeys.isEmpty
                      ? null
                      : selection.filterTierKeys,
                  onSeatTap: (seat) {
                    ref
                        .read(_concertSelectionProvider.notifier)
                        .toggleSeat(seat);
                  },
                ),
              ),
            ),

            // Selected seats bar + Review button
            if (selection.selectedSeatIds.isNotEmpty)
              seatsAsync.maybeWhen(
                data: (seats) => _SelectedSeatsBar(
                  selectedSeatIds: selection.selectedSeatIds,
                  seats: seats,
                  tiers: tiers,
                  eventId: eventId,
                  onReset: () =>
                      ref.read(_concertSelectionProvider.notifier).reset(),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hold banner that fires a callback when timer reaches 0
// ---------------------------------------------------------------------------

class _HoldBannerWithExpiry extends ConsumerWidget {
  const _HoldBannerWithExpiry({
    required this.holdUntil,
    required this.onExpired,
  });

  final String holdUntil;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(holdCountdownProvider(holdUntil));
    if (seconds <= 0) {
      // Use addPostFrameCallback so we don't call setState mid-build
      WidgetsBinding.instance.addPostFrameCallback((_) => onExpired());
    }
    return HoldCountdownBanner(holdUntil: holdUntil);
  }
}

// ---------------------------------------------------------------------------
// Tier filter chips
// ---------------------------------------------------------------------------

class _TierFilterChips extends StatelessWidget {
  const _TierFilterChips({
    required this.tiers,
    required this.tierColors,
    required this.selectedTierKeys,
    required this.onToggle,
  });

  final List<EventTier> tiers;
  final Map<String, Color> tierColors;
  final Set<String> selectedTierKeys;
  final void Function(String tierKey) onToggle;

  @override
  Widget build(BuildContext context) {
    if (tiers.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: tiers.map((tier) {
          final key = tier.nameEn;
          final isSelected = selectedTierKeys.contains(key);
          final color = tierColors[key] ?? Colors.grey;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: BilingualLabel(ar: tier.nameAr, en: tier.nameEn),
              selected: isSelected,
              selectedColor: color.withValues(alpha: 0.25),
              checkmarkColor: color,
              side: BorderSide(
                color: isSelected ? color : Colors.grey.shade300,
              ),
              onSelected: (_) => onToggle(key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selected seats bottom bar
// ---------------------------------------------------------------------------

class _SelectedSeatsBar extends ConsumerWidget {
  const _SelectedSeatsBar({
    required this.selectedSeatIds,
    required this.seats,
    required this.tiers,
    required this.eventId,
    required this.onReset,
  });

  final Set<String> selectedSeatIds;
  final List<Seat> seats;
  final List<EventTier> tiers;
  final String eventId;
  final VoidCallback onReset;

  Map<String, EventTier> get _tierByKey {
    final map = <String, EventTier>{};
    for (final t in tiers) {
      map[t.nameEn] = t;
    }
    return map;
  }

  int get _totalPrice {
    final byKey = _tierByKey;
    int total = 0;
    for (final s in seats) {
      if (selectedSeatIds.contains(s.seatId)) {
        total += byKey[s.tierKey]?.priceIqd ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = selectedSeatIds.length;
    final total = _totalPrice;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count seat${count > 1 ? 's' : ''} selected',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${(total / 1000).toStringAsFixed(0)}k IQD total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => _showReviewSheet(context, ref),
              child: const Text('Review'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, WidgetRef ref) {
    final byKey = _tierByKey;
    final selectedSeats =
        seats.where((s) => selectedSeatIds.contains(s.seatId)).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReviewSheet(
        selectedSeats: selectedSeats,
        tierByKey: byKey,
        eventId: eventId,
        onReset: onReset,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review bottom sheet
// ---------------------------------------------------------------------------

class _ReviewSheet extends ConsumerWidget {
  const _ReviewSheet({
    required this.selectedSeats,
    required this.tierByKey,
    required this.eventId,
    required this.onReset,
  });

  final List<Seat> selectedSeats;
  final Map<String, EventTier> tierByKey;
  final String eventId;
  final VoidCallback onReset;

  int get _total =>
      selectedSeats.fold(0, (sum, s) => sum + (tierByKey[s.tierKey]?.priceIqd ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading = submitState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Review Seats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: selectedSeats.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = selectedSeats[i];
                  final tier = tierByKey[s.tierKey];
                  final tierName = tier != null
                      ? (tier.nameEn.isNotEmpty ? tier.nameEn : tier.nameAr)
                      : s.tierKey;
                  final price = tier?.priceIqd ?? 0;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Row ${s.row} · Seat ${s.seat}'),
                    subtitle: Text(tierName),
                    trailing: Text(
                      '${(price / 1000).toStringAsFixed(0)}k IQD',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(_total / 1000).toStringAsFixed(0)}k IQD',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      ref
                          .read(bookingSubmitProvider.notifier)
                          .createConcertBooking(
                            eventId: eventId,
                            seatIds:
                                selectedSeats.map((s) => s.seatId).toList(),
                          );
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Proceed to Pay'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment in-progress screen
// ---------------------------------------------------------------------------

class _PaymentInProgressView extends ConsumerWidget {
  const _PaymentInProgressView({
    required this.holdUntil,
    required this.eventId,
  });

  final String holdUntil;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (holdUntil.isNotEmpty) HoldCountdownBanner(holdUntil: holdUntil),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment_outlined, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Payment in progress...',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete the payment in your browser, then return here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.goNamed('bookingsHistory'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("I've completed payment"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.read(bookingSubmitProvider.notifier).reset();
                    ref.read(_concertSelectionProvider.notifier).reset();
                  },
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
