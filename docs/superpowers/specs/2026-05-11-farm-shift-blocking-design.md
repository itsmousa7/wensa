# Farm Shift Blocking Design

**Date:** 2026-05-11  
**Status:** Approved

## Problem

Once a confirmed farm booking exists for a specific shift on a specific date, the mobile app currently shows all shifts as selectable regardless. A second user (or the same user on a different device) can attempt to book the same shift — the DB will reject it at the GIST exclusion level, but the user only discovers this after going through the payment flow.

## Goal

After a farm booking is **confirmed** (payment completed, `status = 'confirmed'`), the corresponding shift on that date must appear **grayed out with a "Booked" label** in the mobile app so users cannot attempt to book it.

- Full-day booking → day shift + night shift both appear as blocked (their time ranges overlap with full-day's range).
- Day + night both confirmed → full-day appears as blocked.
- Cancellation restores availability immediately on next fetch.

## DB-Level Protection (Already Exists)

`bookings_no_farm_overlap` GIST exclusion on `bookings.bookings` prevents overlapping farm bookings at `status IN ('pending', 'confirmed')`. This is the authoritative guard against duplicate bookings and is not changed by this design.

## Solution Overview

Add a `bookings.available_farm_shifts(place_id, date)` RPC that returns all shift definitions for a farm plus an `is_available` flag per shift. The mobile app calls this RPC (instead of reading `farm_shifts` directly) and renders unavailable shifts as disabled.

---

## Section 1 — Database

### New migration: `20260511000002_farm_shift_availability.sql`

**`bookings.available_farm_shifts(p_place_id uuid, p_date date)`**

Returns `TABLE (place_id uuid, shift_type farm_shift_type, starts_time time, ends_time time, price_iqd integer, is_available boolean)`.

For each shift in `bookings.farm_shifts` for the given place, checks whether any `confirmed` booking in `bookings.bookings` has a time range that overlaps with the shift's time window on `p_date`:

- Shift window start: `(p_date || ' ' || starts_time)::timestamp AT TIME ZONE 'Asia/Baghdad'`
- Shift window end: same logic as `create_farm_booking` — if `ends_time <= starts_time` (overnight), use `p_date + 1` for the end date.
- Overlap check: `tstzrange(b.starts_at, b.ends_at, '[)') && tstzrange(shift_start, shift_end, '[)')`

`is_available = true` when no such confirmed booking exists.

**`public.available_farm_shifts(p_place_id uuid, p_date date)`** — PostgREST-accessible wrapper (same pattern as `public.available_slots`). Casts `shift_type` to `text` for JSON serialization.

---

## Section 2 — Flutter Model

**File:** `lib/features/booking/domain/models/farm_shift.dart`

Add `@Default(true) bool isAvailable` to the `FarmShift` freezed class. Update `fromJson` to parse `is_available` from the RPC response (defaults to `true` if missing, preserving backward compat).

Regenerate: `farm_shift.freezed.dart`, `farm_shift.g.dart`.

---

## Section 3 — Repository + Provider

**`BookingRepository.fetchFarmShifts`** (`booking_repository.dart`):
- Change signature to `fetchFarmShifts(String placeId, String date)`
- Call `_client.rpc('available_farm_shifts', params: {'p_place_id': placeId, 'p_date': date})` instead of the direct table query.

**`farmShiftsProvider`** (`availability_provider.dart`):
- Change signature from `farmShifts(Ref ref, String placeId)` to `farmShifts(Ref ref, String placeId, String date)`.
- Pass both to `fetchFarmShifts`. Riverpod's parameter-keyed caching means switching dates triggers an automatic re-fetch.

Regenerate: `availability_provider.g.dart`.

---

## Section 4 — UI

**`ShiftCard`** (`lib/features/booking/presentation/widgets/shift_card.dart`):
- Add `required bool isBooked` parameter.
- When `isBooked = true`:
  - Card background: `colorScheme.surfaceContainerHighest` with reduced opacity.
  - Icon and text: `colorScheme.onSurface.withValues(alpha: 0.38)` (Material disabled alpha).
  - `GestureDetector.onTap` becomes `null`.
  - Show a red "Booked" chip alongside the shift label (matching the existing "Blocks the full day" chip style but using `colorScheme.errorContainer` / `colorScheme.onErrorContainer`).

**`FarmSection`** (`lib/features/booking/presentation/sections/farm_section.dart`):
- Update `ref.watch(farmShiftsProvider(placeId))` → `ref.watch(farmShiftsProvider(placeId, bookingFormatDate(selectedDate)))`.
- Pass `isBooked: !shift.isAvailable` to each `ShiftCard`.
- When date changes, the provider auto-refetches; no manual invalidation needed.

---

## Data Flow

```
User opens farm booking page
  └─> farmShiftsProvider(placeId, date) called
        └─> BookingRepository.fetchFarmShifts(placeId, date)
              └─> Supabase RPC: available_farm_shifts(place_id, date)
                    └─> Returns shifts + is_available per shift
  └─> ShiftCard rendered with isBooked = !shift.isAvailable
        ├─> isBooked=false → selectable card (existing behavior)
        └─> isBooked=true  → grayed out + "Booked" chip, tap disabled

User selects date in BookingDateStrip
  └─> farmShiftsProvider(placeId, newDate) watched — new cache key → re-fetch
```

---

## Error Handling

- RPC errors surface via the existing `shiftsAsync.when(error: ...)` in `FarmSection` — no change needed.
- If `available_farm_shifts` returns no rows (farm has no shifts configured), the existing "No shifts available" empty state handles it.

## Testing Notes

- Book day shift → confirm payment → reopen farm page on same date: day and full-day should be blocked; night should be free.
- Book full-day → confirm payment → reopen: all three shifts blocked.
- Cancel the confirmed booking → reopen: all shifts available again.
- Different date: all shifts available regardless.
