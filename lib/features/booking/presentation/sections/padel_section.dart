import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/court.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/hold_countdown_banner.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/slot_grid.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Local state — using Notifier + NotifierProvider (riverpod 3.x compatible)
// ---------------------------------------------------------------------------

class _DateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void set(DateTime d) => state = d;
}

class _CourtNotifier extends Notifier<Court?> {
  @override
  Court? build() => null;
  void set(Court? c) => state = c;
}

class _SlotsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String startsAt) {
    final next = Set<String>.from(state);
    if (next.contains(startsAt)) {
      next.remove(startsAt);
    } else {
      next.add(startsAt);
    }
    state = next;
  }

  void clear() => state = {};
}

final _selectedDateProvider =
    NotifierProvider<_DateNotifier, DateTime>(_DateNotifier.new);

final _selectedCourtProvider =
    NotifierProvider<_CourtNotifier, Court?>(_CourtNotifier.new);

final _selectedSlotsProvider =
    NotifierProvider<_SlotsNotifier, Set<String>>(_SlotsNotifier.new);

// ---------------------------------------------------------------------------
// PadelSection
// ---------------------------------------------------------------------------

class PadelSection extends ConsumerWidget {
  const PadelSection({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(bookingSubmitProvider);

    // Listen for state changes and trigger side-effects.
    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil) async {
          final uri = Uri.parse(paymentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          _PaymentInProgressView(holdUntil: holdUntil, placeId: placeId),
      orElse: () => _BookingFormView(placeId: placeId),
    );
  }
}

// ---------------------------------------------------------------------------
// Booking form (steps 1–3)
// ---------------------------------------------------------------------------

class _BookingFormView extends ConsumerWidget {
  const _BookingFormView({required this.placeId});

  final String placeId;

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(_selectedDateProvider);
    final selectedCourt = ref.watch(_selectedCourtProvider);
    final selectedSlots = ref.watch(_selectedSlotsProvider);
    final courtsAsync = ref.watch(courtsProvider(placeId));
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading = submitState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    final slotsAsync = (selectedCourt != null)
        ? ref.watch(
            availableSlotsProvider(
              courtId: selectedCourt.id,
              date: _formatDate(selectedDate),
            ),
          )
        : null;

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
                ref.read(_selectedDateProvider.notifier).set(date);
                ref.read(_selectedSlotsProvider.notifier).clear();
              },
            ),
          ),
          const SizedBox(height: 24),

          // ---- Step 1: Court picker ----
          Text('Select Court', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          courtsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading courts: $e'),
            data: (courts) {
              if (courts.isEmpty) {
                return const Text('No courts available.');
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: courts.map((court) {
                    final isSelected = selectedCourt?.id == court.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          court.nameEn.isNotEmpty ? court.nameEn : court.nameAr,
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(_selectedCourtProvider.notifier).set(court);
                          ref.read(_selectedSlotsProvider.notifier).clear();
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ---- Step 2: Slot grid ----
          if (selectedCourt != null) ...[
            Text(
              'Available Slots — ${_formatDisplay(selectedDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (slotsAsync != null)
              slotsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading slots: $e'),
                data: (slots) {
                  if (slots.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No slots available for this date.'),
                    );
                  }
                  return SlotGrid(
                    slots: slots,
                    selectedStartTimes: selectedSlots,
                    onTap: (slot) {
                      ref
                          .read(_selectedSlotsProvider.notifier)
                          .toggle(slot.startsAt);
                    },
                  );
                },
              ),
            const SizedBox(height: 24),
          ],

          // ---- Step 3: Review + Pay ----
          if (selectedCourt != null && selectedSlots.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            _ReviewPanel(
              selectedDate: selectedDate,
              selectedCourt: selectedCourt,
              selectedSlots: selectedSlots,
              placeId: placeId,
              isLoading: isLoading,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review + Pay panel
// ---------------------------------------------------------------------------

class _ReviewPanel extends ConsumerWidget {
  const _ReviewPanel({
    required this.selectedDate,
    required this.selectedCourt,
    required this.selectedSlots,
    required this.placeId,
    required this.isLoading,
  });

  final DateTime selectedDate;
  final Court selectedCourt;
  final Set<String> selectedSlots;
  final String placeId;
  final bool isLoading;

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _timeLabel(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _earliestSlot() {
    final sorted = selectedSlots.toList()..sort();
    return sorted.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = selectedSlots.length;
    final sortedSlots = selectedSlots.toList()..sort();
    final timeFrom = _timeLabel(sortedSlots.first);
    final timeTo = _timeLabel(sortedSlots.last);
    final courtName = selectedCourt.nameEn.isNotEmpty
        ? selectedCourt.nameEn
        : selectedCourt.nameAr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Booking Summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Court', value: courtName),
        _SummaryRow(label: 'Date', value: _formatDate(selectedDate)),
        _SummaryRow(label: 'Time', value: '$timeFrom – $timeTo (+1h)'),
        _SummaryRow(
          label: 'Duration',
          value: '$hours hour${hours > 1 ? 's' : ''}',
        ),
        _SummaryRow(label: 'Total', value: 'Rate TBD'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isLoading
              ? null
              : () {
                  ref.read(bookingSubmitProvider.notifier).createPadelBooking(
                        placeId: placeId,
                        courtId: selectedCourt.id,
                        startsAt: _earliestSlot(),
                        hours: hours,
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
// Payment in-progress screen
// ---------------------------------------------------------------------------

class _PaymentInProgressView extends ConsumerWidget {
  const _PaymentInProgressView({
    required this.holdUntil,
    required this.placeId,
  });

  final String holdUntil;
  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        HoldCountdownBanner(holdUntil: holdUntil),
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
                    ref.read(_selectedSlotsProvider.notifier).clear();
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
