import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/event_tier.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_layout.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_section.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/pages/payment_webview_page.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/hold_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/hold_countdown_banner.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/seat_map_web_view.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart'
    show bookingsRefreshProvider;
import 'package:go_router/go_router.dart';

String _formatIqd(int amount) {
  final formatted = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'IQD $formatted';
}

/// Route name used for the concert review / GA checkout bottom sheets so
/// the parent listener can dismiss the right route once the Wayl payment
/// webview is ready to show — keeps the sheet visible while we wait on the
/// create-booking round trip.
const String _concertCheckoutSheetRoute = '_concert_checkout_sheet';

void _dismissCheckoutSheet(BuildContext context) {
  Navigator.of(context).popUntil(
    (route) => route.settings.name != _concertCheckoutSheetRoute,
  );
}

// ---------------------------------------------------------------------------
// Local state — concert selection (two-level: overview → section)
// ---------------------------------------------------------------------------

typedef _ConcertState = ({
  Set<String> selectedSeatIds,
  String? activeSectionId, // null = venue overview
  String? focusedSeatId, // last tapped — shown in the detail card
  String? holdUntil,
});

class _ConcertSelectionNotifier extends Notifier<_ConcertState> {
  @override
  _ConcertState build() => (
        selectedSeatIds: {},
        activeSectionId: null,
        focusedSeatId: null,
        holdUntil: null,
      );

  void openSection(String sectionId) => state = (
        selectedSeatIds: state.selectedSeatIds,
        activeSectionId: sectionId,
        focusedSeatId: state.focusedSeatId,
        holdUntil: state.holdUntil,
      );

  /// Open a section, or close it if it's already the active one. Lets the
  /// viewer's tap-the-same-tier-to-toggle UX flow back into Flutter state.
  void toggleSection(String sectionId) => state = (
        selectedSeatIds: state.selectedSeatIds,
        activeSectionId:
            state.activeSectionId == sectionId ? null : sectionId,
        focusedSeatId: state.focusedSeatId,
        holdUntil: state.holdUntil,
      );

  void closeSection() => state = (
        selectedSeatIds: state.selectedSeatIds,
        activeSectionId: null,
        focusedSeatId: state.focusedSeatId,
        holdUntil: state.holdUntil,
      );

  /// Returns `true` if the seat was added or removed, `false` if the tap was
  /// rejected (currently: tried to add a 5th seat when already at the 4-seat
  /// cap). Callers can use the return value to surface a snackbar.
  bool toggleSeat(Seat seat) {
    final selected = Set<String>.from(state.selectedSeatIds);
    String? focused = state.focusedSeatId;
    if (selected.contains(seat.seatId)) {
      selected.remove(seat.seatId);
      if (focused == seat.seatId) focused = selected.isEmpty ? null : selected.last;
    } else {
      if (selected.length >= 4) return false;
      selected.add(seat.seatId);
      focused = seat.seatId;
    }
    state = (
      selectedSeatIds: selected,
      activeSectionId: state.activeSectionId,
      focusedSeatId: focused,
      holdUntil: selected.isEmpty
          ? null
          : DateTime.now()
              .add(const Duration(seconds: 60))
              .toIso8601String(),
    );
    return true;
  }

  void reset() => state = (
        selectedSeatIds: {},
        activeSectionId: null,
        focusedSeatId: null,
        holdUntil: null,
      );
}

final _concertSelectionProvider =
    NotifierProvider<_ConcertSelectionNotifier, _ConcertState>(
  _ConcertSelectionNotifier.new,
);

// ---------------------------------------------------------------------------
// ConcertSection — payment listener wrapper
// ---------------------------------------------------------------------------

class ConcertSection extends ConsumerWidget {
  const ConcertSection({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (groupId, paymentUrl, holdUntil, waylReferenceId) {
          if (paymentUrl.isNotEmpty) {
            // The review / GA sheet stays open with its loading spinner
            // while create-booking runs; dismiss it now that we have the
            // Wayl URL so the webview lands cleanly on the booking page.
            _dismissCheckoutSheet(context);
            PaymentWebViewPage.push(
              context,
              paymentUrl,
              referenceId: waylReferenceId,
              redirectionUrl: 'wansa://payment',
              onPaymentSuccess: (_, orderId) async {
                // Flip every row in the concert group to confirmed before
                // the cron can expire it — same backstop as padel/farm in
                // case the Wayl webhook is delayed.
                String? firstBookingId;
                try {
                  firstBookingId = await ref
                      .read(bookingRepositoryProvider)
                      .confirmConcertGroupPayment(groupId, orderId);
                } catch (_) {}
                ref.read(bookingSubmitProvider.notifier).reset();
                ref.read(_concertSelectionProvider.notifier).reset();
                ref.read(bookingsRefreshProvider.notifier).bump();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Payment successful! Your tickets are confirmed.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  if (firstBookingId != null && firstBookingId.isNotEmpty) {
                    context.go('/bookings/$firstBookingId');
                  } else {
                    context.goNamed('bookingsHistory');
                  }
                }
              },
              onPaymentFailed: () {
                ref.read(bookingSubmitProvider.notifier).reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment failed. Please try again.'),
                    backgroundColor: Color(0xFFE53935),
                  ),
                );
              },
              onPaymentCancelled: () async {
                // Await the server-side cancel before releasing the Proceed
                // button — otherwise the next tap races the still-`pending`
                // concert group and hits a seat-hold or overlap conflict.
                await ref
                    .read(bookingSubmitProvider.notifier)
                    .cancelPending();
                ref.invalidate(availableSeatsProvider(eventId));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment cancelled.')),
                );
              },
            );
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

    return _ConcertBookingView(eventId: eventId);
  }
}

// ---------------------------------------------------------------------------
// Main booking view — overview ⇄ section drill-in
// ---------------------------------------------------------------------------

class _ConcertBookingView extends ConsumerStatefulWidget {
  const _ConcertBookingView({required this.eventId});

  final String eventId;

  @override
  ConsumerState<_ConcertBookingView> createState() =>
      _ConcertBookingViewState();
}

class _ConcertBookingViewState extends ConsumerState<_ConcertBookingView> {
  final GlobalKey<SeatMapWebViewState> _viewerKey =
      GlobalKey<SeatMapWebViewState>();

  void _pushSelectionToViewer() {
    final ids = ref.read(_concertSelectionProvider).selectedSeatIds.toList();
    _viewerKey.currentState?.setSelectedSeats(ids);
  }

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(venueLayoutProvider(widget.eventId));
    final tiersAsync = ref.watch(eventTiersProvider(widget.eventId));
    final seatsAsync = ref.watch(availableSeatsProvider(widget.eventId));
    final selection = ref.watch(_concertSelectionProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return layoutAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading venue: $e')),
      data: (layout) {
        if (layout.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                isAr
                    ? 'لا توجد خريطة مقاعد لهذا الحدث بعد.'
                    : 'No seat map is configured for this event yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        final tiers = tiersAsync.value ?? const <EventTier>[];
        final tierByKey = {for (final t in tiers) t.tierKey: t};
        final seats = seatsAsync.value ?? const <Seat>[];

        final selectedSeats = seats
            .where((s) => selection.selectedSeatIds.contains(s.seatId))
            .toList();

        final holdBanner = selection.holdUntil != null
            ? _HoldBannerWithExpiry(
                holdUntil: selection.holdUntil!,
                onExpired: () {
                  ref.read(_concertSelectionProvider.notifier).reset();
                  _viewerKey.currentState?.reload();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Your seat hold has expired. Please select again.',
                        ),
                      ),
                    );
                  }
                },
              )
            : const SizedBox.shrink();

        return Stack(
          children: [
            // The dashboard-identical SVG map, served from a bundled HTML
            // viewer. Owns pan / pinch / drill-in entirely.
            Positioned.fill(
              child: SeatMapWebView(
                key: _viewerKey,
                eventId: widget.eventId,
                onSectionTap: (event) {
                  if (event.isGeneralAdmission) {
                    final section = layout.sections
                        .where((s) => s.id == event.sectionId)
                        .firstOrNull;
                    if (section != null) {
                      _showGASheet(
                        context,
                        ref,
                        section: section,
                        tierByKey: tierByKey,
                      );
                    }
                  } else {
                    final notifier =
                        ref.read(_concertSelectionProvider.notifier);
                    final wasActive = ref
                            .read(_concertSelectionProvider)
                            .activeSectionId ==
                        event.sectionId;
                    notifier.toggleSection(event.sectionId);
                    // Mirror the new state into the viewer so it can collapse
                    // the drill-in / zoom-out when the user re-taps the tier.
                    _viewerKey.currentState
                        ?.openSection(wasActive ? null : event.sectionId);
                  }
                },
                onSeatTap: (event) {
                  final seat = seats
                      .where((s) => s.seatId == event.seatId)
                      .firstOrNull;
                  if (seat == null) return;
                  if (seat.status != SeatStatus.free) return;
                  final added = ref
                      .read(_concertSelectionProvider.notifier)
                      .toggleSeat(seat);
                  if (!added) {
                    final isAr = Localizations.localeOf(context).languageCode == 'ar';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr
                              ? 'يمكنك اختيار ٤ مقاعد كحد أقصى لكل حجز.'
                              : 'You can select up to 4 seats per booking.',
                        ),
                      ),
                    );
                    return;
                  }
                  _pushSelectionToViewer();
                },
                onBack: () => ref
                    .read(_concertSelectionProvider.notifier)
                    .closeSection(),
              ),
            ),

            // Hold-expiry banner (top)
            if (selection.holdUntil != null)
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(bottom: false, child: holdBanner),
              ),

            // Selection summary + Review CTA (bottom)
            if (selectedSeats.isNotEmpty)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _SelectionBar(
                  selectedSeats: selectedSeats,
                  tierByKey: tierByKey,
                  onReview: () => _showReviewSheet(
                    context,
                    ref,
                    selectedSeats: selectedSeats,
                    tierByKey: tierByKey,
                  ),
                  onClear: () {
                    ref.read(_concertSelectionProvider.notifier).reset();
                    _pushSelectionToViewer();
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showReviewSheet(
    BuildContext context,
    WidgetRef ref, {
    required List<Seat> selectedSeats,
    required Map<String, EventTier> tierByKey,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      routeSettings: const RouteSettings(name: _concertCheckoutSheetRoute),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewSheet(
        selectedSeats: selectedSeats,
        tierByKey: tierByKey,
        eventId: widget.eventId,
      ),
    );
  }

  void _showGASheet(
    BuildContext context,
    WidgetRef ref, {
    required VenueSection section,
    required Map<String, EventTier> tierByKey,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      routeSettings: const RouteSettings(name: _concertCheckoutSheetRoute),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GASheet(
        eventId: widget.eventId,
        section: section,
        tier: tierByKey[section.tierKey],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selection summary bar — bottom-anchored, shown while seats are selected
// ---------------------------------------------------------------------------

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.selectedSeats,
    required this.tierByKey,
    required this.onReview,
    required this.onClear,
  });

  final List<Seat> selectedSeats;
  final Map<String, EventTier> tierByKey;
  final VoidCallback onReview;
  final VoidCallback onClear;

  int _priceOf(Seat s) =>
      s.priceIqd > 0 ? s.priceIqd : (tierByKey[s.tierKey]?.priceIqd ?? 0);

  int get _total => selectedSeats.fold(0, (sum, s) => sum + _priceOf(s));

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    return Material(
      elevation: 12,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClear,
              tooltip: isAr ? 'مسح' : 'Clear',
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAr
                        ? '${selectedSeats.length} مقعد محدد'
                        : '${selectedSeats.length} seat${selectedSeats.length == 1 ? '' : 's'} selected',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _total > 0 ? _formatIqd(_total) : '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onReview,
              child: Text(isAr ? 'مراجعة' : 'Review'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hold banner that fires a callback when the timer reaches 0
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
      WidgetsBinding.instance.addPostFrameCallback((_) => onExpired());
    }
    return HoldCountdownBanner(holdUntil: holdUntil);
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
  });

  final List<Seat> selectedSeats;
  final Map<String, EventTier> tierByKey;
  final String eventId;

  int _priceOf(Seat s) =>
      s.priceIqd > 0 ? s.priceIqd : (tierByKey[s.tierKey]?.priceIqd ?? 0);

  int get _total => selectedSeats.fold(0, (sum, s) => sum + _priceOf(s));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading = submitState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

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
              isAr ? 'مراجعة المقاعد' : 'Review Seats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: selectedSeats.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = selectedSeats[i];
                  final tier = tierByKey[s.tierKey];
                  final tierName = tier != null
                      ? (isAr
                          ? (tier.nameAr.isNotEmpty
                              ? tier.nameAr
                              : tier.nameEn)
                          : (tier.nameEn.isNotEmpty
                              ? tier.nameEn
                              : tier.nameAr))
                      : s.tierKey;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      isAr
                          ? 'صف ${s.row} · مقعد ${s.seat}'
                          : 'Row ${s.row} · Seat ${s.seat}',
                    ),
                    subtitle: Text(tierName),
                    trailing: Text(
                      _formatIqd(_priceOf(s)),
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
                    isAr ? 'الإجمالي' : 'Total',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _formatIqd(_total),
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
              onPressed: isLoading || selectedSeats.isEmpty
                  ? null
                  : () {
                      // Keep the sheet visible while create-booking runs.
                      // The parent listener pops it once the Wayl URL is
                      // ready (see `_dismissCheckoutSheet`).
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
                  : Text(isAr ? 'المتابعة للدفع' : 'Proceed to Payment'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// General Admission bottom sheet — quantity picker + buy CTA
// ---------------------------------------------------------------------------

class _GASheet extends ConsumerStatefulWidget {
  const _GASheet({
    required this.eventId,
    required this.section,
    required this.tier,
  });

  final String eventId;
  final VenueSection section;
  final EventTier? tier;

  @override
  ConsumerState<_GASheet> createState() => _GASheetState();
}

class _GASheetState extends ConsumerState<_GASheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == "ar";
    final remaining = widget.section.freeCount;
    final price = widget.section.priceIqd;
    final tier = widget.tier;
    final tierName = tier != null
        ? (isAr
            ? (tier.nameAr.isNotEmpty ? tier.nameAr : tier.nameEn)
            : (tier.nameEn.isNotEmpty ? tier.nameEn : tier.nameAr))
        : widget.section.tierKey;
    final maxQty = remaining > 10 ? 10 : remaining;
    final total = price * _quantity;
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading = submitState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              isAr
                  ? (widget.section.nameAr.isNotEmpty
                      ? widget.section.nameAr
                      : widget.section.nameEn)
                  : (widget.section.nameEn.isNotEmpty
                      ? widget.section.nameEn
                      : widget.section.nameAr),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              isAr ? "مقاعد عامة — الجلوس حر" : "General admission — open seating",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tierName, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    price > 0
                        ? _formatIqd(price)
                        : (isAr ? "السعر قيد التحديد" : "Price TBD"),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? "الكمية" : "Quantity",
                    style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "$_quantity",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: _quantity < maxQty
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                isAr
                    ? "$remaining تذكرة متاحة"
                    : "$remaining tickets remaining",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? "الإجمالي" : "Total",
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    total > 0 ? _formatIqd(total) : "—",
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
              onPressed: isLoading || remaining <= 0 || price <= 0
                  ? null
                  : () {
                      // Keep the sheet visible until the parent's listener
                      // dismisses it once the Wayl URL is available.
                      ref
                          .read(bookingSubmitProvider.notifier)
                          .createGeneralAdmissionBooking(
                            eventId: widget.eventId,
                            sectionId: widget.section.id,
                            quantity: _quantity,
                          );
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isAr ? "متابعة للدفع" : "Proceed to Payment"),
            ),
            if (price <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  isAr
                      ? "لم يتم تحديد السعر لهذه المنطقة بعد. تواصل مع الإدارة."
                      : "Price has not been configured for this zone yet.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

