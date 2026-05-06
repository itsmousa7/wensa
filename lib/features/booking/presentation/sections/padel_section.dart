import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/court.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/bilingual_label.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/slot_grid.dart';
import 'package:future_riverpod/features/booking/domain/repositories/booking_repository.dart';
import 'package:future_riverpod/features/booking/presentation/pages/payment_webview_page.dart';
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
    NotifierProvider.autoDispose<_SlotsNotifier, Set<String>>(_SlotsNotifier.new);

// ---------------------------------------------------------------------------
// PadelSection
// ---------------------------------------------------------------------------

class PadelSection extends ConsumerWidget {
  const PadelSection({super.key, required this.placeId});
  final String placeId;

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

    return _BookingFormView(placeId: placeId);
  }
}

// ---------------------------------------------------------------------------
// Booking form
// ---------------------------------------------------------------------------

class _BookingFormView extends ConsumerWidget {
  const _BookingFormView({required this.placeId});
  final String placeId;

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String displayDate(DateTime dt, {bool isArabic = false}) {
    const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const daysAr = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    if (isArabic) {
      return '${daysAr[dt.weekday - 1]}، ${dt.day} ${monthsAr[dt.month - 1]} ${dt.year}';
    }
    return '${daysEn[dt.weekday - 1]}, ${dt.day} ${monthsEn[dt.month - 1]} ${dt.year}';
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

    final slotsAsync = selectedCourt != null
        ? ref.watch(availableSlotsProvider(
            courtId: selectedCourt.id,
            date: _formatDate(selectedDate),
          ))
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Date strip ─────────────────────────────────────────────
          _SectionLabel(isAr ? 'اختر التاريخ' : 'Select Date'),
          _DateStrip(
            selected: selectedDate,
            onSelect: (date) {
              ref.read(_selectedDateProvider.notifier).set(date);
              ref.read(_selectedSlotsProvider.notifier).clear();
            },
          ),
          const SizedBox(height: 28),

          // ── Court selector ─────────────────────────────────────────
          _SectionLabel(isAr ? 'اختر الملعب' : 'Select Court'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(isAr ? 'لا توجد ملاعب متاحة.' : 'No courts available.'),
                  )
                : _CourtsRow(
                    courts: courts,
                    selectedId: selectedCourt?.id,
                    onSelect: (court) {
                      ref.read(_selectedCourtProvider.notifier).set(court);
                      ref.read(_selectedSlotsProvider.notifier).clear();
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
                        '${selectedCourt.id}-${_formatDate(selectedDate)}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(isAr
                          ? 'الأوقات المتاحة — ${displayDate(selectedDate, isArabic: true)}'
                          : 'Available Times — ${displayDate(selectedDate)}'),
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
                            if (slots.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 24),
                                child: _EmptySlots(),
                              );
                            }
                            final now = DateTime.now();
                            final isToday = selectedDate.year == now.year &&
                                selectedDate.month == now.month &&
                                selectedDate.day == now.day;
                            final displaySlots = isToday
                                ? slots.map((slot) {
                                    try {
                                      final slotTime =
                                          DateTime.parse(slot.startsAt)
                                              .toLocal();
                                      if (!slotTime.isAfter(now)) {
                                        return slot.copyWith(available: false);
                                      }
                                    } catch (_) {}
                                    return slot;
                                  }).toList()
                                : slots;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: SlotGrid(
                                slots: displaySlots,
                                selectedStartTimes: selectedSlots,
                                onTap: (slot) {
                                  ref
                                      .read(_selectedSlotsProvider.notifier)
                                      .toggle(slot.startsAt);
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
            transitionBuilder: (child, animation) {
              return FadeTransition(
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
              );
            },
            child: (selectedCourt != null && selectedSlots.isNotEmpty)
                ? Padding(
                    key: const ValueKey('summary-visible'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _BookingSummaryCard(
                      selectedDate: selectedDate,
                      selectedCourt: selectedCourt,
                      selectedSlots: selectedSlots,
                      placeId: placeId,
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
// Section label with accent bar
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal date strip
// ---------------------------------------------------------------------------

class _DateStrip extends StatefulWidget {
  const _DateStrip({required this.selected, required this.onSelect});
  final DateTime selected;
  final void Function(DateTime) onSelect;

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  late final ScrollController _scroll;
  static const double _itemW = 64;
  static const double _spacing = 10;
  static const double _padding = 16;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final diff = widget.selected.difference(DateTime(today.year, today.month, today.day)).inDays.clamp(0, 89);
    final offset = (diff * (_itemW + _spacing)).clamp(0.0, double.infinity);
    _scroll = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    const dayNamesEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayNamesAr = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final dayNames = isAr ? dayNamesAr : dayNamesEn;
    final todayLabel = isAr ? 'اليوم' : 'Today';

    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        itemCount: 90,
        itemBuilder: (context, i) {
          final today = DateTime.now();
          final date = DateTime(today.year, today.month, today.day)
              .add(Duration(days: i));
          final isSelected = date.year == widget.selected.year &&
              date.month == widget.selected.month &&
              date.day == widget.selected.day;
          final isToday = i == 0;

          final Color dayLabelColor = isSelected
              ? Colors.white
              : colorScheme.onSurface.withValues(alpha: 0.85);

          return Padding(
            padding: EdgeInsetsDirectional.only(end: _spacing),
            child: GestureDetector(
              onTap: () => widget.onSelect(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: _itemW,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : isToday
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : isToday
                            ? colorScheme.primary.withValues(alpha: 0.4)
                            : colorScheme.outline.withValues(alpha: 0.15),
                    width: isToday && !isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day label / Today badge
                    if (isToday && !isSelected)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              todayLabel,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        isToday ? todayLabel : dayNames[date.weekday - 1],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: dayLabelColor,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 22 : (isToday ? 6 : 4),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.7)
                            : isToday
                                ? colorScheme.primary.withValues(alpha: 0.6)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
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
                        color: isSelected ? Colors.white : colorScheme.onSurface,
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
              isAr ? 'لا توجد أوقات متاحة لهذا التاريخ.' : 'No available times for this date.',
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
// Booking summary card
// ---------------------------------------------------------------------------

class _BookingSummaryCard extends ConsumerWidget {
  const _BookingSummaryCard({
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

  String _timeLabel(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  String _timeRange() {
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

  String _displayDate(DateTime dt, {bool isArabic = false}) {
    return _BookingFormView.displayDate(dt, isArabic: isArabic);
  }

  String _earliestSlot() {
    final sorted = selectedSlots.toList()..sort();
    return sorted.first;
  }

  String _formatPrice(double pricePerHour) {
    if (pricePerHour <= 0) return 'TBD';
    final total = (pricePerHour * selectedSlots.length).toInt();
    final formatted = total.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'IQD $formatted';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hours = selectedSlots.length;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  isAr ? 'ملخص الحجز' : 'Booking Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAr
                        ? '$hours ${hours == 1 ? 'ساعة' : 'ساعات'}'
                        : '$hours ${hours == 1 ? 'hour' : 'hours'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Details body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.sports_tennis_rounded,
                  label: isAr ? 'الملعب' : 'Court',
                  valueWidget: BilingualLabel(
                    ar: selectedCourt.nameAr,
                    en: selectedCourt.nameEn,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
                _divider(),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: isAr ? 'التاريخ' : 'Date',
                  value: _displayDate(selectedDate, isArabic: isAr),
                ),
                _divider(),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: isAr ? 'الوقت' : 'Time',
                  value: _timeRange(),
                ),
                const SizedBox(height: 16),

                // Total amount highlight row
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.08),
                        colorScheme.secondary.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments_rounded,
                          size: 20, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        isAr ? 'المبلغ الإجمالي' : 'Total Amount',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(selectedCourt.pricePerHour),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Pay button with gradient
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isLoading
                          ? null
                          : LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      color: isLoading
                          ? colorScheme.surfaceContainerHighest
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: colorScheme.primary
                                    .withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : () {
                                ref
                                    .read(bookingSubmitProvider.notifier)
                                    .createPadelBooking(
                                      placeId: placeId,
                                      courtId: selectedCourt.id,
                                      startsAt: _earliestSlot(),
                                      hours: hours,
                                    );
                              },
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lock_outline_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1),
      );
}

// ---------------------------------------------------------------------------
// Detail row widget
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.outline),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colorScheme.outline),
        ),
        const Spacer(),
        valueWidget ??
            Text(
              value ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
      ],
    );
  }
}
