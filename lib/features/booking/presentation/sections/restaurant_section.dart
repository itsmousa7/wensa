import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/restaurant_seating_option.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_date_strip.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart' show bookingsRefreshProvider;
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Local state notifiers
// ---------------------------------------------------------------------------

class _RestaurantDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void set(DateTime d) => state = d;
}

class _RestaurantSlotNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? s) => state = s;
}

class _RestaurantPartySizeNotifier extends Notifier<int> {
  @override
  int build() => 2;
  void set(int n) => state = n;
}

class _RestaurantSeatingNotifier extends Notifier<RestaurantSeatingOption?> {
  @override
  RestaurantSeatingOption? build() => null;
  void set(RestaurantSeatingOption? o) => state = o;
}

final _restaurantSelectedDateProvider =
    NotifierProvider<_RestaurantDateNotifier, DateTime>(
        _RestaurantDateNotifier.new);

final _restaurantSelectedSlotProvider =
    NotifierProvider<_RestaurantSlotNotifier, String?>(
        _RestaurantSlotNotifier.new);

final _restaurantPartySizeProvider =
    NotifierProvider<_RestaurantPartySizeNotifier, int>(
        _RestaurantPartySizeNotifier.new);

final _restaurantSeatingOptionProvider =
    NotifierProvider<_RestaurantSeatingNotifier, RestaurantSeatingOption?>(
        _RestaurantSeatingNotifier.new);

// ---------------------------------------------------------------------------
// RestaurantSection
// ---------------------------------------------------------------------------

class RestaurantSection extends ConsumerWidget {
  const RestaurantSection({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(bookingSubmitProvider);

    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (_, __, ___, ____) {
          ref.read(bookingsRefreshProvider.notifier).bump();
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
      success: (bookingId, paymentUrl, holdUntil, waylReferenceId) =>
          const _RestaurantPendingView(),
      orElse: () => _RestaurantBookingFormView(
        placeId: placeId,
        placeName: placeName,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booking form
// ---------------------------------------------------------------------------

class _RestaurantBookingFormView extends ConsumerWidget {
  const _RestaurantBookingFormView({
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  /// Converts a UTC ISO string to Baghdad display time (UTC+3).
  String _slotDisplayTime(String isoUtc) {
    try {
      final utc = DateTime.parse(isoUtc);
      final baghdad = utc.add(const Duration(hours: 3));
      final h = baghdad.hour.toString().padLeft(2, '0');
      final m = baghdad.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return isoUtc;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(_restaurantSelectedDateProvider);
    final selectedSlot = ref.watch(_restaurantSelectedSlotProvider);
    final partySize = ref.watch(_restaurantPartySizeProvider);
    final selectedSeating = ref.watch(_restaurantSeatingOptionProvider);
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading =
        submitState.maybeWhen(loading: () => true, orElse: () => false);
    final seatingAsync = ref.watch(seatingOptionsProvider(placeId));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final closedDatesAsync = ref.watch(placeClosedDatesProvider(placeId));
    final closedDates = closedDatesAsync.value ?? const <String>{};
    final selectedDateStr = bookingFormatDate(selectedDate);
    final isSelectedDateClosed = closedDates.contains(selectedDateStr);

    final dateStr = bookingFormatDate(selectedDate);
    final slots = ref.watch(restaurantTimeSlotsProvider(dateStr));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Date strip ─────────────────────────────────────────────
          BookingSectionLabel(isAr ? 'اختر التاريخ' : 'Select Date'),
          BookingDateStrip(
            selected: selectedDate,
            closedDates: closedDates,
            onSelect: (date) {
              ref.read(_restaurantSelectedDateProvider.notifier).set(date);
              ref.read(_restaurantSelectedSlotProvider.notifier).set(null);
            },
          ),
          const SizedBox(height: 28),

          // ── Time slots ─────────────────────────────────────────────
          BookingSectionLabel(
            isAr
                ? 'اختر الوقت — ${bookingDisplayDate(selectedDate, isArabic: true)}'
                : 'Select Time — ${bookingDisplayDate(selectedDate)}',
          ),
          if (isSelectedDateClosed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _ClosedDay(),
            )
          else if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                isAr
                    ? 'لا توجد أوقات متاحة لهذا التاريخ.'
                    : 'No available times for this date.',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: slots.map((slot) {
                    final isSelected = selectedSlot == slot;
                    final slotTime = DateTime.tryParse(slot)?.toLocal();
                    final isExpired = slotTime != null && !slotTime.isAfter(DateTime.now());
                    final cs = Theme.of(context).colorScheme;
                    return ListTile(
                      title: Text(
                        _slotDisplayTime(slot),
                        style: TextStyle(
                          color: isExpired
                              ? cs.onSurface.withValues(alpha: 0.35)
                              : null,
                          decoration:
                              isExpired ? TextDecoration.lineThrough : null,
                          decorationColor: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                      trailing: isExpired
                          ? Text(
                              isAr ? 'منتهي' : 'Expired',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF92400E)
                                    .withValues(alpha: 0.75),
                              ),
                            )
                          : isSelected
                              ? Icon(Icons.check_circle,
                                  color: cs.primary)
                              : const Icon(Icons.radio_button_unchecked),
                      selected: isSelected && !isExpired,
                      enabled: !isExpired,
                      onTap: isExpired
                          ? null
                          : () {
                              ref
                                  .read(_restaurantSelectedSlotProvider.notifier)
                                  .set(isSelected ? null : slot);
                            },
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 28),

          // ── Party size ─────────────────────────────────────────────
          BookingSectionLabel(isAr ? 'عدد الضيوف' : 'Number of Guests'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'ضيوف' : 'Guests',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: partySize <= 1
                              ? null
                              : () => ref
                                  .read(_restaurantPartySizeProvider.notifier)
                                  .set(partySize - 1),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$partySize',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: partySize >= 20
                              ? null
                              : () => ref
                                  .read(_restaurantPartySizeProvider.notifier)
                                  .set(partySize + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Seating preference (optional) ──────────────────────────
          seatingAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (options) {
              if (options.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookingSectionLabel(
                      isAr ? 'تفضيل الجلوس' : 'Seating Preference'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.map((option) {
                        final label = isAr
                            ? (option.labelAr.isNotEmpty
                                ? option.labelAr
                                : option.labelEn)
                            : (option.labelEn.isNotEmpty
                                ? option.labelEn
                                : option.labelAr);
                        final isSelected = selectedSeating?.id == option.id;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(_restaurantSeatingOptionProvider.notifier)
                                .set(isSelected ? null : option);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              );
            },
          ),

          // ── Booking summary card (animated) ────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            ),
            child: selectedSlot != null
                ? Padding(
                    key: const ValueKey('summary-visible'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BookingSummaryCard(
                      title: isAr ? 'ملخص الحجز' : 'Booking Summary',
                      rows: [
                        BookingSummaryRow(
                          icon: Icons.calendar_today_rounded,
                          label: isAr ? 'التاريخ' : 'Date',
                          value: bookingDisplayDate(selectedDate,
                              isArabic: isAr),
                        ),
                        BookingSummaryRow(
                          icon: Icons.schedule_rounded,
                          label: isAr ? 'الوقت' : 'Time',
                          value: _slotDisplayTime(selectedSlot),
                        ),
                        BookingSummaryRow(
                          icon: Icons.people_rounded,
                          label: isAr ? 'الضيوف' : 'Guests',
                          value: isAr
                              ? '$partySize ${partySize == 1 ? 'ضيف' : 'ضيوف'}'
                              : '$partySize ${partySize == 1 ? 'guest' : 'guests'}',
                        ),
                        if (selectedSeating != null)
                          BookingSummaryRow(
                            icon: Icons.chair_rounded,
                            label: isAr ? 'الجلوس' : 'Seating',
                            value: isAr
                                ? (selectedSeating.labelAr.isNotEmpty
                                    ? selectedSeating.labelAr
                                    : selectedSeating.labelEn)
                                : (selectedSeating.labelEn.isNotEmpty
                                    ? selectedSeating.labelEn
                                    : selectedSeating.labelAr),
                          ),
                      ],
                      // No total — restaurant uses request-based booking
                      actionLabel: isAr ? 'طلب الحجز' : 'Request Booking',
                      onAction: () {
                        final slot = selectedSlot;
                        ref
                            .read(bookingSubmitProvider.notifier)
                            .createRestaurantBooking(
                              placeId: placeId,
                              startsAt: slot,
                              partySize: partySize,
                              seatingOptionId: selectedSeating?.id,
                            );
                      },
                      isLoading: isLoading,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('summary-hidden')),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending confirmation screen
// ---------------------------------------------------------------------------

class _RestaurantPendingView extends ConsumerWidget {
  const _RestaurantPendingView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            isAr ? 'تم إرسال طلب الحجز' : 'Booking Request Sent',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'بانتظار تأكيد التاجر. ستتلقى إشعاراً عند تأكيد الحجز أو رفضه.'
                : 'Waiting for merchant confirmation. You will receive a notification when your booking is confirmed or rejected.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () => context.go('/bookings'),
            icon: const Icon(Icons.list_alt_rounded),
            label: Text(isAr ? 'عرض حجوزاتي' : 'View My Bookings'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Closed day banner
// ---------------------------------------------------------------------------

class _ClosedDay extends StatelessWidget {
  const _ClosedDay();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(Icons.block_rounded,
              size: 36, color: cs.error.withValues(alpha: 0.45)),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'هذا المكان مغلق في هذا التاريخ.'
                : 'This place is closed on this date.',
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
