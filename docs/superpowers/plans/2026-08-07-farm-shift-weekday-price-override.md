# Farm Shift Weekday-Recurring Price Override Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the just-shipped per-calendar-date shift price override with a per-weekday recurring one (e.g. "every Thursday and Friday costs 300,000"), reusing the existing `bookings.place_hours.weekday` convention (0=Sunday…6=Saturday) already established in this schema, and show customers which weekdays the special price applies to — not just whether today happens to be one.

**Architecture:** `bookings.farm_shift_price_overrides` (date-keyed) is dropped and replaced by `bookings.farm_shift_weekday_overrides` (weekday-keyed, same RLS shape). `available_farm_shifts` and `create_farm_booking` both resolve via `EXTRACT(DOW FROM p_date)` instead of `date = p_date`; `available_farm_shifts` additionally returns the full set of weekdays that have any override configured (`override_weekdays`), independent of the currently-viewed date, so the mobile hint can say "Thu & Fri" rather than only lighting up on the exact matching day. The dashboard's `ShiftPanel` override UI (already built for the date version) gets its date `<input>` swapped for a weekday `<select>`.

**Tech Stack:** Postgres/plpgsql (Supabase MCP, applied live), Flutter (Riverpod, freezed), React/TypeScript dashboard (`wansa-admin-dashboard`).

## Global Constraints

- Do not edit any previously-applied migration file — including the superseded plan's `20260806000004/000005/000006`. All DB changes go in new migration files, applied live via Supabase MCP `apply_migration`.
- `weekday` is `smallint`, `0 = Sunday … 6 = Saturday` — matches `bookings.place_hours.weekday`'s own documented convention exactly (`supabase/migrations/20260427000002_bookings_courts_hours_pricing.sql:26`), Postgres's `EXTRACT(DOW FROM date)`, and JavaScript's `Date.getDay()`. Do not use ISO 8601's Monday=1 convention anywhere in this feature.
- `farm_shift_weekday_overrides` RLS mirrors `farm_shifts`'s own policies exactly: public read, write restricted to `public.is_admin() OR bookings.is_merchant_staff_of(bookings._place_merchant(place_id))`.
- The client never computes or sends a price — `available_farm_shifts` and `create_farm_booking` are the sole source of truth.
- Dashboard: reuse the existing `l.daySun`…`l.daySat` translation keys (`en.ts:273-274`, `ar.ts:334-335`) for weekday names — do not add new day-name keys.
- Work directly on `main` in both repos (the user declined worktree isolation for this session) — commit directly.

---

### Task 1: Database — drop the date table, create the weekday table

**Files:**
- Create: `supabase/migrations/20260807000001_farm_shift_weekday_price_overrides.sql`

**Interfaces:**
- Produces: table `bookings.farm_shift_weekday_overrides(id uuid, place_id uuid, shift_type bookings.farm_shift_type, weekday smallint, price_iqd integer, created_at timestamptz)`, unique on `(place_id, shift_type, weekday)` — read by Task 2 and Task 3's RPCs, written by Task 6's dashboard UI.

- [ ] **Step 1: Write the migration file**

```sql
-- ============================================================
-- Migration: Farm shift weekday-recurring price overrides
-- Date: 2026-08-07
-- ============================================================
--
-- Replaces the per-calendar-date override (farm_shift_price_overrides,
-- added 2026-08-06) with a per-weekday recurring rule — merchants think
-- in terms of "Thursdays and Fridays cost more," not specific dates. The
-- date-keyed table holds no real merchant data (only test rows, already
-- cleaned up) and its dashboard UI never reached a merchant, so it's
-- dropped outright rather than migrated.
--
-- weekday follows bookings.place_hours.weekday's own convention:
-- 0 = Sunday … 6 = Saturday (matches Postgres EXTRACT(DOW) and JS
-- Date.getDay()) — see supabase/migrations/20260427000002_bookings_courts_hours_pricing.sql.

DROP TABLE IF EXISTS bookings.farm_shift_price_overrides;

CREATE TABLE bookings.farm_shift_weekday_overrides (
  id         uuid                      PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id   uuid                      NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  shift_type bookings.farm_shift_type  NOT NULL,
  weekday    smallint                  NOT NULL CHECK (weekday BETWEEN 0 AND 6),
  price_iqd  integer                   NOT NULL CHECK (price_iqd > 0),
  created_at timestamptz               NOT NULL DEFAULT now(),
  UNIQUE (place_id, shift_type, weekday)
);

CREATE INDEX farm_shift_weekday_overrides_place_idx
  ON bookings.farm_shift_weekday_overrides (place_id);

ALTER TABLE bookings.farm_shift_weekday_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY farm_shift_weekday_overrides_read ON bookings.farm_shift_weekday_overrides
  FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY farm_shift_weekday_overrides_merchant_write ON bookings.farm_shift_weekday_overrides
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

- [ ] **Step 2: Apply the migration live via Supabase MCP**

Use `mcp__plugin_supabase_supabase__apply_migration` with `name: farm_shift_weekday_price_overrides` and the SQL from Step 1.

- [ ] **Step 3: Verify the old table is gone and the new one exists correctly**

Run via `mcp__plugin_supabase_supabase__execute_sql`:

```sql
SELECT c.relname FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'bookings' AND c.relname IN ('farm_shift_price_overrides', 'farm_shift_weekday_overrides');

SELECT c.relrowsecurity FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'bookings' AND c.relname = 'farm_shift_weekday_overrides';

SELECT polname FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
WHERE c.relname = 'farm_shift_weekday_overrides'
ORDER BY polname;
```

Expected: first query returns exactly one row, `farm_shift_weekday_overrides` (the old table is gone). Second query: `true`. Third query: exactly two rows, `farm_shift_weekday_overrides_merchant_write`, `farm_shift_weekday_overrides_read`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260807000001_farm_shift_weekday_price_overrides.sql
git commit -m "feat(db): replace per-date shift price overrides with per-weekday recurring overrides"
```

---

### Task 2: Database — `available_farm_shifts` resolves weekday overrides + returns the full override-day set

**Files:**
- Create: `supabase/migrations/20260807000002_available_farm_shifts_weekday_override.sql`

**Interfaces:**
- Consumes: `bookings.farm_shift_weekday_overrides` (Task 1).
- Produces: `bookings.available_farm_shifts(p_place_id, p_date)` / `public.available_farm_shifts(p_place_id, p_date)` return `standard_price_iqd integer` (as before, non-null only when today's weekday has an override) AND a new `override_weekdays smallint[]` (the full set of weekdays with any override for that shift, regardless of `p_date` — `NULL`/empty when none configured). Consumed by Task 4 (Flutter model) via `override_weekdays`.

- [ ] **Step 1: Write the migration file**

```sql
-- ============================================================
-- Migration: Resolve weekday price overrides in available_farm_shifts
-- Date: 2026-08-07
-- ============================================================
--
-- price_iqd becomes the effective price for p_date's weekday.
-- standard_price_iqd is populated only when that weekday has an
-- override (unchanged meaning from the date-keyed version). New:
-- override_weekdays returns EVERY weekday with an override configured
-- for the shift, independent of p_date, so the client can show "Special
-- price · Thu & Fri" even when the customer isn't currently looking at
-- a Thursday or Friday.

DROP FUNCTION IF EXISTS bookings.available_farm_shifts(uuid, date);

CREATE OR REPLACE FUNCTION bookings.available_farm_shifts(p_place_id uuid, p_date date)
RETURNS TABLE(
  place_id uuid,
  shift_type bookings.farm_shift_type,
  starts_time time without time zone,
  ends_time time without time zone,
  price_iqd integer,
  standard_price_iqd integer,
  override_weekdays smallint[],
  is_available boolean,
  is_closed boolean,
  party_enabled boolean,
  party_included_persons integer,
  party_flat_fee_iqd integer,
  party_extra_person_fee_iqd integer
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'bookings', 'public'
AS $function$
DECLARE
  v_hours         RECORD;
  v_now_baghdad   timestamp;
  v_today_baghdad date;
  v_weekday       smallint;
BEGIN
  v_now_baghdad   := (NOW() AT TIME ZONE 'Asia/Baghdad');
  v_today_baghdad := v_now_baghdad::date;
  v_weekday       := EXTRACT(DOW FROM p_date)::smallint;

  SELECT * INTO v_hours
  FROM bookings._court_hours(p_place_id, NULL::uuid, p_date);

  IF FOUND AND v_hours.is_closed THEN
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        COALESCE(wo.price_iqd, fs.price_iqd) AS price_iqd,
        CASE WHEN wo.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
        (SELECT array_agg(wo2.weekday ORDER BY wo2.weekday)
         FROM bookings.farm_shift_weekday_overrides wo2
         WHERE wo2.place_id = fs.place_id AND wo2.shift_type = fs.shift_type) AS override_weekdays,
        false AS is_available,
        true  AS is_closed,
        fs.party_enabled,
        fs.party_included_persons,
        fs.party_flat_fee_iqd,
        fs.party_extra_person_fee_iqd
      FROM bookings.farm_shifts fs
      LEFT JOIN bookings.farm_shift_weekday_overrides wo
        ON wo.place_id = fs.place_id
       AND wo.shift_type = fs.shift_type
       AND wo.weekday = v_weekday
      WHERE fs.place_id = p_place_id
      ORDER BY fs.starts_time;
  ELSE
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        COALESCE(wo.price_iqd, fs.price_iqd) AS price_iqd,
        CASE WHEN wo.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
        (SELECT array_agg(wo2.weekday ORDER BY wo2.weekday)
         FROM bookings.farm_shift_weekday_overrides wo2
         WHERE wo2.place_id = fs.place_id AND wo2.shift_type = fs.shift_type) AS override_weekdays,
        -- On today: block the shift once its start time has passed.
        -- For 'full' day: also block if the earliest day-shift start has passed,
        -- since a full-day booking can't start mid-day (mirrors Flutter app behaviour).
        (
          p_date > v_today_baghdad
          OR (
            v_now_baghdad::time < fs.starts_time
            AND (
              fs.shift_type <> 'full'
              OR NOT EXISTS (
                SELECT 1 FROM bookings.farm_shifts ds
                WHERE ds.place_id = p_place_id
                  AND ds.shift_type = 'day'
                  AND v_now_baghdad::time >= ds.starts_time
              )
            )
          )
        )
        AND NOT EXISTS (
          SELECT 1
          FROM bookings.bookings b
          WHERE b.place_id = p_place_id
            AND b.category = 'farm'
            AND b.status   = 'confirmed'
            AND tstzrange(b.starts_at, b.ends_at, '[)') &&
                tstzrange(
                  (p_date::text || ' ' || fs.starts_time::text)::timestamp
                    AT TIME ZONE 'Asia/Baghdad',
                  CASE WHEN fs.ends_time <= fs.starts_time
                    THEN ((p_date + 1)::text || ' ' || fs.ends_time::text)::timestamp
                           AT TIME ZONE 'Asia/Baghdad'
                    ELSE (p_date::text || ' ' || fs.ends_time::text)::timestamp
                           AT TIME ZONE 'Asia/Baghdad'
                  END,
                  '[)'
                )
        ) AS is_available,
        false AS is_closed,
        fs.party_enabled,
        fs.party_included_persons,
        fs.party_flat_fee_iqd,
        fs.party_extra_person_fee_iqd
      FROM bookings.farm_shifts fs
      LEFT JOIN bookings.farm_shift_weekday_overrides wo
        ON wo.place_id = fs.place_id
       AND wo.shift_type = fs.shift_type
       AND wo.weekday = v_weekday
      WHERE fs.place_id = p_place_id
      ORDER BY fs.starts_time;
  END IF;
END;
$function$;

DROP FUNCTION IF EXISTS public.available_farm_shifts(uuid, date);

CREATE OR REPLACE FUNCTION public.available_farm_shifts(p_place_id uuid, p_date date)
RETURNS TABLE(
  place_id uuid,
  shift_type text,
  starts_time time without time zone,
  ends_time time without time zone,
  price_iqd integer,
  standard_price_iqd integer,
  override_weekdays smallint[],
  is_available boolean,
  is_closed boolean,
  party_enabled boolean,
  party_included_persons integer,
  party_flat_fee_iqd integer,
  party_extra_person_fee_iqd integer
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'bookings', 'public'
AS $function$
  SELECT
    place_id,
    shift_type::text,
    starts_time,
    ends_time,
    price_iqd,
    standard_price_iqd,
    override_weekdays,
    is_available,
    is_closed,
    party_enabled,
    party_included_persons,
    party_flat_fee_iqd,
    party_extra_person_fee_iqd
  FROM bookings.available_farm_shifts(p_place_id, p_date);
$function$;

GRANT EXECUTE ON FUNCTION public.available_farm_shifts(uuid, date)
  TO anon, authenticated;
```

- [ ] **Step 2: Apply the migration live via Supabase MCP**

Use `mcp__plugin_supabase_supabase__apply_migration` with `name: available_farm_shifts_weekday_override` and the SQL from Step 1.

- [ ] **Step 3: Verify with a real (but harmless) test override**

Find one existing `(place_id, shift_type)` pair and its price via `mcp__plugin_supabase_supabase__execute_sql`:

```sql
SELECT place_id, shift_type, price_iqd FROM bookings.farm_shifts LIMIT 1;
```

Using that `place_id`/`shift_type` (call them `<PID>`/`<TYPE>`, base price `<BASE>`), pick a weekday number 0-6 (call it `<WD>`) and find two dates you can compute: one date that falls ON weekday `<WD>` (`<MATCH_DATE>`), one that does NOT (`<OTHER_DATE>`) — e.g. run `SELECT to_char(d, 'YYYY-MM-DD'), extract(dow from d) FROM generate_series('2099-01-01'::date, '2099-01-07'::date, '1 day') d;` to pick both from a safe far-future week. Then:

```sql
INSERT INTO bookings.farm_shift_weekday_overrides (place_id, shift_type, weekday, price_iqd)
VALUES ('<PID>', '<TYPE>', <WD>, <BASE> + 12345);

SELECT place_id, shift_type, price_iqd, standard_price_iqd, override_weekdays
FROM bookings.available_farm_shifts('<PID>', '<MATCH_DATE>')
WHERE shift_type = '<TYPE>';
-- Expected: price_iqd = <BASE> + 12345, standard_price_iqd = <BASE>, override_weekdays = {<WD>}

SELECT place_id, shift_type, price_iqd, standard_price_iqd, override_weekdays
FROM bookings.available_farm_shifts('<PID>', '<OTHER_DATE>')
WHERE shift_type = '<TYPE>';
-- Expected: price_iqd = <BASE>, standard_price_iqd IS NULL, override_weekdays = {<WD>} (still shows
-- the day is special somewhere in the week, even though today isn't it)

DELETE FROM bookings.farm_shift_weekday_overrides
WHERE place_id = '<PID>' AND shift_type = '<TYPE>' AND weekday = <WD>;
```

Confirm the DELETE removed exactly 1 row (re-run the first SELECT and confirm `standard_price_iqd IS NULL` and `override_weekdays IS NULL` again) so no test data is left behind.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260807000002_available_farm_shifts_weekday_override.sql
git commit -m "feat(db): resolve weekday price overrides in available_farm_shifts"
```

---

### Task 3: Database — `create_farm_booking` charges the weekday-resolved price

**Files:**
- Create: `supabase/migrations/20260807000003_create_farm_booking_weekday_override.sql`

**Interfaces:**
- Consumes: `bookings.farm_shift_weekday_overrides` (Task 1).
- Produces: `bookings.create_farm_booking(...)` now charges the resolved (possibly weekday-overridden) price. Signature unchanged — `public.create_farm_booking` needs no edit.

- [ ] **Step 1: Write the migration file**

Plain `CREATE OR REPLACE` — signature and `RETURNS jsonb` are unchanged, only the price-resolution `WHERE` clause changes from a date lookup to a weekday lookup.

```sql
-- ============================================================
-- Migration: Charge weekday price overrides in create_farm_booking
-- Date: 2026-08-07
-- ============================================================
--
-- Same v_price_iqd resolution as the date-keyed version (2026-08-06),
-- but keyed on EXTRACT(DOW FROM p_date) against
-- farm_shift_weekday_overrides instead of an exact date match — so the
-- amount charged always matches what available_farm_shifts displayed
-- for that date's weekday.

CREATE OR REPLACE FUNCTION bookings.create_farm_booking(
  p_place_id       uuid,
  p_date           date,
  p_shift_type     bookings.farm_shift_type,
  p_party_size     integer DEFAULT NULL,
  p_bringing_party boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $$
DECLARE
  v_user_id       uuid := auth.uid();
  v_merchant_id   uuid;
  v_shift         bookings.farm_shifts%ROWTYPE;
  v_price_iqd     integer;
  v_starts_at     timestamptz;
  v_ends_at       timestamptz;
  v_hold_until    timestamptz;
  v_booking_id    uuid;
  v_qr_token      uuid;
  v_tz            text := 'Asia/Baghdad';
  v_party_fee     integer := 0;
  v_category_data jsonb;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  -- Look up shift definition
  SELECT * INTO v_shift
  FROM bookings.farm_shifts
  WHERE place_id = p_place_id AND shift_type = p_shift_type;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shift not configured for this farm' USING ERRCODE = 'P0002';
  END IF;

  -- Resolve the effective price for this date's weekday — an override
  -- wins if one exists for (place_id, shift_type, weekday of p_date),
  -- otherwise the standing price.
  SELECT wo.price_iqd INTO v_price_iqd
  FROM bookings.farm_shift_weekday_overrides wo
  WHERE wo.place_id = p_place_id
    AND wo.shift_type = p_shift_type
    AND wo.weekday = EXTRACT(DOW FROM p_date)::smallint;

  IF v_price_iqd IS NULL THEN
    v_price_iqd := v_shift.price_iqd;
  END IF;

  IF p_party_size IS NOT NULL THEN
    IF NOT v_shift.party_enabled THEN
      RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
    END IF;
    IF p_party_size < 1 THEN
      RAISE EXCEPTION 'party_size must be at least 1' USING ERRCODE = 'P0004';
    END IF;
  END IF;

  IF p_bringing_party AND NOT v_shift.party_enabled THEN
    RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
  END IF;

  v_party_fee := (CASE WHEN p_bringing_party THEN v_shift.party_flat_fee_iqd ELSE 0 END)
    + GREATEST(0, COALESCE(p_party_size, 1) - v_shift.party_included_persons)
        * v_shift.party_extra_person_fee_iqd;

  -- Build UTC timestamptz from local date + time
  v_starts_at := (p_date || ' ' || v_shift.starts_time)::timestamp
                   AT TIME ZONE v_tz;

  -- Handle overnight shift (ends_time <= starts_time means next calendar day)
  IF v_shift.ends_time <= v_shift.starts_time THEN
    v_ends_at := ((p_date + 1) || ' ' || v_shift.ends_time)::timestamp
                   AT TIME ZONE v_tz;
  ELSE
    v_ends_at := (p_date || ' ' || v_shift.ends_time)::timestamp
                   AT TIME ZONE v_tz;
  END IF;

  v_merchant_id := bookings._place_merchant(p_place_id);
  v_hold_until  := now() + interval '60 seconds';

  v_category_data := jsonb_build_object('shift_type', p_shift_type);
  IF p_party_size IS NOT NULL THEN
    v_category_data := v_category_data || jsonb_build_object('party_size', p_party_size);
  END IF;
  IF p_bringing_party THEN
    v_category_data := v_category_data || jsonb_build_object('bringing_party', true);
  END IF;
  IF v_party_fee > 0 THEN
    v_category_data := v_category_data || jsonb_build_object('party_fee_iqd', v_party_fee);
  END IF;

  INSERT INTO bookings.bookings (
    user_id, merchant_id, place_id, category, status,
    starts_at, ends_at, amount_iqd, hold_until, category_data
  ) VALUES (
    v_user_id, v_merchant_id, p_place_id, 'farm', 'pending',
    v_starts_at, v_ends_at, v_price_iqd + v_party_fee, v_hold_until,
    v_category_data
  )
  RETURNING id, qr_token INTO v_booking_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_booking_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_price_iqd + v_party_fee,
    'hold_until', v_hold_until
  );
END;
$$;
```

- [ ] **Step 2: Apply the migration live via Supabase MCP**

Use `mcp__plugin_supabase_supabase__apply_migration` with `name: create_farm_booking_weekday_override` and the SQL from Step 1.

- [ ] **Step 3: Verify the function definition and the resolution subquery**

`auth.uid()` blocks direct invocation via `execute_sql`, so verify the deployed SQL text instead:

```sql
SELECT pg_get_functiondef(p.oid) LIKE '%farm_shift_weekday_overrides%' AS has_weekday_lookup,
       pg_get_functiondef(p.oid) LIKE '%EXTRACT(DOW FROM p_date)%' AS uses_dow_extract,
       pg_get_functiondef(p.oid) LIKE '%v_price_iqd + v_party_fee%' AS charges_resolved_price,
       pg_get_functiondef(p.oid) LIKE '%farm_shift_price_overrides%' AS still_references_old_table
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'bookings' AND p.proname = 'create_farm_booking';
```

Expected: `has_weekday_lookup = true`, `uses_dow_extract = true`, `charges_resolved_price = true`, `still_references_old_table = false`.

Then sanity-check the resolution subquery in isolation using the same test place/shift/weekday pattern as Task 2 Step 3:

```sql
INSERT INTO bookings.farm_shift_weekday_overrides (place_id, shift_type, weekday, price_iqd)
VALUES ('<PID>', '<TYPE>', <WD>, <BASE> + 12345);

SELECT wo.price_iqd FROM bookings.farm_shift_weekday_overrides wo
WHERE wo.place_id = '<PID>' AND wo.shift_type = '<TYPE>' AND wo.weekday = EXTRACT(DOW FROM '<MATCH_DATE>'::date)::smallint;
-- Expected: <BASE> + 12345

DELETE FROM bookings.farm_shift_weekday_overrides
WHERE place_id = '<PID>' AND shift_type = '<TYPE>' AND weekday = <WD>;
```

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260807000003_create_farm_booking_weekday_override.sql
git commit -m "feat(db): charge weekday price overrides in create_farm_booking"
```

---

### Task 4: Mobile — `FarmShift.overrideWeekdays`

**Files:**
- Modify: `lib/features/booking/domain/models/farm_shift.dart`
- Modify: `test/features/booking/domain/models/farm_shift_test.dart`

**Interfaces:**
- Consumes: `override_weekdays` JSON key from `available_farm_shifts` (Task 2).
- Produces: `FarmShift.overrideWeekdays` (`List<int>?`, `null` when no override configured for the shift) — consumed by Task 5 (`ShiftCard`).

- [ ] **Step 1: Write the failing test**

Add a new group to `test/features/booking/domain/models/farm_shift_test.dart`, after the existing `'FarmShift.fromJson price override'` group (before the closing `}` of `main()`):

```dart
  group('FarmShift.fromJson override weekdays', () {
    const baseJson = {
      'place_id': 'place-abc',
      'shift_type': 'day',
      'starts_time': '08:00:00',
      'ends_time': '18:00:00',
      'price_iqd': 250000,
    };

    test('parses override_weekdays when present', () {
      final shift = FarmShift.fromJson({
        ...baseJson,
        'override_weekdays': [4, 5],
      });
      expect(shift.overrideWeekdays, [4, 5]);
    });

    test('overrideWeekdays defaults to null when absent', () {
      final shift = FarmShift.fromJson(baseJson);
      expect(shift.overrideWeekdays, isNull);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/booking/domain/models/farm_shift_test.dart`
Expected: FAIL — `The getter 'overrideWeekdays' isn't defined for the type 'FarmShift'`

- [ ] **Step 3: Add the field to the model**

In `lib/features/booking/domain/models/farm_shift.dart`, change the factory constructor from:

```dart
  const factory FarmShift({
    @Default('') String placeId,
    @Default(FarmShiftType.day) FarmShiftType shiftType,
    @Default('') String startsTime,
    @Default('') String endsTime,
    @Default(0) int priceIqd,
    int? standardPriceIqd,
    @Default(true) bool isAvailable,
    @Default(false) bool isClosed,
    @Default(false) bool partyEnabled,
    @Default(1) int partyIncludedPersons,
    @Default(0) int partyFlatFeeIqd,
    @Default(0) int partyExtraPersonFeeIqd,
  }) = _FarmShift;
```

to:

```dart
  const factory FarmShift({
    @Default('') String placeId,
    @Default(FarmShiftType.day) FarmShiftType shiftType,
    @Default('') String startsTime,
    @Default('') String endsTime,
    @Default(0) int priceIqd,
    int? standardPriceIqd,
    List<int>? overrideWeekdays,
    @Default(true) bool isAvailable,
    @Default(false) bool isClosed,
    @Default(false) bool partyEnabled,
    @Default(1) int partyIncludedPersons,
    @Default(0) int partyFlatFeeIqd,
    @Default(0) int partyExtraPersonFeeIqd,
  }) = _FarmShift;
```

and add the JSON parsing line to `fromJson` (after `standardPriceIqd:`, before `isAvailable:`):

```dart
  factory FarmShift.fromJson(Map<String, dynamic> json) => FarmShift(
    placeId: json['place_id'] ?? '',
    shiftType: FarmShiftTypeFromString.fromString(json['shift_type'] ?? ''),
    startsTime: json['starts_time'] ?? '',
    endsTime: json['ends_time'] ?? '',
    priceIqd: (json['price_iqd'] as num?)?.toInt() ?? 0,
    standardPriceIqd: (json['standard_price_iqd'] as num?)?.toInt(),
    overrideWeekdays: (json['override_weekdays'] as List?)
        ?.map((e) => (e as num).toInt())
        .toList(),
    isAvailable: (json['is_available'] as bool?) ?? true,
    isClosed: (json['is_closed'] as bool?) ?? false,
    partyEnabled: (json['party_enabled'] as bool?) ?? false,
    partyIncludedPersons: (json['party_included_persons'] as num?)?.toInt() ?? 1,
    partyFlatFeeIqd: (json['party_flat_fee_iqd'] as num?)?.toInt() ?? 0,
    partyExtraPersonFeeIqd: (json['party_extra_person_fee_iqd'] as num?)?.toInt() ?? 0,
  );
```

- [ ] **Step 4: Regenerate the freezed/json code**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: completes without error, regenerating `farm_shift.freezed.dart` and `farm_shift.g.dart` with the new `overrideWeekdays` field.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/booking/domain/models/farm_shift_test.dart`
Expected: PASS (all tests in the file, including the 2 new ones)

- [ ] **Step 6: Commit**

```bash
git add lib/features/booking/domain/models/farm_shift.dart lib/features/booking/domain/models/farm_shift.freezed.dart lib/features/booking/domain/models/farm_shift.g.dart test/features/booking/domain/models/farm_shift_test.dart
git commit -m "feat(booking): parse override_weekdays on FarmShift for weekday overrides"
```

---

### Task 5: Mobile — `ShiftCard` shows which weekdays the special price applies to

**Files:**
- Modify: `lib/features/booking/presentation/widgets/shift_card.dart`
- Modify: `test/features/booking/presentation/widgets/shift_card_test.dart`

**Interfaces:**
- Consumes: `FarmShift.overrideWeekdays` (Task 4).

- [ ] **Step 1: Write the failing tests**

Add a new group to `test/features/booking/presentation/widgets/shift_card_test.dart`, after the existing `group('ShiftCard price override', ...)` block (before the final closing `}` of `main()`):

```dart
  group('ShiftCard override weekday hint', () {
    testWidgets('appends the weekday list to the badge when overrideWeekdays is set',
        (tester) async {
      const shift = FarmShift(
        placeId: 'p1',
        shiftType: FarmShiftType.day,
        startsTime: '08:00:00',
        endsTime: '18:00:00',
        priceIqd: 300000,
        standardPriceIqd: 200000,
        overrideWeekdays: [4, 5],
        isAvailable: true,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShiftCard(
            shift: shift,
            isSelected: false,
            availability: SlotAvailability.available,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('Special price · Thu & Fri'), findsOneWidget);
    });

    testWidgets('badge shows plain "Special price" when overrideWeekdays is null',
        (tester) async {
      const shift = FarmShift(
        placeId: 'p1',
        shiftType: FarmShiftType.day,
        startsTime: '08:00:00',
        endsTime: '18:00:00',
        priceIqd: 300000,
        standardPriceIqd: 200000,
        isAvailable: true,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShiftCard(
            shift: shift,
            isSelected: false,
            availability: SlotAvailability.available,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('Special price'), findsOneWidget);
      expect(find.text('Special price · Thu & Fri'), findsNothing);
    });
  });
```

Note: this second test reuses the exact scenario the earlier `'ShiftCard price override'` group already covers (badge with no weekday list) — it's repeated here deliberately so this new group is self-contained and readable independent of the other one, not to duplicate assertions carelessly.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/booking/presentation/widgets/shift_card_test.dart`
Expected: FAIL — `find.text('Special price · Thu & Fri')` finds nothing.

- [ ] **Step 3: Add the weekday formatter and extend the badge text**

In `lib/features/booking/presentation/widgets/shift_card.dart`, add a private helper near `_formattedStandardPrice()`:

```dart
  // 0=Sunday … 6=Saturday — matches bookings.place_hours.weekday's
  // convention and this table's own `weekday` column.
  static const _enWeekdayAbbr = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _arWeekdayAbbr = [
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
  ];

  String _overrideDaysLabel({required bool isAr}) {
    final days = shift.overrideWeekdays;
    if (days == null || days.isEmpty) return '';
    final names = days
        .map((d) => isAr ? _arWeekdayAbbr[d] : _enWeekdayAbbr[d])
        .toList();
    return isAr ? names.join(' و') : names.join(' & ');
  }
```

Then change the badge `Text` widget (inside the existing `if (shift.standardPriceIqd != null) ...[` block) from:

```dart
                      child: Text(
                        isAr ? 'سعر خاص' : 'Special price',
                        style: (tt.labelSmall ?? const TextStyle()).copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
```

to:

```dart
                      child: Text(
                        (shift.overrideWeekdays?.isNotEmpty ?? false)
                            ? (isAr
                                ? 'سعر خاص · ${_overrideDaysLabel(isAr: true)}'
                                : 'Special price · ${_overrideDaysLabel(isAr: false)}')
                            : (isAr ? 'سعر خاص' : 'Special price'),
                        style: (tt.labelSmall ?? const TextStyle()).copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/booking/presentation/widgets/shift_card_test.dart`
Expected: PASS (all tests, including the 2 new ones and the pre-existing `'ShiftCard price override'` group unchanged)

- [ ] **Step 5: Run the full booking test directory to check for regressions**

Run: `flutter test test/features/booking/`
Expected: PASS, all tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/booking/presentation/widgets/shift_card.dart test/features/booking/presentation/widgets/shift_card_test.dart
git commit -m "feat(booking): show which weekdays trigger the special price on ShiftCard"
```

---

### Task 6: Dashboard — rename schema routing, rename the "Date" key to "Day", and rework `ShiftPanel`'s override UI

**Files:**
- Modify: `wansa-admin-dashboard/src/lib/supabase.ts`
- Modify: `wansa-admin-dashboard/src/context/translations/en.ts`
- Modify: `wansa-admin-dashboard/src/context/translations/ar.ts`
- Modify: `wansa-admin-dashboard/src/features/bookings/PlaceBookingTab.tsx`

**Interfaces:**
- Consumes: `getApi().get/insert/remove('farm_shift_weekday_overrides', ...)`, `l.bkgOverrideDay`, `l.daySun`…`l.daySat` (pre-existing).
- Produces: a working weekday-based override UI in `ShiftPanel`.

This task bundles the schema/translation rename with the UI rework that depends on them (rather than splitting them across two tasks) because they touch the same three call sites in `PlaceBookingTab.tsx` — splitting them would leave `tsc` genuinely broken between tasks instead of just between steps within one task.

- [ ] **Step 1: Rename the schema routing entry**

In `wansa-admin-dashboard/src/lib/supabase.ts`, change:

```ts
    event_tiers: "bookings", place_hours: "bookings", place_hours_overrides: "bookings",
    seat_map_requests: "bookings", user_payment_tokens: "bookings",
    farm_shift_price_overrides: "bookings",
```

to:

```ts
    event_tiers: "bookings", place_hours: "bookings", place_hours_overrides: "bookings",
    seat_map_requests: "bookings", user_payment_tokens: "bookings",
    farm_shift_weekday_overrides: "bookings",
```

- [ ] **Step 2: Rename the English translation key**

In `wansa-admin-dashboard/src/context/translations/en.ts`, change:

```ts
        bkgOverrideDate: "Date",
```

to:

```ts
        bkgOverrideDay: "Day",
```

(this line sits between `bkgAddOverride: "Add Override",` and `bkgOverridePrice: "Price (IQD)",` — only this one line changes, nothing else in the surrounding block)

- [ ] **Step 3: Rename the Arabic translation key**

In `wansa-admin-dashboard/src/context/translations/ar.ts`, change:

```ts
        bkgOverrideDate: "التاريخ",
```

to:

```ts
        bkgOverrideDay: "اليوم",
```

(same position, between `bkgAddOverride: "إضافة سعر مخصص",` and `bkgOverridePrice: "السعر (د.ع)",`)

- [ ] **Step 4: Change the `PriceOverride` interface**

Change:

```ts
interface PriceOverride { id: string; place_id: string; shift_type: "day" | "night" | "full"; date: string; price_iqd: number; }
```

to:

```ts
interface PriceOverride { id: string; place_id: string; shift_type: "day" | "night" | "full"; weekday: number; price_iqd: number; }

const WEEKDAY_KEYS = ["daySun", "dayMon", "dayTue", "dayWed", "dayThu", "dayFri", "daySat"] as const;
```

- [ ] **Step 5: Rename the override state**

Change:

```ts
    const [overrideModalType, setOverrideModalType] = useState<"day" | "night" | "full" | null>(null);
    const [overrideDate, setOverrideDate] = useState("");
    const [overridePrice, setOverridePrice] = useState("");
```

to:

```ts
    const [overrideModalType, setOverrideModalType] = useState<"day" | "night" | "full" | null>(null);
    const [overrideWeekday, setOverrideWeekday] = useState("");
    const [overridePrice, setOverridePrice] = useState("");
```

- [ ] **Step 6: Update `fetchData`'s override query**

Change:

```ts
            const overrideRows = await getApi().get<PriceOverride>(
                "farm_shift_price_overrides",
                `&place_id=eq.${placeId}&order=date.asc`,
            );
```

to:

```ts
            const overrideRows = await getApi().get<PriceOverride>(
                "farm_shift_weekday_overrides",
                `&place_id=eq.${placeId}&order=weekday.asc`,
            );
```

- [ ] **Step 7: Update `addOverride`**

Change:

```ts
    const addOverride = async () => {
        if (!overrideModalType || !overrideDate || !overridePrice) return;
        setOverrideSaving(true);
        try {
            await getApi().insert("farm_shift_price_overrides", {
                place_id: placeId,
                shift_type: overrideModalType,
                date: overrideDate,
                price_iqd: parseFloat(overridePrice) || 0,
            });
            setOverrideModalType(null);
            setOverrideDate("");
            setOverridePrice("");
            await fetchData();
        } catch (e: any) {
            setToast("Error: " + e.message); setToastErr(true);
        }
        setOverrideSaving(false);
    };
```

to:

```ts
    const addOverride = async () => {
        if (!overrideModalType || overrideWeekday === "" || !overridePrice) return;
        setOverrideSaving(true);
        try {
            await getApi().insert("farm_shift_weekday_overrides", {
                place_id: placeId,
                shift_type: overrideModalType,
                weekday: parseInt(overrideWeekday, 10),
                price_iqd: parseFloat(overridePrice) || 0,
            });
            setOverrideModalType(null);
            setOverrideWeekday("");
            setOverridePrice("");
            await fetchData();
        } catch (e: any) {
            setToast("Error: " + e.message); setToastErr(true);
        }
        setOverrideSaving(false);
    };
```

- [ ] **Step 8: Update `deleteOverride`'s table name**

Change:

```ts
    const deleteOverride = async (id: string) => {
        try {
            await getApi().remove("farm_shift_price_overrides", id);
            await fetchData();
        } catch (e: any) {
            setToast("Error: " + e.message); setToastErr(true);
        }
    };
```

to:

```ts
    const deleteOverride = async (id: string) => {
        try {
            await getApi().remove("farm_shift_weekday_overrides", id);
            await fetchData();
        } catch (e: any) {
            setToast("Error: " + e.message); setToastErr(true);
        }
    };
```

- [ ] **Step 9: Update the "+ Add Override" button's reset call**

Change:

```ts
                                        <Btn variant="secondary" size="sm" onClick={() => { setOverrideModalType(type); setOverrideDate(""); setOverridePrice(""); }}>
                                            + {l.bkgAddOverride}
                                        </Btn>
```

to:

```ts
                                        <Btn variant="secondary" size="sm" onClick={() => { setOverrideModalType(type); setOverrideWeekday(""); setOverridePrice(""); }}>
                                            + {l.bkgAddOverride}
                                        </Btn>
```

- [ ] **Step 10: Update the override list row to show the weekday name**

Change:

```ts
                                            {overrides.filter(o => o.shift_type === type).map(o => (
                                                <div key={o.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: FS.sm, padding: "6px 10px", background: C.bg, borderRadius: R.sm }}>
                                                    <span style={{ color: C.text }}>{o.date}</span>
                                                    <span style={{ color: color, fontWeight: 700 }}>{Number(o.price_iqd).toLocaleString('en-US')} IQD</span>
                                                    <button onClick={() => deleteOverride(o.id)} style={{ background: "none", border: "none", cursor: "pointer", color: C.red, fontSize: FS.sm }}>
                                                        {l.bkgOverrideDelete}
                                                    </button>
                                                </div>
                                            ))}
```

to:

```ts
                                            {overrides.filter(o => o.shift_type === type).map(o => (
                                                <div key={o.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: FS.sm, padding: "6px 10px", background: C.bg, borderRadius: R.sm }}>
                                                    <span style={{ color: C.text }}>{l[WEEKDAY_KEYS[o.weekday]]}</span>
                                                    <span style={{ color: color, fontWeight: 700 }}>{Number(o.price_iqd).toLocaleString('en-US')} IQD</span>
                                                    <button onClick={() => deleteOverride(o.id)} style={{ background: "none", border: "none", cursor: "pointer", color: C.red, fontSize: FS.sm }}>
                                                        {l.bkgOverrideDelete}
                                                    </button>
                                                </div>
                                            ))}
```

- [ ] **Step 11: Replace the modal's date input with a weekday select**

Change:

```tsx
                        <div>
                            <FieldLabel>{l.bkgOverrideDate}</FieldLabel>
                            <input type="date" min={new Date().toISOString().slice(0, 10)}
                                value={overrideDate}
                                onChange={e => setOverrideDate(e.target.value)}
                                style={{ padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                            />
                        </div>
```

to:

```tsx
                        <div>
                            <FieldLabel>{l.bkgOverrideDay}</FieldLabel>
                            <select value={overrideWeekday}
                                onChange={e => setOverrideWeekday(e.target.value)}
                                style={{ padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                            >
                                <option value="" disabled>—</option>
                                {WEEKDAY_KEYS.map((key, i) => (
                                    <option key={i} value={i}>{l[key]}</option>
                                ))}
                            </select>
                        </div>
```

- [ ] **Step 12: Update the modal's "Add Override" button disabled condition**

Change:

```tsx
                            <Btn variant="accent" onClick={addOverride} loading={overrideSaving} disabled={!overrideDate || !overridePrice}>
                                {l.bkgAddOverride}
                            </Btn>
```

to:

```tsx
                            <Btn variant="accent" onClick={addOverride} loading={overrideSaving} disabled={overrideWeekday === "" || !overridePrice}>
                                {l.bkgAddOverride}
                            </Btn>
```

- [ ] **Step 13: Type-check**

Run: `cd wansa-admin-dashboard && npx tsc --noEmit`
Expected: no errors from any of the four files touched in this task.

- [ ] **Step 14: Manual smoke check**

Run: `cd wansa-admin-dashboard && npm run dev` (check `package.json`'s `scripts` for the exact command if this doesn't match), open the dashboard in a browser, navigate to a farm place's booking tab, expand a shift card, and confirm:
- The "Price Overrides" section renders with a "—" placeholder and an "+ Add Override" button (as before).
- Clicking "+ Add Override" opens the modal with a weekday `<select>` (Sunday–Saturday) instead of a date picker, and a price input.
- Submitting adds a row to the list showing the weekday name (localized) and formatted price.
- Adding a second override for the same weekday on the same shift fails with a duplicate-key error toast (the table's `UNIQUE (place_id, shift_type, weekday)` constraint).
- Clicking "Delete" on a row removes it.

Stop the dev server when done.

- [ ] **Step 15: Commit**

```bash
cd wansa-admin-dashboard
git add src/lib/supabase.ts src/context/translations/en.ts src/context/translations/ar.ts src/features/bookings/PlaceBookingTab.tsx
git commit -m "feat(bookings): rework ShiftPanel for weekday-recurring price overrides"
```
