# Booking Card Text Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the booking card's date-as-title with the place/event name as title, show time-remaining as subtitle, and show the full weekday + date on the bottom row — all bilingual (Arabic/English).

**Architecture:** Convert `_BookingCard` from `StatelessWidget` to `ConsumerWidget` so it can resolve the place/event name via `placeDetailsProvider`/`eventDetailsProvider` (same pattern already used in `_BookingDetailBody`). All formatting helpers live as private statics on `TicketCard`. No new files needed.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), `intl` (already imported)

---

## File Map

| Action | File |
|--------|------|
| Modify | `lib/features/bookings_history/presentation/widgets/ticket_card.dart` |

---

### Task 1: Convert `_BookingCard` to `ConsumerWidget` and add name resolution

**Files:**
- Modify: `lib/features/bookings_history/presentation/widgets/ticket_card.dart`

- [ ] **Step 1: Add the missing import**

Open `lib/features/bookings_history/presentation/widgets/ticket_card.dart`.

After the existing imports, add:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
```

- [ ] **Step 2: Change `_BookingCard` class declaration**

Replace:
```dart
class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
```

With:
```dart
class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
```

- [ ] **Step 3: Add name resolution logic at the top of `build`**

Directly after `final accent = TicketCard._categoryAccent(booking.category);` add:

```dart
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Resolve bilingual display name (mirrors _BookingDetailBody)
    final String placeName;
    if (booking.placeId != null && booking.placeId!.isNotEmpty) {
      final pa = ref.watch(placeDetailsProvider(booking.placeId!));
      placeName = pa.when(
        data: (p) => isArabic
            ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn)
            : (p.nameEn.isNotEmpty ? p.nameEn : p.nameAr),
        loading: () => '…',
        error: (_, _) => _categoryFallback(booking.category, isArabic),
      );
    } else if (booking.eventId != null && booking.eventId!.isNotEmpty) {
      final ea = ref.watch(eventDetailsProvider(booking.eventId!));
      placeName = ea.when(
        data: (e) => isArabic
            ? (e.titleAr.isNotEmpty ? e.titleAr : e.titleEn)
            : (e.titleEn.isNotEmpty ? e.titleEn : e.titleAr),
        loading: () => '…',
        error: (_, _) => _categoryFallback(booking.category, isArabic),
      );
    } else {
      placeName = _categoryFallback(booking.category, isArabic);
    }
```

Also remove the two now-unused lines:
```dart
    final dateStr = TicketCard._formatDate(booking.startsAt);
    final timeStr = TicketCard._formatTime(booking.startsAt);
```

- [ ] **Step 4: Add static helpers to `TicketCard`**

Add these three static methods inside `class TicketCard` (after `_formatAmount`):

```dart
  static String _categoryFallback(BookingCategory cat, bool isArabic) {
    switch (cat) {
      case BookingCategory.hourly:
        return isArabic ? 'حجز رياضي' : 'Sports Booking';
      case BookingCategory.shift:
        return isArabic ? 'حجز مزرعة' : 'Farm Booking';
      case BookingCategory.venueSeat:
        return isArabic ? 'حجز حفلة' : 'Concert Booking';
      case BookingCategory.reservation:
        return isArabic ? 'حجز مطعم' : 'Restaurant Booking';
      case BookingCategory.membership:
        return isArabic ? 'عضوية' : 'Membership';
    }
  }

  static String _formatTimeRemaining(String iso, bool isArabic) {
    if (iso.isEmpty) return '';
    final DateTime dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '';
    }
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return '';
    if (diff.inDays >= 1) {
      final d = diff.inDays;
      return isArabic ? 'خلال $d ${d == 1 ? 'يوم' : 'أيام'}' : 'in $d ${d == 1 ? 'day' : 'days'}';
    }
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      return isArabic ? 'خلال $h ${h == 1 ? 'ساعة' : 'ساعات'}' : 'in $h ${h == 1 ? 'hour' : 'hours'}';
    }
    final m = diff.inMinutes;
    if (m < 1) return isArabic ? 'الآن' : 'now';
    return isArabic ? 'خلال $m دقيقة' : 'in $m min';
  }

  // Informal Arabic weekday names (no ال prefix), as preferred by the user.
  // Index order: 0=Sunday, 1=Monday … 6=Saturday (matches dt.weekday % 7).
  static const _arWeekdays = [
    'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت',
  ];

  static String _formatWeekdayDate(String iso, bool isArabic) {
    if (iso.isEmpty) return '';
    final DateTime dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '';
    }
    if (isArabic) {
      final weekday = _arWeekdays[dt.weekday % 7]; // DateTime.sunday==7 → index 0
      final monthNames = [
        '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ];
      return '$weekday، ${dt.day} ${monthNames[dt.month]} ${dt.year}';
    } else {
      return DateFormat('EEEE, d MMM yyyy').format(dt);
    }
  }
```

> Note: `DateTime.weekday` returns 1=Monday … 7=Sunday. `dt.weekday % 7` maps Sunday(7)→0, Monday(1)→1, …, Saturday(6)→6, matching `_arWeekdays` index order.

- [ ] **Step 5: Rewrite the card content columns**

Replace the entire `Column` children list inside `_BookingCard.build` (the `child: Column(...)` that currently has `Row` with `dateStr` and the time/amount row) with:

```dart
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: place/event name + status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              placeName,
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TicketStatusBadge.booking(status: booking.status),
                        ],
                      ),
                      // Row 2: time remaining (only when in the future)
                      Builder(builder: (context) {
                        final remaining = TicketCard._formatTimeRemaining(
                            booking.startsAt, isArabic);
                        if (remaining.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 12,
                                  color: cs.onSurface.withValues(alpha: 0.45)),
                              const SizedBox(width: 3),
                              Text(
                                remaining,
                                style: tt.bodySmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Row 3: weekday+date (left) · amount (right)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                TicketCard._formatWeekdayDate(
                                    booking.startsAt, isArabic),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              TicketCard._formatAmount(booking.amountIqd),
                              style: tt.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
```

- [ ] **Step 6: Remove now-unused `_formatDate` and `_formatTime` static methods from `TicketCard`** (they are no longer referenced)

Delete these two methods from `TicketCard`:
```dart
  static String _formatDate(String iso) { … }
  static String _formatTime(String iso) { … }
```

- [ ] **Step 7: Hot-restart and visually verify**

Run the app (`flutter run`) and navigate to the Bookings tab.

Expected for a future booking:
```
[Icon] | Wensa Padel / وينسا پادل    | [confirmed]
       | 🕐 in 2 days / خلال يومين
       | Thursday, 15 May 2026 · 75,000 IQD
```

Expected for a past/same-day booking (no time remaining):
```
[Icon] | Restaurant Name             | [completed]
       | Thursday, 8 May 2026 · 50,000 IQD
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/bookings_history/presentation/widgets/ticket_card.dart
git commit -m "feat(bookings): show place/event name + time-remaining + weekday date on booking card"
```
