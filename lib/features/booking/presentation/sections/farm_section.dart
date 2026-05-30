import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/slot_availability.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_date_strip.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/shift_card.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/pages/payment_webview_page.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart' show bookingsRefreshProvider;
import 'package:future_riverpod/features/discounts/domain/discount_math.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/widgets/promo_code_field.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
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
    NotifierProvider.autoDispose<_FarmDateNotifier, DateTime>(
        _FarmDateNotifier.new);

final _farmSelectedShiftProvider =
    NotifierProvider.autoDispose<_FarmShiftNotifier, FarmShift?>(
        _FarmShiftNotifier.new);

final _farmPromoProvider =
    NotifierProvider.autoDispose<_FarmPromoNotifier, PromoApplied?>(
        _FarmPromoNotifier.new);

class _FarmPromoNotifier extends Notifier<PromoApplied?> {
  @override
  PromoApplied? build() => null;
  void set(PromoApplied? p) => state = p;
}

/// Computes [SlotAvailability] for a farm shift.
/// [isToday] must be true when the selected date is today (local device date).
/// Uses Baghdad time (UTC+3) for expiry comparison since farm shifts are
/// configured in local Baghdad time.
SlotAvailability computeShiftAvailability(FarmShift shift, {required bool isToday}) {
  if (shift.isClosed) return SlotAvailability.closed;
  if (isToday) {
    final parts = shift.startsTime.split(':');
    if (parts.length >= 2) {
      assert(
        int.tryParse(parts[0]) != null && int.tryParse(parts[1]) != null,
        'FarmShift.startsTime has unexpected format: "${shift.startsTime}"',
      );
      final baghdadNow = DateTime.now().toUtc().add(const Duration(hours: 3));
      final shiftStart = DateTime(
        baghdadNow.year,
        baghdadNow.month,
        baghdadNow.day,
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
      );
      if (!shiftStart.isAfter(baghdadNow)) return SlotAvailability.expired;
    }
  }
  if (!shift.isAvailable) return SlotAvailability.booked;
  return SlotAvailability.available;
}

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

  static String _toTime12h(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  static String _formatIqd(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'IQD $formatted';
  }

  static ({int discount, int finalAmount, String label}) _resolveEffective({
    required int subtotal,
    required PromoApplied? promo,
    required AutoDiscount? autoDiscount,
  }) {
    if (promo != null) {
      return (
        discount: promo.discountAmount,
        finalAmount: promo.finalAmount,
        label: '${promo.percent.round()}% OFF · ${promo.code}',
      );
    }
    if (autoDiscount != null) {
      final r = computeDiscount(
        subtotal: subtotal,
        percent: autoDiscount.percent,
        maxCap: autoDiscount.maxDiscountAmount,
      );
      return (
        discount: r.discountAmount,
        finalAmount: r.finalAmount,
        label: '${autoDiscount.percent.round()}% OFF',
      );
    }
    return (discount: 0, finalAmount: subtotal, label: '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(_farmSelectedDateProvider);
    final selectedShift = ref.watch(_farmSelectedShiftProvider);
    final shiftsAsync = ref.watch(
      farmShiftsProvider(placeId, bookingFormatDate(selectedDate)),
    );
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading =
        submitState.maybeWhen(loading: () => true, orElse: () => false);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final closedDatesAsync = ref.watch(placeClosedDatesProvider(placeId));
    final closedDates = closedDatesAsync.value ?? const <String>{};

    final placeAsync = ref.watch(placeDetailsProvider(placeId));
    final place = placeAsync.value;
    final autoDiscount = ref.watch(bestAutoDiscountProvider(AutoDiscountKey(
      orderType: 'bookings',
      placeId: placeId,
      merchantId: place?.merchantId,
      categoryId: place?.categoryId,
    )));
    final promo = ref.watch(_farmPromoProvider);

    // Opens the payment webview for the given booking details.
    // Defined here so it can be reused by both ref.listen and onAction.
    void openPaymentWebView(
        String bookingId, String paymentUrl, String waylReferenceId) {
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
          ref.invalidate(userPurchaseHistoryProvider);
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
        onPaymentFailed: () async {
          // Release the pending row so the shift frees up immediately instead
          // of staying "booked" until the expiry cron. The shift is only ever
          // held by a confirmed (paid) booking.
          await ref.read(bookingSubmitProvider.notifier).cancelPending();
          ref.invalidate(
              farmShiftsProvider(placeId, bookingFormatDate(selectedDate)));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Please try again.'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        },
        onPaymentCancelled: () async {
          // Release the pending row server-side the moment the user closes the
          // webview, so the shift becomes available again right away (no hot
          // restart, no waiting on the expiry cron). cancelPending() reads the
          // booking id from the success state, cancels via cancel_booking, then
          // resets local state to idle — which also re-enables Proceed only
          // after the row is gone, so a retry can't race the stale pending row.
          await ref.read(bookingSubmitProvider.notifier).cancelPending();
          ref.invalidate(
              farmShiftsProvider(placeId, bookingFormatDate(selectedDate)));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled.')),
          );
        },
      );
    }

    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil, waylReferenceId) {
          if (paymentUrl.isNotEmpty) {
            openPaymentWebView(bookingId, paymentUrl, waylReferenceId);
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
              ref.read(_farmSelectedDateProvider.notifier).set(date);
              ref.read(_farmSelectedShiftProvider.notifier).set(null);
              // Release any pending booking row server-side so the next
              // Proceed doesn't collide with it.
              ref.read(bookingSubmitProvider.notifier).cancelPending();
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
              final baghdadNow = DateTime.now().toUtc().add(const Duration(hours: 3));
              final isToday = selectedDate.year == baghdadNow.year &&
                  selectedDate.month == baghdadNow.month &&
                  selectedDate.day == baghdadNow.day;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: shifts.map((shift) {
                    final isSelected =
                        selectedShift?.shiftType == shift.shiftType;
                    final availability =
                        computeShiftAvailability(shift, isToday: isToday);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ShiftCard(
                        shift: shift,
                        isSelected: isSelected,
                        availability: availability,
                        onTap: () {
                          ref
                              .read(_farmSelectedShiftProvider.notifier)
                              .set(isSelected ? null : shift);
                          // Release any pending booking row server-side.
                          ref
                              .read(bookingSubmitProvider.notifier)
                              .cancelPending();
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
                ? Builder(
                    key: const ValueKey('summary-visible'),
                    builder: (context) {
                      final subtotal = selectedShift.priceIqd;
                      final eff = _FarmBookingFormView._resolveEffective(
                        subtotal: subtotal,
                        promo: promo,
                        autoDiscount: autoDiscount,
                      );

                      // Re-validate promo on subtotal change.
                      if (promo != null &&
                          promo.finalAmount + promo.discountAmount != subtotal) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(_farmPromoProvider.notifier).set(null);
                        });
                      }

                      return Padding(
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
                                  '${_toTime12h(selectedShift.startsTime)} – ${_toTime12h(selectedShift.endsTime)}',
                            ),
                          ],
                          subtotalLabel: isAr ? 'المجموع' : 'Subtotal',
                          subtotalValue: eff.discount > 0
                              ? _FarmBookingFormView._formatIqd(subtotal)
                              : null,
                          discountLabel: eff.discount > 0 ? eff.label : null,
                          discountValue: eff.discount > 0
                              ? '−${_FarmBookingFormView._formatIqd(eff.discount)}'
                              : null,
                          totalLabel: isAr ? 'الإجمالي' : 'Total Amount',
                          totalValue:
                              _FarmBookingFormView._formatIqd(eff.finalAmount),
                          extraSlot: subtotal > 0
                              ? PromoCodeField(
                                  orderType: 'bookings',
                                  subtotal: subtotal,
                                  placeId: placeId,
                                  merchantId: place?.merchantId,
                                  categoryId: place?.categoryId,
                                  applied: promo,
                                  isAr: isAr,
                                  onChange: (p) => ref
                                      .read(_farmPromoProvider.notifier)
                                      .set(p),
                                )
                              : null,
                          actionLabel:
                              isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
                          onAction: () {
                            // If a pending booking already exists, reuse its payment URL
                            // instead of creating a new booking (avoids DB constraint error).
                            final current = ref.read(bookingSubmitProvider);
                            current.maybeWhen(
                              success: (bookingId, paymentUrl, holdUntil,
                                  waylReferenceId) {
                                if (paymentUrl.isNotEmpty) {
                                  openPaymentWebView(
                                      bookingId, paymentUrl, waylReferenceId);
                                }
                              },
                              orElse: () {
                                final shift = selectedShift;
                                ref
                                    .read(bookingSubmitProvider.notifier)
                                    .createFarmBooking(
                                      placeId: placeId,
                                      date: bookingFormatDate(selectedDate),
                                      shiftType: shift.shiftType,
                                      promoCode: promo?.code,
                                    );
                              },
                            );
                          },
                          isLoading: isLoading,
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('summary-hidden')),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
