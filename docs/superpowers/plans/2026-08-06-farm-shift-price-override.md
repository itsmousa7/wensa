# Farm Shift Per-Date Price Override Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a merchant set a custom price for a specific farm shift on a specific calendar date; customers see the overridden price (with the standard price struck through) and are charged exactly that amount.

**Architecture:** A new `bookings.farm_shift_price_overrides` table (place_id, shift_type, date, price_iqd) mirrors the existing `place_hours_overrides` per-date-exception pattern. `available_farm_shifts` resolves it for display (adds a nullable `standard_price_iqd` alongside the now-possibly-overridden `price_iqd`); `create_farm_booking` resolves the same table at charge time so the two never disagree. Mobile shows a strikethrough + badge when an override is active. The dashboard's existing `ShiftPanel` gains a small add/list/delete UI per shift card.

**Tech Stack:** Postgres/plpgsql (Supabase MCP, applied live), Flutter (Riverpod, freezed), React/TypeScript dashboard (`wansa-admin-dashboard`, no state library — local `useState` + a hand-rolled PostgREST client).

## Global Constraints

- Do not edit any previously-applied migration file (`20260806000001` through `20260806000003` in the mobile repo). All DB changes go in new migration files, applied live via Supabase MCP `apply_migration` (this repo's `supabase db push` is blocked by unrelated migration-history drift, per prior commits).
- Scope is farm shift bookings only — no other booking category.
- `farm_shift_price_overrides` RLS must mirror `farm_shifts`'s own policies exactly (`farm_shifts_read` / `farm_shifts_merchant_write` in `supabase/migrations/20260427000009_bookings_rls_views.sql:147-155`): public read, write restricted to `public.is_admin() OR bookings.is_merchant_staff_of(bookings._place_merchant(place_id))`.
- The client never computes or sends a price — `available_farm_shifts` and `create_farm_booking` are the sole source of truth for what a customer sees and pays.
- IQD formatting in Flutter reuses the existing comma-grouping regex pattern (`(\d{1,3})(?=(\d{3})+(?!\d))`) already used in `shift_card.dart` — don't reinvent it.
- Dashboard: table writes go through `getApi().get/insert/remove` (defined in `src/lib/supabase.ts`), routed to the `bookings` Postgres schema via the `TABLE_SCHEMA` map — no Supabase JS SDK, no service layer, matching every other table in `PlaceBookingTab.tsx`.
- Dashboard translation keys follow the existing `bkgShift*`/`bkgParty*` naming convention in `src/context/translations/en.ts` / `ar.ts`.

---

### Task 1: Database — `farm_shift_price_overrides` table + RLS

**Files:**
- Create: `supabase/migrations/20260806000004_farm_shift_price_overrides.sql`

**Interfaces:**
- Produces: table `bookings.farm_shift_price_overrides(id uuid, place_id uuid, shift_type bookings.farm_shift_type, date date, price_iqd integer, created_at timestamptz)`, unique on `(place_id, shift_type, date)` — read by Task 2 and Task 3's RPCs, written by Task 7's dashboard UI.

- [ ] **Step 1: Write the migration file**

```sql
-- ============================================================
-- Migration: Farm shift per-date price overrides
-- Date: 2026-08-06
-- ============================================================
--
-- Lets a merchant set a one-off price for a specific (place, shift_type,
-- date) — a holiday, a weekend, an event — without changing the shift's
-- everyday standing price in bookings.farm_shifts. Mirrors the existing
-- per-date-exception pattern already used for opening hours
-- (bookings.place_hours_overrides winning over bookings.place_hours).

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

- [ ] **Step 2: Apply the migration live via Supabase MCP**

Use the `mcp__plugin_supabase_supabase__apply_migration` tool with:
- `name`: `farm_shift_price_overrides`
- `query`: the full SQL from Step 1

- [ ] **Step 3: Verify the table, index, and both policies exist**

Run via `mcp__plugin_supabase_supabase__execute_sql`:

```sql
SELECT c.relname, c.relrowsecurity
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'bookings' AND c.relname = 'farm_shift_price_overrides';

SELECT polname FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
WHERE c.relname = 'farm_shift_price_overrides'
ORDER BY polname;
```

Expected: one row with `relrowsecurity = true`, and exactly two policy names: `farm_shift_price_overrides_merchant_write`, `farm_shift_price_overrides_read`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260806000004_farm_shift_price_overrides.sql
git commit -m "feat(db): add farm_shift_price_overrides table for per-date pricing"
```

---

### Task 2: Database — `available_farm_shifts` resolves the override

**Files:**
- Create: `supabase/migrations/20260806000005_available_farm_shifts_price_override.sql`

**Interfaces:**
- Consumes: `bookings.farm_shift_price_overrides` (Task 1).
- Produces: `bookings.available_farm_shifts(p_place_id, p_date)` / `public.available_farm_shifts(p_place_id, p_date)` now return an additional `standard_price_iqd integer` column (nullable — non-null only when an override is active for that date), and `price_iqd` becomes the overridden price when one exists. Consumed by Task 4 (Flutter model) via the `standard_price_iqd` JSON key.

- [ ] **Step 1: Write the migration file**

```sql
-- ============================================================
-- Migration: Resolve per-date price overrides in available_farm_shifts
-- Date: 2026-08-06
-- ============================================================
--
-- price_iqd becomes the effective (possibly overridden) price for the
-- requested date. standard_price_iqd is populated only when an override
-- is active, so the client can show "was X, now Y". RETURNS TABLE's
-- column list can't change via CREATE OR REPLACE, so both functions are
-- dropped and recreated (same two-step as 20260806000002); EXECUTE is
-- re-granted on the public wrapper at the end.

DROP FUNCTION IF EXISTS bookings.available_farm_shifts(uuid, date);

CREATE OR REPLACE FUNCTION bookings.available_farm_shifts(p_place_id uuid, p_date date)
RETURNS TABLE(
  place_id uuid,
  shift_type bookings.farm_shift_type,
  starts_time time without time zone,
  ends_time time without time zone,
  price_iqd integer,
  standard_price_iqd integer,
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
BEGIN
  v_now_baghdad   := (NOW() AT TIME ZONE 'Asia/Baghdad');
  v_today_baghdad := v_now_baghdad::date;

  SELECT * INTO v_hours
  FROM bookings._court_hours(p_place_id, NULL::uuid, p_date);

  IF FOUND AND v_hours.is_closed THEN
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        COALESCE(po.price_iqd, fs.price_iqd) AS price_iqd,
        CASE WHEN po.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
        false AS is_available,
        true  AS is_closed,
        fs.party_enabled,
        fs.party_included_persons,
        fs.party_flat_fee_iqd,
        fs.party_extra_person_fee_iqd
      FROM bookings.farm_shifts fs
      LEFT JOIN bookings.farm_shift_price_overrides po
        ON po.place_id = fs.place_id
       AND po.shift_type = fs.shift_type
       AND po.date = p_date
      WHERE fs.place_id = p_place_id
      ORDER BY fs.starts_time;
  ELSE
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        COALESCE(po.price_iqd, fs.price_iqd) AS price_iqd,
        CASE WHEN po.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
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
      LEFT JOIN bookings.farm_shift_price_overrides po
        ON po.place_id = fs.place_id
       AND po.shift_type = fs.shift_type
       AND po.date = p_date
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

Use `mcp__plugin_supabase_supabase__apply_migration` with `name: available_farm_shifts_price_override` and the SQL from Step 1.

- [ ] **Step 3: Verify with a real (but harmless) test override**

Find one existing `(place_id, shift_type)` pair to test against, using `mcp__plugin_supabase_supabase__execute_sql`:

```sql
SELECT place_id, shift_type, price_iqd FROM bookings.farm_shifts LIMIT 1;
```

Using that `place_id`/`shift_type` (call them `<PID>`/`<TYPE>`, and note the returned `price_iqd` as `<BASE>`), insert a temporary override for a date far in the future so it can never collide with a real booking, then query the RPC, then delete the override:

```sql
INSERT INTO bookings.farm_shift_price_overrides (place_id, shift_type, date, price_iqd)
VALUES ('<PID>', '<TYPE>', '2099-01-01', <BASE> + 12345);

SELECT place_id, shift_type, price_iqd, standard_price_iqd
FROM bookings.available_farm_shifts('<PID>', '2099-01-01')
WHERE shift_type = '<TYPE>';
-- Expected: price_iqd = <BASE> + 12345, standard_price_iqd = <BASE>

SELECT place_id, shift_type, price_iqd, standard_price_iqd
FROM bookings.available_farm_shifts('<PID>', '2099-01-02')
WHERE shift_type = '<TYPE>';
-- Expected (different date, no override): price_iqd = <BASE>, standard_price_iqd IS NULL

DELETE FROM bookings.farm_shift_price_overrides
WHERE place_id = '<PID>' AND shift_type = '<TYPE>' AND date = '2099-01-01';
```

Confirm the DELETE removed exactly 1 row (re-run the first SELECT and confirm `standard_price_iqd` is `NULL` again for `2099-01-01`) so no test data is left behind.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260806000005_available_farm_shifts_price_override.sql
git commit -m "feat(db): resolve per-date price overrides in available_farm_shifts"
```

---

### Task 3: Database — `create_farm_booking` charges the override price

**Files:**
- Create: `supabase/migrations/20260806000006_create_farm_booking_price_override.sql`

**Interfaces:**
- Consumes: `bookings.farm_shift_price_overrides` (Task 1).
- Produces: `bookings.create_farm_booking(...)` now charges the resolved (possibly overridden) price instead of the shift's standing `price_iqd`. Signature is unchanged (no new parameter), so `public.create_farm_booking` and the edge function need no changes.

- [ ] **Step 1: Write the migration file**

The function's argument list is unchanged, so this is a plain `CREATE OR REPLACE` — no `DROP FUNCTION IF EXISTS` needed (only required when `RETURNS TABLE`'s columns or the argument list change).

```sql
-- ============================================================
-- Migration: Charge per-date price overrides in create_farm_booking
-- Date: 2026-08-06
-- ============================================================
--
-- amount_iqd now uses the resolved (possibly overridden) price for the
-- booking's date, via the same farm_shift_price_overrides table
-- available_farm_shifts already reads for display — so the charged
-- amount always matches what the customer saw.

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

  -- Resolve the effective price for this date — an override wins if one
  -- exists for (place_id, shift_type, date), otherwise the standing price.
  SELECT po.price_iqd INTO v_price_iqd
  FROM bookings.farm_shift_price_overrides po
  WHERE po.place_id = p_place_id AND po.shift_type = p_shift_type AND po.date = p_date;

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

Use `mcp__plugin_supabase_supabase__apply_migration` with `name: create_farm_booking_price_override` and the SQL from Step 1.

- [ ] **Step 3: Verify the function definition contains the override resolution**

`auth.uid()` requires a real JWT session, so this function can't be invoked directly from `execute_sql` (it would fail with `Unauthorized` before reaching the price logic) — verify the deployed SQL text instead:

```sql
SELECT pg_get_functiondef(p.oid) LIKE '%farm_shift_price_overrides%' AS has_override_lookup,
       pg_get_functiondef(p.oid) LIKE '%v_price_iqd + v_party_fee%' AS charges_resolved_price
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'bookings' AND p.proname = 'create_farm_booking';
```

Expected: both columns `true`.

Additionally, sanity-check the resolution subquery in isolation (this part has no auth requirement) using the same test place/shift/date pattern as Task 2 Step 3 — insert a temporary override, run just the `SELECT po.price_iqd FROM bookings.farm_shift_price_overrides po WHERE ...` lookup the function uses, confirm it returns the override price, then delete the test row:

```sql
INSERT INTO bookings.farm_shift_price_overrides (place_id, shift_type, date, price_iqd)
VALUES ('<PID>', '<TYPE>', '2099-01-01', <BASE> + 12345);

SELECT po.price_iqd FROM bookings.farm_shift_price_overrides po
WHERE po.place_id = '<PID>' AND po.shift_type = '<TYPE>' AND po.date = '2099-01-01';
-- Expected: <BASE> + 12345

DELETE FROM bookings.farm_shift_price_overrides
WHERE place_id = '<PID>' AND shift_type = '<TYPE>' AND date = '2099-01-01';
```

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260806000006_create_farm_booking_price_override.sql
git commit -m "feat(db): charge per-date price overrides in create_farm_booking"
```

---

### Task 4: Mobile — `FarmShift.standardPriceIqd`

**Files:**
- Modify: `lib/features/booking/domain/models/farm_shift.dart`
- Modify: `test/features/booking/domain/models/farm_shift_test.dart`

**Interfaces:**
- Consumes: `standard_price_iqd` JSON key from `available_farm_shifts` (Task 2).
- Produces: `FarmShift.standardPriceIqd` (`int?`, `null` when no override is active) — consumed by Task 5 (`ShiftCard`).

- [ ] **Step 1: Write the failing test**

Add a new group to `test/features/booking/domain/models/farm_shift_test.dart`, after the existing `'FarmShift.fromJson party fields'` group (before the closing `}` of `main()`):

```dart
  group('FarmShift.fromJson price override', () {
    const baseJson = {
      'place_id': 'place-abc',
      'shift_type': 'day',
      'starts_time': '08:00:00',
      'ends_time': '18:00:00',
      'price_iqd': 250000,
    };

    test('parses standard_price_iqd when an override is active', () {
      final shift = FarmShift.fromJson({
        ...baseJson,
        'standard_price_iqd': 200000,
      });
      expect(shift.priceIqd, 250000);
      expect(shift.standardPriceIqd, 200000);
    });

    test('standardPriceIqd defaults to null when absent (no override)', () {
      final shift = FarmShift.fromJson(baseJson);
      expect(shift.standardPriceIqd, isNull);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/booking/domain/models/farm_shift_test.dart`
Expected: FAIL — `The getter 'standardPriceIqd' isn't defined for the type 'FarmShift'`

- [ ] **Step 3: Add the field to the model**

In `lib/features/booking/domain/models/farm_shift.dart`, change the factory constructor from:

```dart
  const factory FarmShift({
    @Default('') String placeId,
    @Default(FarmShiftType.day) FarmShiftType shiftType,
    @Default('') String startsTime,
    @Default('') String endsTime,
    @Default(0) int priceIqd,
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
    @Default(true) bool isAvailable,
    @Default(false) bool isClosed,
    @Default(false) bool partyEnabled,
    @Default(1) int partyIncludedPersons,
    @Default(0) int partyFlatFeeIqd,
    @Default(0) int partyExtraPersonFeeIqd,
  }) = _FarmShift;
```

and add the JSON parsing line to `fromJson` (after `priceIqd:`, before `isAvailable:`):

```dart
  factory FarmShift.fromJson(Map<String, dynamic> json) => FarmShift(
    placeId: json['place_id'] ?? '',
    shiftType: FarmShiftTypeFromString.fromString(json['shift_type'] ?? ''),
    startsTime: json['starts_time'] ?? '',
    endsTime: json['ends_time'] ?? '',
    priceIqd: (json['price_iqd'] as num?)?.toInt() ?? 0,
    standardPriceIqd: (json['standard_price_iqd'] as num?)?.toInt(),
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
Expected: completes without error, regenerating `farm_shift.freezed.dart` and `farm_shift.g.dart` with the new nullable `standardPriceIqd` field.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/booking/domain/models/farm_shift_test.dart`
Expected: PASS (all tests in the file, including the 2 new ones)

- [ ] **Step 6: Commit**

```bash
git add lib/features/booking/domain/models/farm_shift.dart lib/features/booking/domain/models/farm_shift.freezed.dart lib/features/booking/domain/models/farm_shift.g.dart test/features/booking/domain/models/farm_shift_test.dart
git commit -m "feat(booking): parse standard_price_iqd on FarmShift for date overrides"
```

---

### Task 5: Mobile — `ShiftCard` shows the override (strikethrough + badge)

**Files:**
- Modify: `lib/features/booking/presentation/widgets/shift_card.dart`
- Modify: `test/features/booking/presentation/widgets/shift_card_test.dart`

**Interfaces:**
- Consumes: `FarmShift.standardPriceIqd` (Task 4).

- [ ] **Step 1: Write the failing tests**

Add a new group to `test/features/booking/presentation/widgets/shift_card_test.dart`, after the existing `group('ShiftCard booked state', ...)` block (before the final closing `}` of `main()`):

```dart
  group('ShiftCard price override', () {
    const overriddenShift = FarmShift(
      placeId: 'p1',
      shiftType: FarmShiftType.day,
      startsTime: '08:00:00',
      endsTime: '18:00:00',
      priceIqd: 300000,
      standardPriceIqd: 200000,
      isAvailable: true,
    );

    Widget buildOverriddenCard() {
      return MaterialApp(
        home: Scaffold(
          body: ShiftCard(
            shift: overriddenShift,
            isSelected: false,
            availability: SlotAvailability.available,
            onTap: () {},
          ),
        ),
      );
    }

    testWidgets('shows the struck-through standard price and a badge',
        (tester) async {
      await tester.pumpWidget(buildOverriddenCard());
      expect(find.text('300,000'), findsOneWidget);
      expect(find.text('200,000'), findsOneWidget);
      expect(find.text('Special price'), findsOneWidget);
      final standardPriceText =
          tester.widget<Text>(find.text('200,000'));
      expect(
        standardPriceText.style?.decoration,
        TextDecoration.lineThrough,
      );
    });

    testWidgets('shows no strikethrough or badge when there is no override',
        (tester) async {
      const shift = FarmShift(
        placeId: 'p1',
        shiftType: FarmShiftType.day,
        startsTime: '08:00:00',
        endsTime: '18:00:00',
        priceIqd: 200000,
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
      expect(find.text('Special price'), findsNothing);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/booking/presentation/widgets/shift_card_test.dart`
Expected: FAIL — `find.text('200,000')` and `find.text('Special price')` find nothing (the widget doesn't render them yet).

- [ ] **Step 3: Add the strikethrough + badge to the widget**

In `lib/features/booking/presentation/widgets/shift_card.dart`, add a helper method next to `_formattedPrice()`:

```dart
  String _formattedStandardPrice() {
    final standard = shift.standardPriceIqd;
    if (standard == null) return '';
    return standard.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
```

Then change the `// ── Price ──` `Column` (the widget's final child, around lines 208-232) from:

```dart
              // ── Price ──────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (tt.titleMedium ?? const TextStyle()).copyWith(
                      color: priceColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    child: Text(_formattedPrice()),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (tt.labelSmall ?? const TextStyle()).copyWith(
                      color: currencyColor,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                    child: const Text('IQD'),
                  ),
                ],
              ),
```

to:

```dart
              // ── Price ──────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (shift.standardPriceIqd != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAr ? 'سعر خاص' : 'Special price',
                        style: (tt.labelSmall ?? const TextStyle()).copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      _formattedStandardPrice(),
                      style: (tt.bodySmall ?? const TextStyle()).copyWith(
                        color: subtextColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (tt.titleMedium ?? const TextStyle()).copyWith(
                      color: priceColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    child: Text(_formattedPrice()),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (tt.labelSmall ?? const TextStyle()).copyWith(
                      color: currencyColor,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                    child: const Text('IQD'),
                  ),
                ],
              ),
```

`isAr` and `cs`/`tt`/`subtextColor` are already in scope in `build()` — no new imports needed.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/booking/presentation/widgets/shift_card_test.dart`
Expected: PASS (all tests, including the 2 new ones)

- [ ] **Step 5: Run the full booking test directory to check for regressions**

Run: `flutter test test/features/booking/`
Expected: PASS, all tests (this touches a widget used by `farm_section.dart`, so confirm nothing there broke even though that file itself isn't modified by this task).

- [ ] **Step 6: Commit**

```bash
git add lib/features/booking/presentation/widgets/shift_card.dart test/features/booking/presentation/widgets/shift_card_test.dart
git commit -m "feat(booking): show struck-through standard price on ShiftCard when overridden"
```

---

### Task 6: Dashboard — data-layer routing + translation keys

**Files:**
- Modify: `wansa-admin-dashboard/src/lib/supabase.ts`
- Modify: `wansa-admin-dashboard/src/context/translations/en.ts`
- Modify: `wansa-admin-dashboard/src/context/translations/ar.ts`

**Interfaces:**
- Produces: `getApi()` calls against table `"farm_shift_price_overrides"` now route to the `bookings` Postgres schema. Translation keys `bkgPriceOverrides`, `bkgAddOverride`, `bkgOverrideDate`, `bkgOverridePrice`, `bkgOverrideDelete` — consumed by Task 7.

- [ ] **Step 1: Add the schema routing entry**

In `wansa-admin-dashboard/src/lib/supabase.ts`, in the `TABLE_SCHEMA` map's `// bookings` section, change:

```ts
    event_tiers: "bookings", place_hours: "bookings", place_hours_overrides: "bookings",
    seat_map_requests: "bookings", user_payment_tokens: "bookings",
```

to:

```ts
    event_tiers: "bookings", place_hours: "bookings", place_hours_overrides: "bookings",
    seat_map_requests: "bookings", user_payment_tokens: "bookings",
    farm_shift_price_overrides: "bookings",
```

- [ ] **Step 2: Add English translation keys**

In `wansa-admin-dashboard/src/context/translations/en.ts`, change:

```ts
        bkgPartyExtraFee: "Fee per Extra Guest",
        bkgComingSoon: "Booking config coming soon for this category",
```

to:

```ts
        bkgPartyExtraFee: "Fee per Extra Guest",
        bkgPriceOverrides: "Price Overrides",
        bkgAddOverride: "Add Override",
        bkgOverrideDate: "Date",
        bkgOverridePrice: "Price (IQD)",
        bkgOverrideDelete: "Delete",
        bkgComingSoon: "Booking config coming soon for this category",
```

- [ ] **Step 3: Add Arabic translation keys**

In `wansa-admin-dashboard/src/context/translations/ar.ts`, change:

```ts
        bkgPartyExtraFee: "رسوم كل ضيف إضافي",
        bkgComingSoon: "إعدادات الحجز لهذه الفئة قريباً",
```

to:

```ts
        bkgPartyExtraFee: "رسوم كل ضيف إضافي",
        bkgPriceOverrides: "أسعار مخصصة لتواريخ محددة",
        bkgAddOverride: "إضافة سعر مخصص",
        bkgOverrideDate: "التاريخ",
        bkgOverridePrice: "السعر (د.ع)",
        bkgOverrideDelete: "حذف",
        bkgComingSoon: "إعدادات الحجز لهذه الفئة قريباً",
```

- [ ] **Step 4: Type-check the dashboard**

Run: `cd wansa-admin-dashboard && npx tsc --noEmit`
Expected: no new errors introduced by these three files (pre-existing errors elsewhere, if any, are out of scope for this task — only confirm nothing new appears in `supabase.ts` or the translation files).

- [ ] **Step 5: Commit**

```bash
cd wansa-admin-dashboard
git add src/lib/supabase.ts src/context/translations/en.ts src/context/translations/ar.ts
git commit -m "feat(bookings): route farm_shift_price_overrides + add translation keys"
```

---

### Task 7: Dashboard — `ShiftPanel` price-override UI

**Files:**
- Modify: `wansa-admin-dashboard/src/features/bookings/PlaceBookingTab.tsx`

**Interfaces:**
- Consumes: `getApi().get/insert/remove('farm_shift_price_overrides', ...)` (Task 6's schema routing), translation keys (Task 6).

- [ ] **Step 1: Add the override row type and per-shift state**

In `PlaceBookingTab.tsx`, immediately after the existing `interface ShiftRowState { ... }` block (around line 343), add:

```ts
interface PriceOverride { id: string; place_id: string; shift_type: "day" | "night" | "full"; date: string; price_iqd: number; }
```

Inside `ShiftPanel`, after the existing `const [toastErr, setToastErr] = useState(false);` line, add state for the overrides list and the add-modal:

```ts
    const [overrides, setOverrides] = useState<PriceOverride[]>([]);
    const [overrideModalType, setOverrideModalType] = useState<"day" | "night" | "full" | null>(null);
    const [overrideDate, setOverrideDate] = useState("");
    const [overridePrice, setOverridePrice] = useState("");
    const [overrideSaving, setOverrideSaving] = useState(false);
```

- [ ] **Step 2: Fetch overrides alongside shifts**

Change `fetchData` from:

```ts
    const fetchData = async () => {
        setLoading(true); setError(null);
        try {
            const shiftRows = await getApi().get("farm_shifts", `&place_id=eq.${placeId}`);
            setShifts(shiftRows);
```

to:

```ts
    const fetchData = async () => {
        setLoading(true); setError(null);
        try {
            const shiftRows = await getApi().get("farm_shifts", `&place_id=eq.${placeId}`);
            setShifts(shiftRows);
            const overrideRows = await getApi().get<PriceOverride>(
                "farm_shift_price_overrides",
                `&place_id=eq.${placeId}&order=date.asc`,
            );
            setOverrides(overrideRows);
```

(the rest of `fetchData` — the per-shift-type state population loop and its `catch`/`setLoading(false)` — is unchanged)

- [ ] **Step 3: Add the save/delete handlers**

After the existing `saveAll` function (ends around line 436), add:

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

    const deleteOverride = async (id: string) => {
        try {
            await getApi().remove("farm_shift_price_overrides", id);
            await fetchData();
        } catch (e: any) {
            setToast("Error: " + e.message); setToastErr(true);
        }
    };
```

- [ ] **Step 4: Render the per-shift override list + "Add Override" button**

Inside the `shiftRows.map(({ type, label }) => { ... })` block, immediately after the existing party-pricing `{state.enabled && ( <div style={{ padding: "0 16px 14px", ... }}> ... </div> )}` block (which currently ends the card's JSX before its closing `</div>` at line 548), add a new sibling block still inside `{state.enabled && ( ... )}`'s parent scope — i.e. insert this right before the shift card's final closing `</div>` (the one that closes the `key={type}` wrapper div):

```tsx
                            {state.enabled && (
                                <div style={{ padding: "0 16px 14px", borderTop: `1px solid ${C.border}` }}>
                                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 0 10px" }}>
                                        <span style={{ fontSize: FS.base, fontWeight: 700, color: C.text }}>
                                            {l.bkgPriceOverrides}
                                        </span>
                                        <Btn variant="secondary" size="sm" onClick={() => { setOverrideModalType(type); setOverrideDate(""); setOverridePrice(""); }}>
                                            + {l.bkgAddOverride}
                                        </Btn>
                                    </div>
                                    {overrides.filter(o => o.shift_type === type).length === 0 ? (
                                        <div style={{ fontSize: FS.sm, color: C.text4, paddingBottom: 8 }}>—</div>
                                    ) : (
                                        <div style={{ display: "flex", flexDirection: "column", gap: 6, paddingBottom: 8 }}>
                                            {overrides.filter(o => o.shift_type === type).map(o => (
                                                <div key={o.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: FS.sm, padding: "6px 10px", background: C.bg, borderRadius: R.sm }}>
                                                    <span style={{ color: C.text }}>{o.date}</span>
                                                    <span style={{ color: color, fontWeight: 700 }}>{Number(o.price_iqd).toLocaleString('en-US')} IQD</span>
                                                    <button onClick={() => deleteOverride(o.id)} style={{ background: "none", border: "none", cursor: "pointer", color: C.red, fontSize: FS.sm }}>
                                                        {l.bkgOverrideDelete}
                                                    </button>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>
                            )}
```

- [ ] **Step 5: Add the "add override" modal**

Immediately before the closing `{toast && <Toast ... />}` line at the end of `ShiftPanel`'s returned JSX (around line 557), add:

```tsx
            {overrideModalType && (
                <Modal title={l.bkgAddOverride} onClose={() => setOverrideModalType(null)}>
                    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
                        <div>
                            <FieldLabel>{l.bkgOverrideDate}</FieldLabel>
                            <input type="date" min={new Date().toISOString().slice(0, 10)}
                                value={overrideDate}
                                onChange={e => setOverrideDate(e.target.value)}
                                style={{ padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                            />
                        </div>
                        <div>
                            <FieldLabel>{l.bkgOverridePrice}</FieldLabel>
                            <input type="text" inputMode="numeric"
                                value={overridePrice ? Number(overridePrice).toLocaleString('en-US') : ""}
                                placeholder="0"
                                onChange={e => setOverridePrice(e.target.value.replace(/,/g, '').replace(/[^0-9]/g, ''))}
                                style={{ width: 160, padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                            />
                        </div>
                        <div style={{ display: "flex", justifyContent: "flex-end", gap: 10, marginTop: 6 }}>
                            <Btn variant="secondary" onClick={() => setOverrideModalType(null)}>Cancel</Btn>
                            <Btn variant="accent" onClick={addOverride} loading={overrideSaving} disabled={!overrideDate || !overridePrice}>
                                {l.bkgAddOverride}
                            </Btn>
                        </div>
                    </div>
                </Modal>
            )}
```

- [ ] **Step 6: Type-check and lint**

Run: `cd wansa-admin-dashboard && npx tsc --noEmit`
Expected: no new type errors from `PlaceBookingTab.tsx`.

Run whatever lint command this repo defines (check `package.json`'s `scripts.lint`; if none exists, skip this step — don't invent a lint config).

- [ ] **Step 7: Manual smoke check**

Run: `cd wansa-admin-dashboard && npm run dev` (or the repo's equivalent dev-server script — check `package.json`), open the dashboard in a browser, navigate to a farm place's booking tab, expand a shift card, and confirm:
- The "Price Overrides" section renders with a "—" placeholder and an "+ Add Override" button.
- Clicking "+ Add Override" opens the modal with a date input (blocking past dates) and a price input.
- Submitting adds a row to the list showing the date and formatted price.
- Clicking "Delete" on that row removes it.

Stop the dev server when done.

- [ ] **Step 8: Commit**

```bash
cd wansa-admin-dashboard
git add src/features/bookings/PlaceBookingTab.tsx
git commit -m "feat(bookings): add per-date price override UI to ShiftPanel"
```
