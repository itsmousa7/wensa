import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/court.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/pages/payment_webview_page.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/bilingual_label.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_date_strip.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/slot_grid.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart'
    show bookingsRefreshProvider;
import 'package:future_riverpod/features/discounts/domain/discount_math.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/domain/models/merchant_discount.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/widgets/promo_code_field.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Local state
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
    NotifierProvider.autoDispose<_DateNotifier, DateTime>(_DateNotifier.new);
final _selectedCourtProvider =
    NotifierProvider.autoDispose<_CourtNotifier, Court?>(_CourtNotifier.new);
final _selectedSlotsProvider =
    NotifierProvider.autoDispose<_SlotsNotifier, Set<String>>(
        _SlotsNotifier.new);

final _padelPromoProvider =
    NotifierProvider.autoDispose<_PadelPromoNotifier, PromoApplied?>(
        _PadelPromoNotifier.new);

class _PadelPromoNotifier extends Notifier<PromoApplied?> {
  @override
  PromoApplied? build() => null;
  void set(PromoApplied? p) => state = p;
}

// ---------------------------------------------------------------------------
// PadelSection
// ---------------------------------------------------------------------------

class PadelSection extends ConsumerWidget {
  const PadelSection({super.key, required this.placeId});
  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BookingFormView(placeId: placeId);
  }
}

// ---------------------------------------------------------------------------
// Booking form
// ---------------------------------------------------------------------------

class _BookingFormView extends ConsumerWidget {
  const _BookingFormView({required this.placeId});
  final String placeId;

  static String _timeLabel(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  static String _timeRange(Set<String> selectedSlots) {
    final sorted = selectedSlots.toList()..sort();
    try {
      final startDt = DateTime.parse(sorted.first).toLocal();
      final hours = selectedSlots.length;
      final endDt = startDt.add(Duration(hours: hours));
      return '${_timeLabel(startDt)} – ${_timeLabel(endDt)} (${hours}h)';
    } catch (_) {
      return '';
    }
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
    int merchantHourlyAmount = 0,
    String merchantHourlyLabel = '',
  }) {
    // Promo stacks on top of the merchant hourly discount. The promo widget
    // validates against `subtotal - merchantHourlyAmount`, so promo.finalAmount
    // is already the post-stack total — anything else is the combined discount.
    if (promo != null) {
      final totalDiscount = subtotal - promo.finalAmount;
      final label = merchantHourlyAmount > 0
          ? '$merchantHourlyLabel + ${promo.percent.round()}% · ${promo.code}'
          : '${promo.percent.round()}% OFF · ${promo.code}';
      return (
        discount: totalDiscount,
        finalAmount: promo.finalAmount,
        label: label,
      );
    }
    int autoAmt = 0;
    String autoLabel = '';
    if (autoDiscount != null) {
      final r = computeDiscount(
        subtotal: subtotal,
        percent: autoDiscount.percent,
        maxCap: autoDiscount.maxDiscountAmount,
      );
      autoAmt = r.discountAmount;
      autoLabel = '${autoDiscount.percent.round()}% OFF';
    }
    if (merchantHourlyAmount > 0 && merchantHourlyAmount >= autoAmt) {
      return (
        discount: merchantHourlyAmount,
        finalAmount: subtotal - merchantHourlyAmount,
        label: merchantHourlyLabel,
      );
    }
    if (autoAmt > 0) {
      return (
        discount: autoAmt,
        finalAmount: subtotal - autoAmt,
        label: autoLabel,
      );
    }
    return (discount: 0, finalAmount: subtotal, label: '');
  }

  static ({int amount, String label}) _computeMerchantHourly({
    required MerchantDiscount? discount,
    required Set<String> slots,
    required int pricePerHour,
    required int subtotal,
  }) {
    if (discount == null || slots.isEmpty || pricePerHour <= 0) {
      return (amount: 0, label: '');
    }
    if (!discount.isCurrentlyActive()) return (amount: 0, label: '');
    var discountedHours = 0;
    for (final s in slots) {
      try {
        final dt = DateTime.parse(s).toLocal();
        if (!discount.appliesOnDate(dt)) continue;
        if (discount.appliesAtHour(dt.hour)) discountedHours++;
      } catch (_) {}
    }
    if (discountedHours == 0) return (amount: 0, label: '');
    var amt =
        (pricePerHour * discountedHours * discount.percent / 100).round();
    final cap = discount.maxDiscountAmount;
    if (cap != null && amt > cap) amt = cap.round();
    if (amt > subtotal) amt = subtotal;
    return (amount: amt, label: '${discount.percent.round()}% OFF');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(_selectedDateProvider);
    final selectedCourt = ref.watch(_selectedCourtProvider);
    final selectedSlots = ref.watch(_selectedSlotsProvider);
    final courtsAsync = ref.watch(courtsProvider(placeId));
    final submitState = ref.watch(bookingSubmitProvider);
    final isLoading =
        submitState.maybeWhen(loading: () => true, orElse: () => false);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final closedDatesAsync = ref.watch(placeClosedDatesProvider(placeId));
    final closedDates = closedDatesAsync.value ?? const <String>{};
    final selectedDateStr = bookingFormatDate(selectedDate);
    final isSelectedDateClosed = closedDates.contains(selectedDateStr);

    final placeAsync = ref.watch(placeDetailsProvider(placeId));
    final place = placeAsync.value;
    final autoDiscount = ref.watch(bestAutoDiscountProvider(AutoDiscountKey(
      orderType: 'bookings',
      placeId: placeId,
      merchantId: place?.merchantId,
      categoryId: place?.categoryId,
    )));
    final merchantDiscount = ref.watch(placeMerchantDiscountProvider(
      PlaceDiscountKey(placeId: placeId, merchantId: place?.merchantId),
    ));
    final promo = ref.watch(_padelPromoProvider);

    final slotsAsync = selectedCourt != null
        ? ref.watch(availableSlotsProvider(
            courtId: selectedCourt.id,
            date: bookingFormatDate(selectedDate),
          ))
        : null;

    // Cancels any pending booking row + resets local submit state.
    // Awaits the server-side cancel so the next "Proceed" doesn't hit the
    // no-overlap exclusion constraint while the prior `pending` row is still
    // alive. State is `loading` during the cancel, which disables Proceed.
    Future<void> resetPendingBooking() =>
        ref.read(bookingSubmitProvider.notifier).cancelPending();

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
          // Release the pending row so the slot frees up immediately instead
          // of staying "booked" until the expiry cron. The slot is only ever
          // held by a confirmed (paid) booking.
          await ref.read(bookingSubmitProvider.notifier).cancelPending();
          if (selectedCourt != null) {
            ref.invalidate(availableSlotsProvider(
              courtId: selectedCourt.id,
              date: bookingFormatDate(selectedDate),
            ));
          }
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
          // webview, so the slot becomes available again right away (no hot
          // restart, no waiting on the expiry cron). cancelPending() reads the
          // booking id from the success state, cancels via cancel_booking, then
          // resets local state to idle — which also re-enables Proceed only
          // after the row is gone, so a retry can't race the stale pending row.
          await ref.read(bookingSubmitProvider.notifier).cancelPending();
          if (selectedCourt != null) {
            ref.invalidate(availableSlotsProvider(
              courtId: selectedCourt.id,
              date: bookingFormatDate(selectedDate),
            ));
          }
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
              ref.read(_selectedDateProvider.notifier).set(date);
              ref.read(_selectedSlotsProvider.notifier).clear();
              // Clear any pending booking when selection changes
              resetPendingBooking();
            },
          ),
          const SizedBox(height: 28),

          // ── Court selector ─────────────────────────────────────────
          BookingSectionLabel(isAr ? 'اختر الملعب' : 'Select Court'),
          courtsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Error loading courts: $e'),
            ),
            data: (courts) => courts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Text(isAr
                        ? 'لا توجد ملاعب متاحة.'
                        : 'No courts available.'),
                  )
                : _CourtsRow(
                    courts: courts,
                    selectedId: selectedCourt?.id,
                    onSelect: (court) {
                      ref.read(_selectedCourtProvider.notifier).set(court);
                      ref.read(_selectedSlotsProvider.notifier).clear();
                      // Clear any pending booking when selection changes
                      resetPendingBooking();
                    },
                  ),
          ),
          const SizedBox(height: 28),

          // ── Slot grid ──────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: selectedCourt != null
                ? Column(
                    key: ValueKey(
                        '${selectedCourt.id}-${bookingFormatDate(selectedDate)}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookingSectionLabel(isAr
                          ? 'الأوقات المتاحة — ${bookingDisplayDate(selectedDate, isArabic: true)}'
                          : 'Available Times — ${bookingDisplayDate(selectedDate)}'),
                      if (slotsAsync != null)
                        slotsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Text('Error loading times: $e'),
                          ),
                          data: (slots) {
                            if (isSelectedDateClosed) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: _ClosedDay(),
                              );
                            }
                            if (slots.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 24),
                                child: _EmptySlots(),
                              );
                            }
                            // Pass raw slots — SlotGrid handles expiry internally
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: SlotGrid(
                                slots: slots,
                                selectedStartTimes: selectedSlots,
                                discount: merchantDiscount,
                                onTap: (slot) {
                                  ref
                                      .read(_selectedSlotsProvider.notifier)
                                      .toggle(slot.startsAt);
                                  // Clear any pending booking when selection changes
                                  resetPendingBooking();
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Summary card (animated) ────────────────────────────────
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
            child: (selectedCourt != null && selectedSlots.isNotEmpty)
                ? Builder(
                    key: const ValueKey('summary-visible'),
                    builder: (context) {
                      final hours = selectedSlots.length;
                      final subtotal =
                          (selectedCourt.pricePerHour * hours).toInt();
                      final merchantHourly =
                          _BookingFormView._computeMerchantHourly(
                        discount: merchantDiscount,
                        slots: selectedSlots,
                        pricePerHour: selectedCourt.pricePerHour.toInt(),
                        subtotal: subtotal,
                      );
                      // Promo stacks on top of the hourly discount, so it
                      // applies to (subtotal − merchantHourly).
                      final promoBase = subtotal - merchantHourly.amount;
                      if (promo != null &&
                          promo.finalAmount + promo.discountAmount !=
                              promoBase) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(_padelPromoProvider.notifier).set(null);
                        });
                      }
                      final eff = _BookingFormView._resolveEffective(
                        subtotal: subtotal,
                        promo: promo,
                        autoDiscount: autoDiscount,
                        merchantHourlyAmount: merchantHourly.amount,
                        merchantHourlyLabel: merchantHourly.label,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BookingSummaryCard(
                          title: isAr ? 'ملخص الحجز' : 'Booking Summary',
                          badgeText: isAr
                              ? '${selectedSlots.length} ${selectedSlots.length == 1 ? 'ساعة' : 'ساعات'}'
                              : '${selectedSlots.length} ${selectedSlots.length == 1 ? 'hour' : 'hours'}',
                          rows: [
                            BookingSummaryRow(
                              icon: Icons.sports_tennis_rounded,
                              label: isAr ? 'الملعب' : 'Court',
                              valueWidget: BilingualLabel(
                                ar: selectedCourt.nameAr,
                                en: selectedCourt.nameEn,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                    ),
                              ),
                            ),
                            BookingSummaryRow(
                              icon: Icons.calendar_today_rounded,
                              label: isAr ? 'التاريخ' : 'Date',
                              value: bookingDisplayDate(selectedDate,
                                  isArabic: isAr),
                            ),
                            BookingSummaryRow(
                              icon: Icons.schedule_rounded,
                              label: isAr ? 'الوقت' : 'Time',
                              value:
                                  _BookingFormView._timeRange(selectedSlots),
                            ),
                          ],
                          subtotalLabel: isAr ? 'المجموع' : 'Subtotal',
                          subtotalValue: eff.discount > 0
                              ? _BookingFormView._formatIqd(subtotal)
                              : null,
                          discountLabel:
                              eff.discount > 0 ? eff.label : null,
                          discountValue: eff.discount > 0
                              ? '−${_BookingFormView._formatIqd(eff.discount)}'
                              : null,
                          totalLabel:
                              isAr ? 'المبلغ الإجمالي' : 'Total Amount',
                          totalValue:
                              _BookingFormView._formatIqd(eff.finalAmount),
                          extraSlot: promoBase > 0
                              ? PromoCodeField(
                                  orderType: 'bookings',
                                  subtotal: promoBase,
                                  placeId: placeId,
                                  merchantId: place?.merchantId,
                                  categoryId: place?.categoryId,
                                  applied: promo,
                                  isAr: isAr,
                                  onChange: (p) {
                                    ref
                                        .read(_padelPromoProvider.notifier)
                                        .set(p);
                                    resetPendingBooking();
                                  },
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
                                final sorted = selectedSlots.toList()..sort();
                                ref
                                    .read(bookingSubmitProvider.notifier)
                                    .createPadelBooking(
                                      placeId: placeId,
                                      courtId: selectedCourt.id,
                                      startsAt: sorted.first,
                                      hours: selectedSlots.length,
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

// ---------------------------------------------------------------------------
// Courts row
// ---------------------------------------------------------------------------

class _CourtsRow extends StatelessWidget {
  const _CourtsRow({
    required this.courts,
    required this.selectedId,
    required this.onSelect,
  });
  final List<Court> courts;
  final String? selectedId;
  final void Function(Court) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: courts.length,
        itemBuilder: (context, i) {
          final court = courts[i];
          final isSelected = selectedId == court.id;
          final colorScheme = Theme.of(context).colorScheme;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: GestureDetector(
              onTap: () => onSelect(court),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_tennis_rounded,
                      size: 16,
                      color: isSelected ? Colors.white : colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    BilingualLabel(
                      ar: court.nameAr,
                      en: court.nameEn,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color:
                            isSelected ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 15),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty slots placeholder
// ---------------------------------------------------------------------------

class _EmptySlots extends StatelessWidget {
  const _EmptySlots();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 36, color: colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            return Text(
              isAr
                  ? 'لا توجد أوقات متاحة لهذا التاريخ.'
                  : 'No available times for this date.',
              style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 13),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Closed day placeholder
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
