# Farm Shift Weekday-Recurring Price Override Design

**Date:** 2026-08-07
**Status:** Approved
**Supersedes:** [2026-08-06-farm-shift-price-override-design.md](./2026-08-06-farm-shift-price-override-design.md) (per-calendar-date override — replaced before its dashboard UI task finished landing; no real merchant data exists in the superseded table)

## Problem

The just-shipped per-*calendar-date* override (one row per `place_id, shift_type, date`) doesn't match how merchants actually want to price farm shifts: not "August 20th costs more," but "every Thursday and Friday costs more" — a recurring rule tied to the day of the week, not a specific date.

## Goal

Let a merchant set a price for a farm shift that recurs on one or more weekdays (e.g. Thursday + Friday = 300,000 IQD). Customers see the overridden price with the standard price struck through, plus a hint naming *which* weekdays trigger it — not just whether today happens to be one of them.

## Precedent — reuse, don't reinvent

This exact shape of problem (a weekly-recurring per-day rule) already exists in this schema: `bookings.place_hours` (opening hours) uses `weekday smallint NOT NULL CHECK (weekday BETWEEN 0 AND 6)` — "0 = Sunday … 6 = Saturday (matches JS convention)," per its own migration comment (`supabase/migrations/20260427000002_bookings_courts_hours_pricing.sql:24-36`). This is also exactly what Postgres's `EXTRACT(DOW FROM date)` returns and what JavaScript's `Date.getDay()` returns — the dashboard's `PlacesPage.tsx`/`MyPlacesPage.tsx` already builds a 7-row weekly editor keyed this same way. The new table mirrors this column name and convention exactly, and the dashboard's day-name translation keys (`daySun`…`daySat`, already present in `en.ts:273-274`/`ar.ts:335`) are reused as-is rather than adding new ones.

## Undo Section — remove the per-date implementation

The per-date table and its two RPC integrations shipped this session but hold no real merchant data (only test rows, already cleaned up) and the dashboard UI for it never reached a merchant. Safe to remove outright, not migrate:

- **DB:** `DROP TABLE bookings.farm_shift_price_overrides` (drops its own RLS policies automatically). `available_farm_shifts` and `create_farm_booking` get new migrations that replace the date-keyed `LEFT JOIN`/lookup with the weekday-keyed version below — not a literal git revert, just fresh SQL on top of current state.
- **Mobile:** `FarmShift.standardPriceIqd` stays (same meaning: "an override is active for the currently-viewed date") — no mobile revert needed, only an addition (see below).
- **Dashboard:** `ShiftPanel`'s just-committed override section (`wansa-admin-dashboard` commit `bfa0fe5`) gets reworked in place — the date `<input type="date">` becomes a weekday `<select>`, and the `PriceOverride`/`ShiftRowState`-adjacent types swap `date: string` for `weekday: number`. The `farm_shift_price_overrides` entry in `TABLE_SCHEMA` (`src/lib/supabase.ts`) is renamed to `farm_shift_weekday_overrides`. The `bkgOverrideDate` translation key (currently "Date"/"التاريخ") is renamed to `bkgOverrideDay` ("Day"/"اليوم") — it's only consumed by this feature's own UI, safe to rename.

## Data Model

```sql
CREATE TABLE bookings.farm_shift_weekday_overrides (
  id         uuid                      PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id   uuid                      NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  shift_type bookings.farm_shift_type  NOT NULL,
  weekday    smallint                  NOT NULL CHECK (weekday BETWEEN 0 AND 6),
  price_iqd  integer                   NOT NULL CHECK (price_iqd > 0),
  created_at timestamptz               NOT NULL DEFAULT now(),
  UNIQUE (place_id, shift_type, weekday)
);
```

Same RLS shape as `farm_shifts`/the superseded table: public read, write restricted to `is_admin() OR is_merchant_staff_of(_place_merchant(place_id))`. A merchant wanting both Thursday and Friday at 300,000 adds two rows (`weekday=4`, `weekday=5`) — no array column, matching how `place_hours` handles "different hours per day" (one row per day, not a bitmask).

## Pricing Resolution

```
override_price_iqd = (SELECT price_iqd FROM farm_shift_weekday_overrides
                       WHERE place_id = :place AND shift_type = :type
                         AND weekday = EXTRACT(DOW FROM :date))
effective_price_iqd = COALESCE(override_price_iqd, standing_price_iqd)
```

Same as the superseded design, with `EXTRACT(DOW FROM p_date)` replacing `date = p_date` as the join/lookup key — both `available_farm_shifts` (display) and `create_farm_booking` (charge) resolve identically, so what's shown always matches what's charged.

## The Hint

`available_farm_shifts` additionally returns `override_weekdays smallint[]` per shift — the *full set* of weekdays that have any override configured for that `(place_id, shift_type)`, via a small aggregate subquery, independent of which date is currently selected:

```sql
(SELECT array_agg(wo.weekday ORDER BY wo.weekday)
 FROM bookings.farm_shift_weekday_overrides wo
 WHERE wo.place_id = fs.place_id AND wo.shift_type = fs.shift_type) AS override_weekdays
```

This lets `ShiftCard` show "Special price · Thu & Fri" regardless of whether the customer is currently looking at a Thursday, a Friday, or a Tuesday — more useful than a hint that only appears on the exact day it applies. Weekday-number-to-name formatting happens client-side (bilingual), following the existing pattern already duplicated in `lib/features/places/presentation/widgets/place_opening_hours.dart` and `lib/features/bookings_history/presentation/widgets/ticket_card.dart` (both already index weekday arrays as `0=Sunday…6=Saturday`, i.e. no remapping needed from this table's convention).

---

## Section 1 — Database

New migration(s) on top of current live state:

1. `DROP TABLE bookings.farm_shift_price_overrides;` then `CREATE TABLE bookings.farm_shift_weekday_overrides` (schema above) with RLS + the same two-policy shape as the table it replaces.
2. `available_farm_shifts` (`bookings.` + `public.`): same `DROP FUNCTION IF EXISTS` + `CREATE OR REPLACE` two-step as before (RETURNS TABLE column list changes — `standard_price_iqd` stays, `override_weekdays smallint[]` is new). The `LEFT JOIN` moves from `farm_shift_price_overrides ON date = p_date` to `farm_shift_weekday_overrides ON weekday = EXTRACT(DOW FROM p_date)::smallint`, plus the new aggregate subquery column. All availability/closure logic untouched (same constraint as the superseded plan).
3. `create_farm_booking`: plain `CREATE OR REPLACE` (signature unchanged), swapping the override `SELECT ... INTO v_price_iqd` lookup's `WHERE` clause from `date = p_date` to `weekday = EXTRACT(DOW FROM p_date)::smallint`. All party-pricing logic untouched.

## Section 2 — Mobile App (Flutter)

- `FarmShift` gains `List<int>? overrideWeekdays` (nullable, parsed from `override_weekdays`) alongside the existing `standardPriceIqd`.
- `ShiftCard`'s existing strikethrough + "Special price" badge (already built) gets its badge text extended: when `overrideWeekdays` is non-empty, append the formatted day list (e.g. "Special price · Thu & Fri" / "سعر خاص · الخميس والجمعة"), using a new small bilingual weekday-abbreviation formatter local to this widget (short-form, following the existing `ticket_card.dart` "informal Arabic weekday names" convention rather than full names, to fit the card's compact layout).

## Section 3 — Merchant + Admin Dashboard

- `PlaceBookingTab.tsx`'s `ShiftPanel`: the override type/state (`PriceOverride`, `overrideDate`/`setOverrideDate`) swaps `date: string` for `weekday: number`. The "Add Override" modal's date `<input type="date">` becomes a `<select>` of the 7 weekdays, reusing the existing `l.daySun`…`l.daySat` translation values already in `en.ts`/`ar.ts` (no new day-name keys needed). The override list rows show the weekday name instead of a date string.
- `src/lib/supabase.ts`: `TABLE_SCHEMA` entry renamed `farm_shift_price_overrides` → `farm_shift_weekday_overrides`.
- `bkgOverrideDate` ("Date"/"التاريخ") renamed to `bkgOverrideDay` ("Day"/"اليوم") in both translation files.

## Testing Notes

- Merchant adds Thursday + Friday overrides at 300,000 IQD for the Night shift (standing price 200,000).
- Mobile: any date's Night shift card shows "Special price · Thu & Fri" regardless of the currently selected date; on an actual Thursday or Friday, the price shown is 300,000 with 200,000 struck through; on any other day, 200,000 with no strikethrough.
- Booking on a Thursday charges exactly 300,000 (+ Extra Guests Fee if applicable); booking on a Tuesday charges 200,000.
- Dashboard: merchant deletes the Friday row → mobile stops showing 300,000/badge-mention-of-Friday on Fridays, Thursday still applies.
- Shifts with no weekday overrides configured behave exactly as before (`standard_price_iqd`/`override_weekdays` both empty/null) — regression check.
