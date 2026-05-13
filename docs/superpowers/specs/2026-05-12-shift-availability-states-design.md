# Spec: Shift & Slot Availability States
**Date:** 2026-05-12
**Scope:** All booking types — farm shifts, padel slots, restaurant time slots, concert section

---

## Problem

The current booking UI has two availability states: available and unavailable (isBooked/isAvailable).
Users cannot distinguish between three meaningfully different unavailability reasons:
1. The place is **closed** on that day (merchant-configured hours)
2. The shift/slot is **booked** by someone else
3. The shift/slot has **expired** because the time has already passed today

Additionally, closed dates are not visible in the date strip — users must select a date before discovering the place is closed.

---

## Solution

Introduce a `SlotAvailability` enum with four states used uniformly across all booking types. Add a Supabase RPC to expose closed dates for a place. Surface all three unavailability reasons with distinct labels in both Arabic and English.

---

## Availability State Model

```dart
enum SlotAvailability { available, booked, expired, closed }
```

| State | Trigger | Label EN | Label AR | Icon |
|---|---|---|---|---|
| `available` | Bookable | — | — | shift/time icon |
| `booked` | Backend `is_available=false`, time not past | Booked | محجوز | lock |
| `expired` | Today + start time ≤ current time | Expired | منتهي | schedule/clock |
| `closed` | Place closed on this day (from backend) | Closed | مغلق | block |

**Non-tappable states:** `booked`, `expired`, `closed`.

**Expired time logic:**
- Uses `DateTime.now().toLocal()` — consistent with existing padel slot expiry code.
- Farm shifts: parse `startsTime` (HH:MM:SS) as local time on the selected date, compare with now.
- Padel/restaurant slots: parse ISO `startsAt` via `.toLocal()`, compare with now.

**Farm cascade rule:** No special logic needed. The full-day shift has the same `starts_time` as the day shift (e.g. 08:00), so it naturally expires at the same moment when checked independently.

---

## Backend Changes

### 1. New RPC: `public.place_closed_dates`

```sql
place_closed_dates(p_place_id uuid, p_start_date date, p_end_date date)
RETURNS SETOF date
```

Returns every date in the range where the place is closed, by checking:
1. `place_hours_overrides` — date-specific `is_closed = true` overrides (highest priority)
2. `place_hours` — weekly schedule where `is_closed = true` for that weekday

Granted to `anon, authenticated`. Called once per section load covering 90 days.

### 2. Update `available_farm_shifts` RPC

Add `is_closed boolean` to the return type. Before querying shifts, check place-wide hours for `p_date` (using the same `place_hours_overrides` / `place_hours` priority as `_court_hours` but without a court_id). If the place is closed:
- Return all configured shifts with `is_available = false, is_closed = true`.

The existing `available_slots` (padel) already returns empty on closed days — no change needed. The `place_closed_dates` result tells the Flutter layer whether "empty = closed" or "empty = fully booked".

---

## Flutter Changes

### `FarmShift` model
Add `isClosed: bool` field, default `false`, parsed from new RPC column `is_closed`.

### `SlotAvailability` enum
New file: `lib/features/booking/domain/models/slot_availability.dart`

### `ShiftCard` widget
- Replace `isBooked: bool` parameter with `availability: SlotAvailability`
- State-specific visuals:
  - `expired` → amber muted chip "Expired / منتهي", clock icon, all colors grayed
  - `booked` → error red chip "Booked / محجوز", lock icon, all colors grayed (existing behavior)
  - `closed` → neutral gray chip "Closed / مغلق", block icon, all colors grayed

### `SlotGrid` / `_SlotTile` widget
- `_SlotTile` receives `availability: SlotAvailability` instead of `isAvailable: bool`
- Unavailable tiles show a tiny status label below the time (replaces plain strikethrough)
- `SlotGrid` computes availability per slot:
  ```dart
  if (startsAt <= now)        → SlotAvailability.expired
  else if (!slot.available)   → SlotAvailability.booked
  else                        → SlotAvailability.available
  ```
- Raw (untransformed) slots passed from `PadelSection` — `SlotGrid` owns expiry logic

### `BookingDateStrip` widget
- New parameter: `closedDates: Set<String>` (dates as `"yyyy-MM-dd"`)
- Closed date cells: subtle neutral tint background, tiny "مغلق/Closed" label below day number, no selection bar indicator
- Still tappable so users can tap and see the "Closed" empty state in the content area

### New `placeClosedDatesProvider`
```dart
@riverpod
Future<Set<String>> placeClosedDates(Ref ref, String placeId)
```
- Calls `place_closed_dates` RPC for today → today + 90 days
- Returns `Set<String>` of `"yyyy-MM-dd"` strings
- Added to `availability_provider.dart`

### Sections with date strips: `FarmSection`, `PadelSection`, `RestaurantSection`

Concert and membership sections are event/plan-based (no date strip) — closed-date logic does not apply to them.
- Watch `placeClosedDatesProvider(placeId)`
- Pass `closedDates` to `BookingDateStrip`
- When selected date is in `closedDates`: show a "مغلق / Closed" empty state widget instead of "No available times"
- `FarmSection`: compute `availability` per shift before passing to `ShiftCard`:
  ```dart
  if (shift.isClosed)                               → closed
  else if (isToday && shiftStartLocal <= now)        → expired
  else if (!shift.isAvailable)                       → booked
  else                                               → available
  ```
- `PadelSection`: pass original slots (no pre-transformation) to `SlotGrid`; remove existing past-slot transformation
- `RestaurantSection`: restaurant slots are client-generated (no backend availability per slot), so only `expired` applies (no `booked` state)

---

## Bilingual Labels

All chips and empty-state messages appear in both languages based on app locale (`Localizations.localeOf(context).languageCode == 'ar'`):

| Context | EN | AR |
|---|---|---|
| Booked chip | Booked | محجوز |
| Expired chip | Expired | منتهي |
| Closed chip | Closed | مغلق |
| Closed empty state | This place is closed on this date | هذا المكان مغلق في هذا التاريخ |
| Date strip closed label | Closed | مغلق |

---

## Files Changed

| File | Change |
|---|---|
| `supabase/migrations/YYYYMMDD_place_closed_dates.sql` | New RPC |
| `supabase/migrations/YYYYMMDD_farm_shifts_is_closed.sql` | Add `is_closed` to farm shifts RPC |
| `lib/features/booking/domain/models/slot_availability.dart` | New enum |
| `lib/features/booking/domain/models/farm_shift.dart` | Add `isClosed` field |
| `lib/features/booking/domain/models/farm_shift.freezed.dart` | Regenerated |
| `lib/features/booking/domain/models/farm_shift.g.dart` | Regenerated |
| `lib/features/booking/presentation/providers/availability_provider.dart` | Add `placeClosedDatesProvider` |
| `lib/features/booking/presentation/providers/availability_provider.g.dart` | Regenerated |
| `lib/features/booking/presentation/widgets/shift_card.dart` | Replace `isBooked` with `availability` |
| `lib/features/booking/presentation/widgets/slot_grid.dart` | Add `SlotAvailability` per tile |
| `lib/features/booking/presentation/widgets/booking_date_strip.dart` | Add `closedDates` param |
| `lib/features/booking/presentation/sections/farm_section.dart` | Availability computation |
| `lib/features/booking/presentation/sections/padel_section.dart` | Pass closed dates, remove transformation |
| `lib/features/booking/presentation/sections/restaurant_section.dart` | Pass closed dates, expired slots |
| `lib/features/booking/presentation/sections/concert_section.dart` | No change — no date strip |
