import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_date_strip.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/shift_card.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/pages/payment_webview_page.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart' show bookingsRefreshProvider;
import 'package:go_router/go_router.dart';

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
    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil, waylReferenceId) {
          if (paymentUrl.isNotEmpty) {
            PaymentWebViewPage.push(
              context,
              paymentUrl,
              referenceId: waylReferenceId,
              redirectionUrl: 'wansa://payment',
              onPaymentSuccess: (_, orderId) async {
                try {
                  await ref
                      .read(bookingRepositoryProvider)
                      .confirmPayment(bookingId, orderId);
                } catch (_) {}
                ref.read(bookingSubmitProvider.notifier).reset();
                ref.read(bookingsRefreshProvider.notifier).bump();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment successful! Your booking is confirmed.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.go('/bookings/$bookingId');
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
              onPaymentCancelled: () {
                ref.read(bookingSubmitProvider.notifier).reset();
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

    return _FarmBookingFormView(placeId: placeId, placeName: placeName);
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

  static String _shiftLabel(FarmShiftType type, {bool isArabic = false}) {
    if (isArabic) {
      switch (type) {
        case FarmShiftType.day:
          return 'نهار';
        case FarmShiftType.night:
          return 'ليل';
        case FarmShiftType.full:
          return 'يوم كامل';
      }
    }
    switch (type) {
      case FarmShiftType.day:
        return 'Day';
      case FarmShiftType.night:
        return 'Night';
      case FarmShiftType.full:
        return 'Full Day';
    }
  }

  static String _formatPrice(int priceIqd) {
    final formatted = priceIqd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'IQD $formatted';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(_farmSelectedDateProvider);
    final selectedShift = ref.watch(_farmSelectedShiftProvider);
    final shiftsAsync = ref.watch(farmShiftsProvider(placeId));
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading =
        submitState.maybeWhen(loading: () => true, orElse: () => false);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Date strip ─────────────────────────────────────────────
          BookingSectionLabel(isAr ? 'اختر التاريخ' : 'Select Date'),
          BookingDateStrip(
            selected: selectedDate,
            onSelect: (date) {
              ref.read(_farmSelectedDateProvider.notifier).set(date);
              ref.read(_farmSelectedShiftProvider.notifier).set(null);
            },
          ),
          const SizedBox(height: 28),

          // ── Shift picker ───────────────────────────────────────────
          BookingSectionLabel(
            isAr
                ? 'اختر الوردية — ${bookingDisplayDate(selectedDate, isArabic: true)}'
                : 'Select Shift — ${bookingDisplayDate(selectedDate)}',
          ),
          shiftsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Error loading shifts: $e'),
            ),
            data: (shifts) {
              if (shifts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Text(
                    isAr
                        ? 'لا توجد أوردية متاحة لهذا الموقع.'
                        : 'No shifts available for this location.',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5)),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: shifts.map((shift) {
                    final isSelected =
                        selectedShift?.shiftType == shift.shiftType;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ShiftCard(
                        shift: shift,
                        isSelected: isSelected,
                        isBooked: false,
                        onTap: () {
                          ref
                              .read(_farmSelectedShiftProvider.notifier)
                              .set(isSelected ? null : shift);
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

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
            child: selectedShift != null
                ? Padding(
                    key: const ValueKey('summary-visible'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BookingSummaryCard(
                      title: isAr ? 'ملخص الحجز' : 'Booking Summary',
                      badgeText: _shiftLabel(selectedShift.shiftType,
                          isArabic: isAr),
                      rows: [
                        BookingSummaryRow(
                          icon: Icons.calendar_today_rounded,
                          label: isAr ? 'التاريخ' : 'Date',
                          value: bookingDisplayDate(selectedDate,
                              isArabic: isAr),
                        ),
                        BookingSummaryRow(
                          icon: Icons.wb_sunny_rounded,
                          label: isAr ? 'الوردية' : 'Shift',
                          value: _shiftLabel(selectedShift.shiftType,
                              isArabic: isAr),
                        ),
                        BookingSummaryRow(
                          icon: Icons.schedule_rounded,
                          label: isAr ? 'الوقت' : 'Time',
                          value:
                              '${selectedShift.startsTime} – ${selectedShift.endsTime}',
                        ),
                      ],
                      totalLabel: isAr ? 'الإجمالي' : 'Total Amount',
                      totalValue: _formatPrice(selectedShift.priceIqd),
                      actionLabel:
                          isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
                      onAction: () {
                        final shift = selectedShift;
                        ref
                            .read(bookingSubmitProvider.notifier)
                            .createFarmBooking(
                              placeId: placeId,
                              date: bookingFormatDate(selectedDate),
                              shiftType: shift.shiftType,
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
