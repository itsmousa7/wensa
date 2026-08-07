# Farm Shift Per-Date Price Override Design

**Date:** 2026-08-06
**Status:** Approved

## Problem

`bookings.farm_shifts` holds one row per `(place_id, shift_type)` — a single standing price that applies to every calendar date. A merchant running a farm/chalet wants to charge more (or less) on specific dates — a holiday, a weekend, an event — without changing the shift's everyday price. There is no way to do this today; it would have to be handled manually, outside the app.

## Goal

Let a merchant (or admin) set a price override for a specific `(place, shift_type, date)` combination. When a customer views shifts for that date, the overridden price is what they see and pay; the shift's original standing price is shown struck through alongside it. Scope: **farm shift bookings only**, matching how party pricing was scoped.

## Pattern

No existing per-date *pricing* concept exists anywhere in either codebase, but a per-date *exception* pattern already exists and is architecturally identical: `bookings.place_hours_overrides` — a small table keyed on `(place_id, court_id, date)` that overrides `bookings.place_hours`' weekly schedule, with override-wins-over-weekly-schedule resolution in `bookings._court_hours()`. `farm_shift_price_overrides` mirrors this table shape and resolution style exactly, substituting `price_iqd` for `opens_at/closes_at/is_closed`.

---

## Section 1 — Database

### New migration: `farm_shift_price_overrides`

```sql
CREATE TABLE bookings.farm_shift_price_overrides (
  id         uuid                      PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id   uuid                      NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  shift_type bookings.farm_shift_type  NOT NULL,
  date       date                      NOT NULL,
  price_iqd  integer                   NOT NULL CHECK (price_iqd > 0),
  created_at timestamptz               NOT NULL DEFAULT now(),
  UNIQUE (place_id, shift_type, date)
);

CREATE INDEX farm_shift_price_overrides_place_date_idx
  ON bookings.farm_shift_price_overrides (place_id, date);

ALTER TABLE bookings.farm_shift_price_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY farm_shift_price_overrides_read ON bookings.farm_shift_price_overrides
  FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY farm_shift_price_overrides_merchant_write ON bookings.farm_shift_price_overrides
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );
```

This is a verbatim copy of `farm_shifts`'s own RLS shape (`farm_shifts_read` / `farm_shifts_merchant_write` in `20260427000009_bookings_rls_views.sql:147-155`) — public read, admin-or-own-merchant-staff write. No `public.` PostgREST wrapper table is needed since the dashboard writes to `bookings.farm_shift_price_overrides` directly via PostgREST schema headers (`Content-Profile: bookings`), the same way it already writes to `farm_shifts`.

### `bookings.available_farm_shifts` — resolve the override

Both the `bookings.` function and its `public.` wrapper gain one new output column, `standard_price_iqd integer` (nullable — populated only when an override is active for that date; `NULL` otherwise, meaning "no override, `price_iqd` already is the standard price"). Same `DROP FUNCTION IF EXISTS` + `CREATE OR REPLACE` two-step as `20260806000002` (`RETURNS TABLE`'s column list can't change via plain replace).

Both branches of the existing `IF FOUND AND v_hours.is_closed` / `ELSE` split gain a `LEFT JOIN`:

```sql
LEFT JOIN bookings.farm_shift_price_overrides po
  ON po.place_id = fs.place_id
 AND po.shift_type = fs.shift_type
 AND po.date = p_date
```

and the `price_iqd` column in both `SELECT` lists changes from `fs.price_iqd` to:

```sql
COALESCE(po.price_iqd, fs.price_iqd) AS price_iqd,
CASE WHEN po.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
```

Everything else in this function (availability logic, closure logic, party-pricing columns) is untouched.

### `bookings.create_farm_booking` / `public.create_farm_booking` — charge the override price

New migration, `CREATE OR REPLACE` (no argument-list change this time — `DROP FUNCTION IF EXISTS` not needed). After the existing shift lookup:

```sql
SELECT * INTO v_shift
FROM bookings.farm_shifts
WHERE place_id = p_place_id AND shift_type = p_shift_type;

IF NOT FOUND THEN
  RAISE EXCEPTION 'Shift not configured for this farm' USING ERRCODE = 'P0002';
END IF;
```

add a resolution step:

```sql
DECLARE
  v_price_iqd integer;
  ...
BEGIN
  ...
  SELECT COALESCE(po.price_iqd, v_shift.price_iqd) INTO v_price_iqd
  FROM bookings.farm_shift_price_overrides po
  WHERE po.place_id = p_place_id AND po.shift_type = p_shift_type AND po.date = p_date;

  IF v_price_iqd IS NULL THEN
    v_price_iqd := v_shift.price_iqd;
  END IF;
```

(the `SELECT ... INTO` returns no row and leaves `v_price_iqd` `NULL` when there's no override — the trailing `IF` is the same "no match" guard used nowhere else in this function today, so it's spelled out explicitly rather than relying on an implicit fallback.)

Then every remaining use of `v_shift.price_iqd` in this function — the `v_party_fee` computation is unaffected (it's additive on top of price, doesn't read `price_iqd`), but `amount_iqd` and the returned `jsonb_build_object('amount_iqd', ...)` — changes from `v_shift.price_iqd + v_party_fee` to `v_price_iqd + v_party_fee`, in both the `INSERT ... VALUES` and the final `RETURN jsonb_build_object(...)`.

This guarantees the charged amount always matches what `available_farm_shifts` displayed for that date — same override table, same resolution, no separate code path to drift.

---

## Section 2 — Mobile App (Flutter)

### Model

**File:** `lib/features/booking/domain/models/farm_shift.dart`

Add `@Default(null) int? standardPriceIqd` to the freezed class, parsed from `standard_price_iqd` in `fromJson` (nullable, no default coercion needed — absent/null key means "no override," matching the RPC's `NULL`). Regenerate via `build_runner`.

### UI

**File:** `lib/features/booking/presentation/widgets/shift_card.dart`

When `shift.standardPriceIqd != null`, render the standard price with a strikethrough (`TextDecoration.lineThrough`, muted color) directly above or beside the current price display, plus a small "Special price" / "سعر خاص" badge near the shift label — visually similar to the existing availability `_StatusBadge`, not a new badge system. When `standardPriceIqd` is `null` (the common case), rendering is byte-for-byte identical to today.

No other Flutter file changes: `priceIqd` remains the one effective/charged price everywhere else (`farm_section.dart`'s fee math, `BookingSummaryCard`, `createFarmBooking` submission) — none of that code needs to know an override happened, since the RPC already resolved it before the client ever saw a number.

---

## Section 3 — Merchant + Admin Dashboard (`wansa-admin-dashboard`)

**File:** `src/features/bookings/PlaceBookingTab.tsx`, inside the existing `ShiftPanel` sub-component (lines 354-560).

Each of the three shift cards (day/night/full) gets a new "Price overrides" sub-section, below the existing party-pricing fields, matching that sub-section's collapsed/toggle-revealed visual treatment:

- A **list** of existing overrides for that `(place_id, shift_type)`, fetched via `getApi().get('farm_shift_price_overrides', { place_id, shift_type })` on mount — each row shows the date (localized) and price, with a delete (🗑) icon button calling `getApi().remove('farm_shift_price_overrides', { id })`.
- A **"+ Add override"** button opening a `Modal` (existing shared component) with:
  - A native `<input type="date" min={today}>` — no new date-picker component; the codebase's only calendar-grid picker (`MultiDatePicker` in `MyDiscountsPage.tsx`) is built for multi-select ranges, not a single override date, so introducing it here would be over-engineering for this need.
  - A numeric price input, formatted/parsed the same comma-stripping way `price_iqd` already is elsewhere in this file.
  - A "Save" button calling `getApi().insert('farm_shift_price_overrides', { place_id, shift_type, date, price_iqd })`, then refetching the list and closing the modal. A duplicate `(place_id, shift_type, date)` insert fails on the table's `UNIQUE` constraint — surfaced via the existing `Toast` error pattern, no client-side pre-check needed.

**Translations** (`src/context/translations/en.ts` / `ar.ts`): add `bkgPriceOverrides`, `bkgAddOverride`, `bkgOverrideDate`, `bkgOverridePrice`, `bkgOverrideDelete` keys, following the existing `bkgShift*`/`bkgParty*` naming convention (`en.ts:440-451`, `ar.ts:501-512`).

No RPC/service layer needed on the dashboard side — `getApi()`'s direct table calls already route through `Content-Profile: bookings` (per `TABLE_SCHEMA` in `src/lib/supabase.ts:5-36`, which needs one new entry: `farm_shift_price_overrides: "bookings"`), and RLS (Section 1) enforces the same admin-or-own-merchant-staff write scope every other merchant-editable table in this panel already relies on.

---

## Data Flow

```
Merchant (dashboard) adds an override: place X, Night shift, 2026-08-20, 300,000 IQD
  └─> INSERT bookings.farm_shift_price_overrides (RLS: is_admin() OR is_merchant_staff_of(...))

Customer opens booking screen, picks 2026-08-20
  └─> available_farm_shifts(place_id, '2026-08-20')
        └─> LEFT JOIN farm_shift_price_overrides
              ├─> price_iqd = 300,000 (overridden)
              └─> standard_price_iqd = 200,000 (original, for strikethrough)
  └─> ShiftCard renders: ~~200,000~~ 300,000 IQD · "Special price" badge

Customer proceeds to payment
  └─> createFarmBooking(..., date: '2026-08-20', shiftType: night)
        └─> create-booking edge function → create_farm_booking RPC
              ├─> resolves the SAME override (300,000)
              ├─> amount_iqd = 300,000 + party_fee (if any)
              └─> booking charged at exactly the displayed price
```

## Error Handling

- Dashboard: a duplicate override insert (same place/shift/date) fails the table's `UNIQUE` constraint, surfaced via the existing generic `Toast` error path — no new error UI.
- Mobile: no new error states — the RPC either resolves an override or falls back to the standing price; there's no failure mode a customer can trigger here beyond the existing "shift not configured" / closure paths, which are unaffected.
- If a merchant deletes an override *after* a customer has already loaded the shift list but *before* they pay, `create_farm_booking` simply resolves no override at that moment and charges the standing price — same accepted race already documented for party-pricing toggles in the prior design.

## Testing Notes

- Merchant adds an override for the Night shift, 2026-08-20, 300,000 IQD (standing price 200,000) → mobile shows 2026-08-20's Night shift at 300,000 with 200,000 struck through and a "Special price" badge; Day/Full shifts and every other date show the standing price, no badge.
- Complete a booking on the overridden date → booking's `amount_iqd` is 300,000 (+ Extra Guests Fee if applicable); dashboard's booking list shows the same amount.
- Merchant deletes the override → next fetch of that date shows the standing price again, no badge.
- Attempt to add a second override for the same place/shift/date → dashboard shows a duplicate-key error toast, no row created.
- Farm shifts with no overrides configured anywhere behave exactly as before — regression check (`standard_price_iqd` is `NULL` everywhere, `ShiftCard` renders unchanged).
