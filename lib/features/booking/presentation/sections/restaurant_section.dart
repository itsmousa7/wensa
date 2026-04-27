import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/restaurant_seating_option.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
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

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatDisplay(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  /// Converts a UTC ISO string back to local Baghdad time for display.
  String _slotDisplayTime(String isoUtc) {
    try {
      // Stored as UTC but represents Baghdad time (UTC+3), so add 3h.
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
    final isLoading = submitState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    final dateStr = _formatDate(selectedDate);
    final slots = ref.watch(restaurantTimeSlotsProvider(dateStr));
    final seatingAsync = ref.watch(seatingOptionsProvider(placeId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Step 1: Date picker ----
          Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              onDateChanged: (date) {
                ref.read(_restaurantSelectedDateProvider.notifier).set(date);
                ref.read(_restaurantSelectedSlotProvider.notifier).set(null);
              },
            ),
          ),
          const SizedBox(height: 24),

          // ---- Step 2: Time slot list ----
          Text(
            'Select Time — ${_formatDisplay(selectedDate)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (slots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No slots available for this date.'),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: slots.map((slot) {
                  final isSelected = selectedSlot == slot;
                  return ListTile(
                    title: Text(_slotDisplayTime(slot)),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : const Icon(Icons.radio_button_unchecked),
                    selected: isSelected,
                    onTap: () {
                      ref
                          .read(_restaurantSelectedSlotProvider.notifier)
                          .set(isSelected ? null : slot);
                    },
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),

          // ---- Step 3: Party-size stepper ----
          Text(
            'Party Size',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Number of guests',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: partySize <= 1
                            ? null
                            : () {
                                ref
                                    .read(_restaurantPartySizeProvider.notifier)
                                    .set(partySize - 1);
                              },
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
                            : () {
                                ref
                                    .read(_restaurantPartySizeProvider.notifier)
                                    .set(partySize + 1);
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ---- Step 4: Seating options (optional) ----
          seatingAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (options) {
              if (options.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seating Preference',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final label = option.labelEn.isNotEmpty
                          ? option.labelEn
                          : option.labelAr;
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
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // ---- Review + Request ----
          if (selectedSlot != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            _RestaurantReviewPanel(
              selectedDate: selectedDate,
              selectedSlot: selectedSlot,
              partySize: partySize,
              selectedSeating: selectedSeating,
              placeName: placeName,
              placeId: placeId,
              isLoading: isLoading,
              slotDisplayTime: _slotDisplayTime(selectedSlot),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review + Request panel
// ---------------------------------------------------------------------------

class _RestaurantReviewPanel extends ConsumerWidget {
  const _RestaurantReviewPanel({
    required this.selectedDate,
    required this.selectedSlot,
    required this.partySize,
    required this.selectedSeating,
    required this.placeName,
    required this.placeId,
    required this.isLoading,
    required this.slotDisplayTime,
  });

  final DateTime selectedDate;
  final String selectedSlot;
  final int partySize;
  final RestaurantSeatingOption? selectedSeating;
  final String placeName;
  final String placeId;
  final bool isLoading;
  final String slotDisplayTime;

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Booking Summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Place', value: placeName),
        _SummaryRow(label: 'Date', value: _formatDate(selectedDate)),
        _SummaryRow(label: 'Time', value: slotDisplayTime),
        _SummaryRow(
          label: 'Party Size',
          value: '$partySize guest${partySize > 1 ? 's' : ''}',
        ),
        if (selectedSeating != null)
          _SummaryRow(
            label: 'Seating',
            value: selectedSeating!.labelEn.isNotEmpty
                ? selectedSeating!.labelEn
                : selectedSeating!.labelAr,
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isLoading
              ? null
              : () {
                  ref
                      .read(bookingSubmitProvider.notifier)
                      .createRestaurantBooking(
                        placeId: placeId,
                        startsAt: selectedSlot,
                        partySize: partySize,
                        seatingOptionId: selectedSeating?.id,
                      );
                },
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Request Booking'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
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
            'Booking Request Sent',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Awaiting merchant confirmation. You'll receive a push notification when your booking is confirmed or rejected.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () => context.go('/bookings'),
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('View My Bookings'),
          ),
        ],
      ),
    );
  }
}
