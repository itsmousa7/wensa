import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/hold_countdown_banner.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/shift_card.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Local state notifiers
// ---------------------------------------------------------------------------

class _FarmDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void set(DateTime d) => state = d;
}

class _FarmShiftNotifier extends Notifier<FarmShift?> {
  @override
  FarmShift? build() => null;
  void set(FarmShift? s) => state = s;
}

final _farmSelectedDateProvider =
    NotifierProvider<_FarmDateNotifier, DateTime>(_FarmDateNotifier.new);

final _farmSelectedShiftProvider =
    NotifierProvider<_FarmShiftNotifier, FarmShift?>(_FarmShiftNotifier.new);

// ---------------------------------------------------------------------------
// FarmSection
// ---------------------------------------------------------------------------

class FarmSection extends ConsumerWidget {
  const FarmSection({
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
          _FarmPaymentInProgressView(holdUntil: holdUntil),
      orElse: () => _FarmBookingFormView(
        placeId: placeId,
        placeName: placeName,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booking form
// ---------------------------------------------------------------------------

class _FarmBookingFormView extends ConsumerWidget {
  const _FarmBookingFormView({
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

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
    final selectedDate = ref.watch(_farmSelectedDateProvider);
    final selectedShift = ref.watch(_farmSelectedShiftProvider);
    final shiftsAsync = ref.watch(farmShiftsProvider(placeId));
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading = submitState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

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
                ref.read(_farmSelectedDateProvider.notifier).set(date);
                ref.read(_farmSelectedShiftProvider.notifier).set(null);
              },
            ),
          ),
          const SizedBox(height: 24),

          // ---- Step 2: Shift picker ----
          Text(
            'Select Shift — ${_formatDisplay(selectedDate)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          shiftsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading shifts: $e'),
            data: (shifts) {
              if (shifts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No shifts available for this place.'),
                );
              }
              return Column(
                children: shifts.map((shift) {
                  final isSelected =
                      selectedShift?.shiftType == shift.shiftType;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShiftCard(
                      shift: shift,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(_farmSelectedShiftProvider.notifier)
                            .set(isSelected ? null : shift);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),

          // ---- Step 3: Review + Pay ----
          if (selectedShift != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            _FarmReviewPanel(
              selectedDate: selectedDate,
              selectedShift: selectedShift,
              placeName: placeName,
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

class _FarmReviewPanel extends ConsumerWidget {
  const _FarmReviewPanel({
    required this.selectedDate,
    required this.selectedShift,
    required this.placeName,
    required this.placeId,
    required this.isLoading,
  });

  final DateTime selectedDate;
  final FarmShift selectedShift;
  final String placeName;
  final String placeId;
  final bool isLoading;

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _shiftLabel(FarmShiftType type) {
    switch (type) {
      case FarmShiftType.day:
        return 'Day';
      case FarmShiftType.night:
        return 'Night';
      case FarmShiftType.full:
        return 'Full Day';
    }
  }

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
        _SummaryRow(
          label: 'Shift',
          value: _shiftLabel(selectedShift.shiftType),
        ),
        _SummaryRow(
          label: 'Time',
          value: '${selectedShift.startsTime} – ${selectedShift.endsTime}',
        ),
        _SummaryRow(
          label: 'Total',
          value: '${selectedShift.priceIqd} IQD',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isLoading
              ? null
              : () {
                  ref.read(bookingSubmitProvider.notifier).createFarmBooking(
                        placeId: placeId,
                        date: _formatDate(selectedDate),
                        shiftType: selectedShift.shiftType,
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

class _FarmPaymentInProgressView extends ConsumerWidget {
  const _FarmPaymentInProgressView({required this.holdUntil});

  final String holdUntil;

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
                    ref.read(_farmSelectedShiftProvider.notifier).set(null);
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
