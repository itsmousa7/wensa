# Shift Party Pricing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let merchants (and admins, via the same shared dashboard) configure an optional per-shift party surcharge — a flat fee plus a per-extra-guest fee beyond an included headcount — and let customers opt into it in the mobile shift-booking flow, with the server computing and enforcing the final charge.

**Architecture:** Four new columns on `bookings.farm_shifts` carry the per-shift party config. `bookings.create_farm_booking` (and its `public` wrapper) gain an optional `p_party_size` param and compute the surcharge server-side into `amount_iqd` + `category_data`. The dashboard's existing `ShiftPanel` (shared by merchant and admin) gains a party-pricing sub-section per shift. The mobile `FarmSection` gains a new `PartyOptionCard` between the shift picker and the booking summary, wired through a new optional `partySize` param on `createFarmBooking`.

**Tech Stack:** Supabase/PostgreSQL (migrations, PL/pgSQL RPCs), Deno (Supabase Edge Functions), React 19 + TypeScript (dashboard, no test framework — `tsc -b` is the verification gate), Flutter + Dart, Riverpod (`riverpod_annotation`), Freezed, `build_runner`.

## Global Constraints

- No hard cap on party size — the per-guest overage scales freely with no maximum, per the approved design.
- Party pricing is configured **per shift** (day/night/full each have independent settings), not per place.
- The client sends only a guest count (`party_size`); the server (`bookings.create_farm_booking`) is the sole authority on price — never trust or read a client-supplied amount.
- `party_size`, when provided, must be `>= 1` and the target shift must have `party_enabled = true`, enforced by the RPC with `RAISE EXCEPTION`.
- Dashboard UI: never use emojis for UI elements — inline SVG icons only, per the existing `wansa-ui-conventions` rule already applied to `ShiftCards`' `SunIcon`/`MoonIcon`/`ClockIcon`.
- Existing shifts (`party_enabled` defaults to `false`) must behave exactly as before — this is an additive, non-breaking change.
- The `create-booking` Supabase Edge Function source is kept byte-identical between `wensa/supabase/functions/create-booking/index.ts` and `wansa-admin-dashboard/supabase/functions/create-booking/index.ts` — both must be edited together.

---

## File Map

| File | Action |
|------|--------|
| `wensa/supabase/migrations/20260806000001_farm_shift_party_pricing.sql` | Create |
| `wensa/supabase/functions/create-booking/index.ts` | Modify |
| `wansa-admin-dashboard/supabase/functions/create-booking/index.ts` | Modify (kept byte-identical) |
| `wansa-admin-dashboard/src/features/bookings/PlaceBookingTab.tsx` | Modify |
| `wansa-admin-dashboard/src/context/translations/en.ts` | Modify |
| `wansa-admin-dashboard/src/context/translations/ar.ts` | Modify |
| `wansa-admin-dashboard/src/features/merchant/MyBookingsPage.tsx` | Modify |
| `wensa/lib/features/booking/domain/models/farm_shift.dart` | Modify |
| `wensa/lib/features/booking/domain/models/farm_shift.freezed.dart` | Regenerate via `build_runner` |
| `wensa/lib/features/booking/domain/models/farm_shift.g.dart` | Regenerate via `build_runner` |
| `wensa/test/features/booking/domain/models/farm_shift_test.dart` | Modify — add party field test cases |
| `wensa/lib/features/booking/presentation/providers/booking_submit_provider.dart` | Modify |
| `wensa/lib/features/booking/presentation/widgets/party_option_card.dart` | Create |
| `wensa/test/features/booking/presentation/widgets/party_option_card_test.dart` | Create |
| `wensa/lib/features/booking/presentation/sections/farm_section.dart` | Modify |
| `wensa/lib/features/bookings_history/presentation/pages/ticket_detail_page.dart` | Modify |

All `wensa/...` paths are relative to `/Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa`. All `wansa-admin-dashboard/...` paths are relative to `/Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard`. These are two separate git repositories — commit each task's changes in the repo it touches.

---

### Task 1: Database — party pricing columns + RPC updates

**Files:**
- Create: `supabase/migrations/20260806000001_farm_shift_party_pricing.sql` (in `wensa`)

**Interfaces:**
- Produces: `bookings.farm_shifts` gains `party_enabled boolean`, `party_included_persons integer`, `party_flat_fee_iqd integer`, `party_extra_person_fee_iqd integer`. `bookings.create_farm_booking(p_place_id uuid, p_date date, p_shift_type bookings.farm_shift_type, p_party_size integer DEFAULT NULL)` and `public.create_farm_booking(...)` (same signature) are the new RPC contracts every later task (edge function, mobile) calls against.

- [ ] **Step 1: Create the migration file**

```sql
-- ============================================================
-- Migration: Farm shift party pricing
-- Date: 2026-08-06
-- ============================================================
--
-- Lets merchants configure, per shift, an optional party surcharge:
--   - party_enabled: on/off
--   - party_included_persons: guests covered by the base shift price
--   - party_flat_fee_iqd: flat charge added when the customer opts into a party
--   - party_extra_person_fee_iqd: per-guest charge beyond party_included_persons
--
-- bookings.create_farm_booking gains p_party_size (nullable) and computes
-- the party surcharge server-side — the client never sends a price.

ALTER TABLE bookings.farm_shifts
  ADD COLUMN party_enabled              boolean NOT NULL DEFAULT false,
  ADD COLUMN party_included_persons     integer NOT NULL DEFAULT 1  CHECK (party_included_persons > 0),
  ADD COLUMN party_flat_fee_iqd         integer NOT NULL DEFAULT 0  CHECK (party_flat_fee_iqd >= 0),
  ADD COLUMN party_extra_person_fee_iqd integer NOT NULL DEFAULT 0  CHECK (party_extra_person_fee_iqd >= 0);

-- ── bookings.create_farm_booking — add p_party_size ─────────────────────────
-- The argument list changes (adds a 4th param). CREATE OR REPLACE cannot
-- "replace" a function when the argument types differ — Postgres would keep
-- the old 3-arg function AND add this as a new overload, making 3-arg calls
-- ambiguous. Drop the old signature first so there's exactly one version.
DROP FUNCTION IF EXISTS bookings.create_farm_booking(uuid, date, bookings.farm_shift_type);

CREATE OR REPLACE FUNCTION bookings.create_farm_booking(
  p_place_id   uuid,
  p_date       date,
  p_shift_type bookings.farm_shift_type,
  p_party_size integer DEFAULT NULL
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

  IF p_party_size IS NOT NULL THEN
    IF NOT v_shift.party_enabled THEN
      RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
    END IF;
    IF p_party_size < 1 THEN
      RAISE EXCEPTION 'party_size must be at least 1' USING ERRCODE = 'P0004';
    END IF;
    v_party_fee := v_shift.party_flat_fee_iqd
      + GREATEST(0, p_party_size - v_shift.party_included_persons) * v_shift.party_extra_person_fee_iqd;
  END IF;

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
  IF v_party_fee > 0 THEN
    v_category_data := v_category_data || jsonb_build_object('party_fee_iqd', v_party_fee);
  END IF;

  INSERT INTO bookings.bookings (
    user_id, merchant_id, place_id, category, status,
    starts_at, ends_at, amount_iqd, hold_until, category_data
  ) VALUES (
    v_user_id, v_merchant_id, p_place_id, 'farm', 'pending',
    v_starts_at, v_ends_at, v_shift.price_iqd + v_party_fee, v_hold_until,
    v_category_data
  )
  RETURNING id, qr_token INTO v_booking_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_booking_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_shift.price_iqd + v_party_fee,
    'hold_until', v_hold_until
  );
END;
$$;

-- ── public.create_farm_booking wrapper — add p_party_size ──────────────────
DROP FUNCTION IF EXISTS public.create_farm_booking(uuid, date, bookings.farm_shift_type);

CREATE OR REPLACE FUNCTION public.create_farm_booking(
  p_place_id   uuid,
  p_date       date,
  p_shift_type bookings.farm_shift_type,
  p_party_size integer DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.create_farm_booking(p_place_id, p_date, p_shift_type, p_party_size);
$$;
```

- [ ] **Step 2: Apply the migration**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
supabase db push
```

Expected: migration applies without error (project is already linked — `supabase/.temp/project-ref` contains `qvozjwlkzordudkhamcu`).

- [ ] **Step 3: Smoke-test in the Supabase SQL editor**

Substitute a real farm `place_id` that has a `day` shift configured (from `content.places` / `bookings.farm_shifts`):

```sql
-- 1. Enable party pricing on the day shift for this place
UPDATE bookings.farm_shifts
SET party_enabled = true, party_included_persons = 10,
    party_flat_fee_iqd = 20000, party_extra_person_fee_iqd = 5000
WHERE place_id = '<real-place-id>' AND shift_type = 'day';

-- 2. Call the RPC without a party_size — base price only
SELECT bookings.create_farm_booking('<real-place-id>', CURRENT_DATE + 3, 'day', NULL);
-- Expected: amount_iqd equals the shift's plain price_iqd (no surcharge).

-- 3. Call the RPC with party_size = 10 (== included persons) — flat fee only
SELECT bookings.create_farm_booking('<real-place-id>', CURRENT_DATE + 4, 'day', 10);
-- Expected: amount_iqd = price_iqd + 20000.

-- 4. Call the RPC with party_size = 13 (3 over) — flat fee + overage
SELECT bookings.create_farm_booking('<real-place-id>', CURRENT_DATE + 5, 'day', 13);
-- Expected: amount_iqd = price_iqd + 20000 + 3*5000 = price_iqd + 35000.
-- Expected: the row's category_data (SELECT category_data FROM bookings.bookings
-- WHERE id = <returned id>) contains {"shift_type":"day","party_size":13,"party_fee_iqd":35000}.

-- 5. Call the RPC with a party_size on a shift where party_enabled = false
--    (e.g. the 'night' shift, untouched by step 1)
SELECT bookings.create_farm_booking('<real-place-id>', CURRENT_DATE + 6, 'night', 5);
-- Expected: ERROR "Party pricing not enabled for this shift" (SQLSTATE P0003).

-- 6. Cleanup — cancel the pending test bookings created above so they don't
--    block the GIST exclusion or linger as test data.
UPDATE bookings.bookings SET status = 'cancelled'
WHERE place_id = '<real-place-id>' AND status = 'pending'
  AND starts_at::date IN (CURRENT_DATE + 3, CURRENT_DATE + 4, CURRENT_DATE + 5);
```

- [ ] **Step 4: Commit**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
git add supabase/migrations/20260806000001_farm_shift_party_pricing.sql
git commit -m "feat(db): add per-shift party pricing columns and RPC support"
```

---

### Task 2: Edge function — pass `party_size` through to the RPC

**Files:**
- Modify: `supabase/functions/create-booking/index.ts` (in `wensa`)
- Modify: `supabase/functions/create-booking/index.ts` (in `wansa-admin-dashboard`) — identical edit, kept in sync

**Interfaces:**
- Consumes: `bookings.create_farm_booking(p_place_id, p_date, p_shift_type, p_party_size)` from Task 1.
- Produces: `ShiftPayload.party_size?: number` — the mobile `createFarmBooking` (Task 9) sends this field.

- [ ] **Step 1: Add `party_size` to `ShiftPayload` and the RPC call**

In `wensa/supabase/functions/create-booking/index.ts`, find:

```ts
interface ShiftPayload extends BasePaylod {
  category: "shift";
  place_id: string;
  date: string;
  shift_type: "day" | "night" | "full";
}
```

Replace with:

```ts
interface ShiftPayload extends BasePaylod {
  category: "shift";
  place_id: string;
  date: string;
  shift_type: "day" | "night" | "full";
  party_size?: number;
}
```

Then find:

```ts
    } else if (body.category === "shift") {
      const p = body as ShiftPayload;
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_farm_booking", {
        p_place_id:   p.place_id,
        p_date:       p.date,
        p_shift_type: p.shift_type,
      });
```

Replace with:

```ts
    } else if (body.category === "shift") {
      const p = body as ShiftPayload;
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_farm_booking", {
        p_place_id:   p.place_id,
        p_date:       p.date,
        p_shift_type: p.shift_type,
        p_party_size: p.party_size ?? null,
      });
```

- [ ] **Step 2: Apply the identical edit to the dashboard's copy**

Apply the exact same two replacements to `wansa-admin-dashboard/supabase/functions/create-booking/index.ts`.

- [ ] **Step 3: Verify both files stay byte-identical and type-check**

```bash
diff /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/supabase/functions/create-booking/index.ts \
     /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard/supabase/functions/create-booking/index.ts
```

Expected: no output (identical).

```bash
deno check /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/supabase/functions/create-booking/index.ts
```

Expected: no type errors.

- [ ] **Step 4: Deploy**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
supabase functions deploy create-booking
```

Expected: deploy succeeds against the linked project (`qvozjwlkzordudkhamcu`).

- [ ] **Step 5: Commit (both repos)**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
git add supabase/functions/create-booking/index.ts
git commit -m "feat(edge): pass party_size through to create_farm_booking"

cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
git add supabase/functions/create-booking/index.ts
git commit -m "feat(edge): pass party_size through to create_farm_booking"
```

---

### Task 3: Dashboard — extend `ShiftPanel` state to carry party fields

**Files:**
- Modify: `src/features/bookings/PlaceBookingTab.tsx` (in `wansa-admin-dashboard`)

**Interfaces:**
- Consumes: `bookings.farm_shifts` columns from Task 1 (`party_enabled`, `party_included_persons`, `party_flat_fee_iqd`, `party_extra_person_fee_iqd`) via the existing `getApi().get("farm_shifts", ...)` REST call.
- Produces: `ShiftRowState` gains `party_enabled: boolean`, `party_included_persons: string`, `party_flat_fee_iqd: string`, `party_extra_person_fee_iqd: string` — Task 5's UI reads/writes these via the existing `getShiftState`/`setShiftState` helpers.

- [ ] **Step 1: Extend the `FarmShift` and `ShiftRowState` interfaces**

Find (around line 321):

```ts
interface FarmShift {
    id: string; place_id: string; shift_type: "day" | "night" | "full";
    starts_time: string; ends_time: string; price_iqd: number;
}
interface FarmSettings { id: string; place_id: string; multi_day_allowed: boolean; }
interface ShiftRowState { starts_time: string; ends_time: string; price_iqd: string; saving: boolean; enabled: boolean; }
```

Replace with:

```ts
interface FarmShift {
    id: string; place_id: string; shift_type: "day" | "night" | "full";
    starts_time: string; ends_time: string; price_iqd: number;
    party_enabled: boolean; party_included_persons: number;
    party_flat_fee_iqd: number; party_extra_person_fee_iqd: number;
}
interface FarmSettings { id: string; place_id: string; multi_day_allowed: boolean; }
interface ShiftRowState {
    starts_time: string; ends_time: string; price_iqd: string; saving: boolean; enabled: boolean;
    party_enabled: boolean; party_included_persons: string;
    party_flat_fee_iqd: string; party_extra_person_fee_iqd: string;
}
```

- [ ] **Step 2: Add party defaults to the three `useState` initializers**

Find:

```ts
    const [dayState, setDayState] = useState<ShiftRowState>({ starts_time: "08:00", ends_time: "18:00", price_iqd: "", saving: false, enabled: false });
    const [nightState, setNightState] = useState<ShiftRowState>({ starts_time: "18:00", ends_time: "02:00", price_iqd: "", saving: false, enabled: false });
    const [fullState, setFullState] = useState<ShiftRowState>({ starts_time: "08:00", ends_time: "02:00", price_iqd: "", saving: false, enabled: false });
```

Replace with:

```ts
    const PARTY_DEFAULTS = { party_enabled: false, party_included_persons: "1", party_flat_fee_iqd: "", party_extra_person_fee_iqd: "" };
    const [dayState, setDayState] = useState<ShiftRowState>({ starts_time: "08:00", ends_time: "18:00", price_iqd: "", saving: false, enabled: false, ...PARTY_DEFAULTS });
    const [nightState, setNightState] = useState<ShiftRowState>({ starts_time: "18:00", ends_time: "02:00", price_iqd: "", saving: false, enabled: false, ...PARTY_DEFAULTS });
    const [fullState, setFullState] = useState<ShiftRowState>({ starts_time: "08:00", ends_time: "02:00", price_iqd: "", saving: false, enabled: false, ...PARTY_DEFAULTS });
```

- [ ] **Step 3: Populate party fields in `fetchData`**

Find:

```ts
            for (const type of ["day", "night", "full"] as const) {
                const row = (shiftRows as FarmShift[]).find(r => r.shift_type === type);
                const def = SHIFT_DEFAULTS[type];
                const state: ShiftRowState = {
                    starts_time: row?.starts_time ?? def.starts_time,
                    ends_time: row?.ends_time ?? def.ends_time,
                    price_iqd: row ? String(row.price_iqd) : "",
                    saving: false,
                    enabled: !!row,
                };
                if (type === "day") setDayState(state);
                else if (type === "night") setNightState(state);
                else setFullState(state);
            }
```

Replace with:

```ts
            for (const type of ["day", "night", "full"] as const) {
                const row = (shiftRows as FarmShift[]).find(r => r.shift_type === type);
                const def = SHIFT_DEFAULTS[type];
                const state: ShiftRowState = {
                    starts_time: row?.starts_time ?? def.starts_time,
                    ends_time: row?.ends_time ?? def.ends_time,
                    price_iqd: row ? String(row.price_iqd) : "",
                    saving: false,
                    enabled: !!row,
                    party_enabled: row?.party_enabled ?? false,
                    party_included_persons: row ? String(row.party_included_persons) : "1",
                    party_flat_fee_iqd: row?.party_flat_fee_iqd ? String(row.party_flat_fee_iqd) : "",
                    party_extra_person_fee_iqd: row?.party_extra_person_fee_iqd ? String(row.party_extra_person_fee_iqd) : "",
                };
                if (type === "day") setDayState(state);
                else if (type === "night") setNightState(state);
                else setFullState(state);
            }
```

- [ ] **Step 4: Include party fields in the `saveShift` payload**

Find:

```ts
            const existing = shifts.find(r => r.shift_type === type);
            const payload = { place_id: placeId, shift_type: type, starts_time: state.starts_time, ends_time: state.ends_time, price_iqd: parseFloat(state.price_iqd) || 0 };
            if (existing) { await getApi().update("farm_shifts", existing.id, payload); }
```

Replace with:

```ts
            const existing = shifts.find(r => r.shift_type === type);
            const payload = {
                place_id: placeId, shift_type: type, starts_time: state.starts_time, ends_time: state.ends_time, price_iqd: parseFloat(state.price_iqd) || 0,
                party_enabled: state.party_enabled,
                party_included_persons: parseInt(state.party_included_persons) || 1,
                party_flat_fee_iqd: parseFloat(state.party_flat_fee_iqd) || 0,
                party_extra_person_fee_iqd: parseFloat(state.party_extra_person_fee_iqd) || 0,
            };
            if (existing) { await getApi().update("farm_shifts", existing.id, payload); }
```

- [ ] **Step 5: Type-check**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
npx tsc -b --noEmit
```

Expected: no errors (Task 5 adds the UI that reads these fields — until then, `party_enabled` etc. are set but unused in JSX, which `tsc` does not flag).

- [ ] **Step 6: Commit**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
git add src/features/bookings/PlaceBookingTab.tsx
git commit -m "feat(dashboard): carry party pricing fields in ShiftPanel state"
```

---

### Task 4: Dashboard — translation keys

**Files:**
- Modify: `src/context/translations/en.ts` (in `wansa-admin-dashboard`)
- Modify: `src/context/translations/ar.ts` (in `wansa-admin-dashboard`)

**Interfaces:**
- Produces: `l.bkgPartyPricing`, `l.bkgPartyIncluded`, `l.bkgPartyFlatFee`, `l.bkgPartyExtraFee` — consumed by Task 5's JSX and Task 6's detail modal.

- [ ] **Step 1: Add English keys**

In `en.ts`, find:

```ts
        bkgSaveShift: "Save",
        bkgComingSoon: "Booking config coming soon for this category",
```

Replace with:

```ts
        bkgSaveShift: "Save",
        bkgPartyPricing: "Party Pricing",
        bkgPartyIncluded: "Included Guests",
        bkgPartyFlatFee: "Party Fee",
        bkgPartyExtraFee: "Fee per Extra Guest",
        bkgComingSoon: "Booking config coming soon for this category",
```

- [ ] **Step 2: Add Arabic keys**

In `ar.ts`, find:

```ts
        bkgSaveShift: "حفظ",
        bkgComingSoon: "إعدادات الحجز لهذه الفئة قريباً",
```

Replace with:

```ts
        bkgSaveShift: "حفظ",
        bkgPartyPricing: "أسعار الحفلات",
        bkgPartyIncluded: "عدد الضيوف المشمولين",
        bkgPartyFlatFee: "رسوم الحفلة",
        bkgPartyExtraFee: "رسوم كل ضيف إضافي",
        bkgComingSoon: "إعدادات الحجز لهذه الفئة قريباً",
```

- [ ] **Step 3: Type-check**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
npx tsc -b --noEmit
```

Expected: no errors — `ar.ts`'s `const ar: Translations = {...}` requires every key `en.ts` defines (`Translations = typeof en`), so a mismatch between the two files would fail here.

- [ ] **Step 4: Commit**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
git add src/context/translations/en.ts src/context/translations/ar.ts
git commit -m "feat(dashboard): add party pricing translation keys"
```

---

### Task 5: Dashboard — Party Pricing UI in `ShiftPanel`

**Files:**
- Modify: `src/features/bookings/PlaceBookingTab.tsx` (in `wansa-admin-dashboard`)

**Interfaces:**
- Consumes: `ShiftRowState.party_*` fields and `getShiftState`/`setShiftState` from Task 3, and `l.bkgPartyPricing`/`l.bkgPartyIncluded`/`l.bkgPartyFlatFee`/`l.bkgPartyExtraFee` from Task 4.

- [ ] **Step 1: Add a `PeopleIcon` component**

Find the `StatusBadge` function (around line 82-95) and add this new function immediately after it, before the `// ── Injected styles ──` comment:

```tsx
/** Feather-style "users" icon for party pricing — no emojis per dashboard convention */
function PeopleIcon({ size = 16, color = "currentColor" }: { size?: number; color?: string }) {
    return (
        <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
            <path d="M16 3.13a4 4 0 0 1 0 7.75" />
        </svg>
    );
}
```

- [ ] **Step 2: Add the Party Pricing sub-section to each shift card**

Find the shift card body block:

```tsx
                            {/* Card body — only shown when enabled */}
                            {state.enabled && (
                                <div style={{ padding: "14px 16px", display: "flex", flexWrap: "wrap", gap: 14, alignItems: "flex-end" }}>
                                    <div>
                                        <FieldLabel>{l.bkgShiftStart}</FieldLabel>
                                        <input type="time" value={state.starts_time}
                                            onChange={e => setShiftState(type, s => ({ ...s, starts_time: e.target.value }))}
                                            style={{ padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                        />
                                    </div>
                                    <div>
                                        <FieldLabel>{l.bkgShiftEnd}</FieldLabel>
                                        <input type="time" value={state.ends_time}
                                            onChange={e => setShiftState(type, s => ({ ...s, ends_time: e.target.value }))}
                                            style={{ padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                        />
                                    </div>
                                    <div>
                                        <FieldLabel>{l.bkgShiftPrice} (IQD)</FieldLabel>
                                        <input type="text" inputMode="numeric"
                                            value={state.price_iqd ? Number(state.price_iqd).toLocaleString('en-US') : ""}
                                            placeholder="0"
                                            onChange={e => setShiftState(type, s => ({ ...s, price_iqd: e.target.value.replace(/,/g, '').replace(/[^0-9]/g, '') }))}
                                            style={{ width: 130, padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                        />
                                    </div>
                                    <Btn variant="accent" size="sm" onClick={() => saveShift(type)} loading={state.saving}>
                                        {l.bkgSaveShift}
                                    </Btn>
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>
```

Replace with (the only change is a new sibling block inserted between the closing `)}` of the existing body div and the shift card's own closing `</div>`):

```tsx
                            {/* Card body — only shown when enabled */}
                            {state.enabled && (
                                <div style={{ padding: "14px 16px", display: "flex", flexWrap: "wrap", gap: 14, alignItems: "flex-end" }}>
                                    <div>
                                        <FieldLabel>{l.bkgShiftStart}</FieldLabel>
                                        <input type="time" value={state.starts_time}
                                            onChange={e => setShiftState(type, s => ({ ...s, starts_time: e.target.value }))}
                                            style={{ padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                        />
                                    </div>
                                    <div>
                                        <FieldLabel>{l.bkgShiftEnd}</FieldLabel>
                                        <input type="time" value={state.ends_time}
                                            onChange={e => setShiftState(type, s => ({ ...s, ends_time: e.target.value }))}
                                            style={{ padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                        />
                                    </div>
                                    <div>
                                        <FieldLabel>{l.bkgShiftPrice} (IQD)</FieldLabel>
                                        <input type="text" inputMode="numeric"
                                            value={state.price_iqd ? Number(state.price_iqd).toLocaleString('en-US') : ""}
                                            placeholder="0"
                                            onChange={e => setShiftState(type, s => ({ ...s, price_iqd: e.target.value.replace(/,/g, '').replace(/[^0-9]/g, '') }))}
                                            style={{ width: 130, padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                        />
                                    </div>
                                    <Btn variant="accent" size="sm" onClick={() => saveShift(type)} loading={state.saving}>
                                        {l.bkgSaveShift}
                                    </Btn>
                                </div>
                            )}
                            {state.enabled && (
                                <div style={{ padding: "0 16px 14px", borderTop: `1px solid ${C.border}` }}>
                                    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "12px 0 10px" }}>
                                        <Toggle checked={state.party_enabled} onChange={() => setShiftState(type, s => ({ ...s, party_enabled: !s.party_enabled }))} />
                                        <PeopleIcon size={16} color={state.party_enabled ? color : C.text4} />
                                        <span style={{ fontSize: FS.base, fontWeight: 700, color: state.party_enabled ? C.text : C.text4 }}>
                                            {l.bkgPartyPricing}
                                        </span>
                                    </div>
                                    {state.party_enabled && (
                                        <div style={{ display: "flex", flexWrap: "wrap", gap: 14, alignItems: "flex-end", paddingBottom: 4 }}>
                                            <div>
                                                <FieldLabel>{l.bkgPartyIncluded}</FieldLabel>
                                                <input type="text" inputMode="numeric"
                                                    value={state.party_included_persons}
                                                    onChange={e => setShiftState(type, s => ({ ...s, party_included_persons: e.target.value.replace(/[^0-9]/g, '') }))}
                                                    style={{ width: 90, padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                                />
                                            </div>
                                            <div>
                                                <FieldLabel>{l.bkgPartyFlatFee} (IQD)</FieldLabel>
                                                <input type="text" inputMode="numeric"
                                                    value={state.party_flat_fee_iqd ? Number(state.party_flat_fee_iqd).toLocaleString('en-US') : ""}
                                                    placeholder="0"
                                                    onChange={e => setShiftState(type, s => ({ ...s, party_flat_fee_iqd: e.target.value.replace(/,/g, '').replace(/[^0-9]/g, '') }))}
                                                    style={{ width: 130, padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                                />
                                            </div>
                                            <div>
                                                <FieldLabel>{l.bkgPartyExtraFee} (IQD)</FieldLabel>
                                                <input type="text" inputMode="numeric"
                                                    value={state.party_extra_person_fee_iqd ? Number(state.party_extra_person_fee_iqd).toLocaleString('en-US') : ""}
                                                    placeholder="0"
                                                    onChange={e => setShiftState(type, s => ({ ...s, party_extra_person_fee_iqd: e.target.value.replace(/,/g, '').replace(/[^0-9]/g, '') }))}
                                                    style={{ width: 130, padding: "8px 10px", border: `1.5px solid ${C.border}`, borderRadius: R.sm, fontSize: FS.base, fontFamily: font, color: C.text, background: "#fff", outline: "none" }}
                                                />
                                            </div>
                                        </div>
                                    )}
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>
```

Note: `color` in `<PeopleIcon color={state.party_enabled ? color : C.text4} />` refers to the `const color = SHIFT_COLOR[type];` already in scope from the enclosing `shiftRows.map(({ type, label }) => { const state = ...; const color = SHIFT_COLOR[type]; ...` block — no new variable needed.

- [ ] **Step 3: Type-check**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
npx tsc -b --noEmit
```

Expected: no errors.

- [ ] **Step 4: Manual verification**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
npm run dev
```

Open the dashboard, navigate to a farm-type place's booking config (merchant "My Places" or admin "Places" → edit a place → Booking tab), expand a shift, verify: the "Party Pricing" toggle appears below the existing fields with a divider; toggling it on reveals the three numeric fields; entering values and clicking the shift's **Save** button persists them (reload the page — values should still be there).

- [ ] **Step 5: Commit**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
git add src/features/bookings/PlaceBookingTab.tsx
git commit -m "feat(dashboard): add party pricing UI to ShiftPanel"
```

---

### Task 6: Dashboard — show party info in the booking detail modal

**Files:**
- Modify: `src/features/merchant/MyBookingsPage.tsx` (in `wansa-admin-dashboard`)

**Interfaces:**
- Consumes: `category_data.party_size` / `category_data.party_fee_iqd` written by Task 1's RPC, `l.bkgPartyPricing`-adjacent copy is inline here (not reused from Task 4's keys, since the phrasing differs — see Step 1).

- [ ] **Step 1: Add a party `DetailRow` after the existing shift-type block**

Find (around line 823-849):

```tsx
                        {(() => {
                            const place = data.places.find((p: any) => p.id === selectedBooking.place_id);
                            const bookingType = place?.booking_category;
                            if (bookingType === "shift") {
                                const shiftVal = selectedBooking.shift_type
                                    ?? selectedBooking.category_data?.shift_type
                                    ?? selectedBooking.category_data?.shift;
                                return shiftVal ? (
                                    <DetailRow label="Shift Type" value={
                                        <span style={{
                                            display: "inline-flex", alignItems: "center",
                                            padding: "3px 10px", borderRadius: R.full,
                                            fontSize: FS.sm, fontWeight: 700, letterSpacing: 0.5,
                                            textTransform: "uppercase" as const,
                                            background: C.orange + "14", color: C.orange,
                                            border: `1px solid ${C.orange}30`,
                                        }}>
                                            {shiftVal}
                                        </span>
                                    } />
                                ) : null;
                            }
                            if (bookingType === "hourly") {
                                return <DetailRow label="Court" value={courtName ?? "—"} />;
                            }
                            return null;
                        })()}
                        <DetailRow label={l.bkgStatus} value={<StatusBadge label={getStatusLabel(selectedBooking.status)} color={STATUS_COLOR[selectedBooking.status] || C.text4} />} />
```

Replace with (adds one new `(() => {...})()` block right after the existing one, before the Status row):

```tsx
                        {(() => {
                            const place = data.places.find((p: any) => p.id === selectedBooking.place_id);
                            const bookingType = place?.booking_category;
                            if (bookingType === "shift") {
                                const shiftVal = selectedBooking.shift_type
                                    ?? selectedBooking.category_data?.shift_type
                                    ?? selectedBooking.category_data?.shift;
                                return shiftVal ? (
                                    <DetailRow label="Shift Type" value={
                                        <span style={{
                                            display: "inline-flex", alignItems: "center",
                                            padding: "3px 10px", borderRadius: R.full,
                                            fontSize: FS.sm, fontWeight: 700, letterSpacing: 0.5,
                                            textTransform: "uppercase" as const,
                                            background: C.orange + "14", color: C.orange,
                                            border: `1px solid ${C.orange}30`,
                                        }}>
                                            {shiftVal}
                                        </span>
                                    } />
                                ) : null;
                            }
                            if (bookingType === "hourly") {
                                return <DetailRow label="Court" value={courtName ?? "—"} />;
                            }
                            return null;
                        })()}
                        {(() => {
                            const place = data.places.find((p: any) => p.id === selectedBooking.place_id);
                            const partySize = selectedBooking.category_data?.party_size;
                            if (place?.booking_category !== "shift" || !partySize) return null;
                            const partyFee = selectedBooking.category_data?.party_fee_iqd;
                            return (
                                <DetailRow label={lang === "ar" ? "الحفلة" : "Party"} value={
                                    <span style={{ fontWeight: 700, color: C.text }}>
                                        {lang === "ar" ? `حفلة من ${partySize}` : `Party of ${partySize}`}
                                        {typeof partyFee === "number" && partyFee > 0 && (
                                            <span style={{ color: C.text4, fontWeight: 500 }}> (+{partyFee.toLocaleString()} IQD)</span>
                                        )}
                                    </span>
                                } />
                            );
                        })()}
                        <DetailRow label={l.bkgStatus} value={<StatusBadge label={getStatusLabel(selectedBooking.status)} color={STATUS_COLOR[selectedBooking.status] || C.text4} />} />
```

- [ ] **Step 2: Type-check**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
npx tsc -b --noEmit
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
git add src/features/merchant/MyBookingsPage.tsx
git commit -m "feat(dashboard): show party size and fee in booking detail modal"
```

---

### Task 7: Dashboard — full build verification

**Files:** none (verification-only task)

- [ ] **Step 1: Full production build**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
npm run build
```

Expected: `tsc -b && vite build` completes with no errors, confirming Tasks 3-6 compile together cleanly end-to-end.

---

### Task 8: Mobile — `FarmShift` model gains party fields

**Files:**
- Modify: `lib/features/booking/domain/models/farm_shift.dart` (in `wensa`)
- Regenerate: `lib/features/booking/domain/models/farm_shift.freezed.dart`, `lib/features/booking/domain/models/farm_shift.g.dart`
- Modify: `test/features/booking/domain/models/farm_shift_test.dart`

**Interfaces:**
- Produces: `FarmShift.partyEnabled` (bool), `.partyIncludedPersons` (int), `.partyFlatFeeIqd` (int), `.partyExtraPersonFeeIqd` (int) — consumed by Task 10's `PartyOptionCard` props and Task 11's `farm_section.dart`.

- [ ] **Step 1: Write the failing tests**

Append to `test/features/booking/domain/models/farm_shift_test.dart`, inside `main()` after the existing `group('FarmShift.fromJson', ...)` block, as a new top-level group:

```dart
  group('FarmShift.fromJson party fields', () {
    const baseJson = {
      'place_id': 'place-abc',
      'shift_type': 'day',
      'starts_time': '08:00:00',
      'ends_time': '18:00:00',
      'price_iqd': 100000,
    };

    test('parses party fields when present', () {
      final shift = FarmShift.fromJson({
        ...baseJson,
        'party_enabled': true,
        'party_included_persons': 10,
        'party_flat_fee_iqd': 20000,
        'party_extra_person_fee_iqd': 5000,
      });
      expect(shift.partyEnabled, isTrue);
      expect(shift.partyIncludedPersons, 10);
      expect(shift.partyFlatFeeIqd, 20000);
      expect(shift.partyExtraPersonFeeIqd, 5000);
    });

    test('defaults party fields when absent', () {
      final shift = FarmShift.fromJson(baseJson);
      expect(shift.partyEnabled, isFalse);
      expect(shift.partyIncludedPersons, 1);
      expect(shift.partyFlatFeeIqd, 0);
      expect(shift.partyExtraPersonFeeIqd, 0);
    });
  });
```

- [ ] **Step 2: Run the test — expect a compile failure**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
flutter test test/features/booking/domain/models/farm_shift_test.dart
```

Expected: FAIL — compile error, `partyEnabled` (and the other three) are not defined on `FarmShift`.

- [ ] **Step 3: Add the fields to the model**

In `lib/features/booking/domain/models/farm_shift.dart`, replace the whole file with:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'booking_enums.dart';

part 'farm_shift.freezed.dart';
part 'farm_shift.g.dart';

@freezed
abstract class FarmShift with _$FarmShift {
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

  factory FarmShift.fromJson(Map<String, dynamic> json) => FarmShift(
    placeId: json['place_id'] ?? '',
    shiftType: FarmShiftTypeFromString.fromString(json['shift_type'] ?? ''),
    startsTime: json['starts_time'] ?? '',
    endsTime: json['ends_time'] ?? '',
    priceIqd: (json['price_iqd'] as num?)?.toInt() ?? 0,
    isAvailable: (json['is_available'] as bool?) ?? true,
    isClosed: (json['is_closed'] as bool?) ?? false,
    partyEnabled: (json['party_enabled'] as bool?) ?? false,
    partyIncludedPersons: (json['party_included_persons'] as num?)?.toInt() ?? 1,
    partyFlatFeeIqd: (json['party_flat_fee_iqd'] as num?)?.toInt() ?? 0,
    partyExtraPersonFeeIqd: (json['party_extra_person_fee_iqd'] as num?)?.toInt() ?? 0,
  );
}
```

- [ ] **Step 4: Regenerate Freezed/JSON files**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
dart run build_runner build --delete-conflicting-outputs
```

Expected: `farm_shift.freezed.dart` and `farm_shift.g.dart` regenerated without errors.

- [ ] **Step 5: Run the test — expect pass**

```bash
flutter test test/features/booking/domain/models/farm_shift_test.dart
```

Expected: 5 tests pass (3 existing + 2 new).

- [ ] **Step 6: Commit**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
git add lib/features/booking/domain/models/farm_shift.dart \
        lib/features/booking/domain/models/farm_shift.freezed.dart \
        lib/features/booking/domain/models/farm_shift.g.dart \
        test/features/booking/domain/models/farm_shift_test.dart
git commit -m "feat(model): add party pricing fields to FarmShift"
```

---

### Task 9: Mobile — `createFarmBooking` accepts an optional `partySize`

**Files:**
- Modify: `lib/features/booking/presentation/providers/booking_submit_provider.dart` (in `wensa`)

**Interfaces:**
- Consumes: the edge function's `party_size` field from Task 2.
- Produces: `BookingSubmit.createFarmBooking({..., int? partySize})` — consumed by Task 11's `farm_section.dart`.

- [ ] **Step 1: Add the `partySize` parameter**

Find:

```dart
  Future<void> createFarmBooking({
    required String placeId,
    required String date, // 'yyyy-MM-dd'
    required FarmShiftType shiftType,
    String? promoCode,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'shift',
          'place_id': placeId,
          'date': date,
          'shift_type': shiftType.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
```

Replace with:

```dart
  Future<void> createFarmBooking({
    required String placeId,
    required String date, // 'yyyy-MM-dd'
    required FarmShiftType shiftType,
    String? promoCode,
    int? partySize,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'shift',
          'place_id': placeId,
          'date': date,
          'shift_type': shiftType.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
          if (partySize != null) 'party_size': partySize,
        },
      );
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
flutter analyze lib/features/booking/presentation/providers/booking_submit_provider.dart
```

Expected: no issues. (No dedicated unit test exists for this provider's other `create*Booking` methods either — this follows the same established pattern; end-to-end coverage comes from Task 13.)

- [ ] **Step 3: Commit**

```bash
git add lib/features/booking/presentation/providers/booking_submit_provider.dart
git commit -m "feat(provider): createFarmBooking accepts optional partySize"
```

---

### Task 10: Mobile — `PartyOptionCard` widget

**Files:**
- Create: `lib/features/booking/presentation/widgets/party_option_card.dart` (in `wensa`)
- Create: `test/features/booking/presentation/widgets/party_option_card_test.dart`

**Interfaces:**
- Produces: `PartyOptionCard({required int includedPersons, required int flatFeeIqd, required int extraPersonFeeIqd, required bool isOn, required int guestCount, required ValueChanged<bool> onToggle, required ValueChanged<int> onGuestCountChanged})` — a pure, stateless, presentational widget. Consumed by Task 11's `farm_section.dart`, which owns all state via Riverpod notifiers and passes it down as props (same pattern as `ShiftCard`).

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/booking/presentation/widgets/party_option_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/party_option_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('guest stepper is hidden when off, shown when on', (tester) async {
    await tester.pumpWidget(wrap(PartyOptionCard(
      includedPersons: 10,
      flatFeeIqd: 20000,
      extraPersonFeeIqd: 5000,
      isOn: false,
      guestCount: 10,
      onToggle: (_) {},
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('10'), findsNothing);

    await tester.pumpWidget(wrap(PartyOptionCard(
      includedPersons: 10,
      flatFeeIqd: 20000,
      extraPersonFeeIqd: 5000,
      isOn: true,
      guestCount: 10,
      onToggle: (_) {},
      onGuestCountChanged: (_) {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);
    expect(find.text('No extra charge up to 10 guests'), findsOneWidget);
  });

  testWidgets('shows overage fee and tapping + increments the count', (tester) async {
    int? changedTo;
    await tester.pumpWidget(wrap(PartyOptionCard(
      includedPersons: 10,
      flatFeeIqd: 20000,
      extraPersonFeeIqd: 5000,
      isOn: true,
      guestCount: 12,
      onToggle: (_) {},
      onGuestCountChanged: (v) => changedTo = v,
    )));
    await tester.pumpAndSettle();
    expect(find.text('+10,000 IQD for 2 extra guest(s)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(changedTo, 13);
  });

  testWidgets('minus button is disabled when guestCount is 1', (tester) async {
    await tester.pumpWidget(wrap(PartyOptionCard(
      includedPersons: 5,
      flatFeeIqd: 20000,
      extraPersonFeeIqd: 5000,
      isOn: true,
      guestCount: 1,
      onToggle: (_) {},
      onGuestCountChanged: (_) {},
    )));
    await tester.pumpAndSettle();
    final minusButton = tester.widget<InkWell>(find.ancestor(
      of: find.byIcon(Icons.remove_rounded),
      matching: find.byType(InkWell),
    ));
    expect(minusButton.onTap, isNull);
  });
}
```

- [ ] **Step 2: Run the test — expect failure**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
flutter test test/features/booking/presentation/widgets/party_option_card_test.dart
```

Expected: FAIL — `party_option_card.dart` does not exist yet.

- [ ] **Step 3: Implement the widget**

Create `lib/features/booking/presentation/widgets/party_option_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

/// Toggle + guest-count stepper shown under the shift picker in
/// [FarmSection] when the selected shift has party pricing enabled.
/// Purely presentational — the caller owns all state.
class PartyOptionCard extends StatelessWidget {
  const PartyOptionCard({
    super.key,
    required this.includedPersons,
    required this.flatFeeIqd,
    required this.extraPersonFeeIqd,
    required this.isOn,
    required this.guestCount,
    required this.onToggle,
    required this.onGuestCountChanged,
  });

  final int includedPersons;
  final int flatFeeIqd;
  final int extraPersonFeeIqd;
  final bool isOn;
  final int guestCount;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onGuestCountChanged;

  static String _formatIqd(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final extraGuests = (guestCount - includedPersons).clamp(0, 1 << 30);
    final extraTotal = extraGuests * extraPersonFeeIqd;
    final String helperText;
    if (extraGuests <= 0) {
      helperText = isAr
          ? 'بدون رسوم إضافية حتى $includedPersons ضيوف'
          : 'No extra charge up to $includedPersons guests';
    } else {
      helperText = isAr
          ? '+${_formatIqd(extraTotal)} د.ع لـ $extraGuests ضيوف إضافيين'
          : '+${_formatIqd(extraTotal)} IQD for $extraGuests extra guest(s)';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn ? cs.primary.withValues(alpha: 0.35) : cs.outlineVariant,
          width: isOn ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isOn
                      ? cs.primary.withValues(alpha: 0.12)
                      : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  size: 20,
                  color:
                      isOn ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr ? 'هل تحضر مجموعة؟' : 'Bringing a party?',
                  style: (tt.titleSmall ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOn ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              Switch.adaptive(
                value: isOn,
                onChanged: onToggle,
                activeTrackColor: cs.primary,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: !isOn
                ? const SizedBox(width: double.infinity, height: 0)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isAr ? 'عدد الضيوف' : 'Guests',
                              style: (tt.bodyMedium ?? const TextStyle())
                                  .copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.7)),
                            ),
                            const Spacer(),
                            _StepperButton(
                              icon: Icons.remove_rounded,
                              onTap: guestCount > 1
                                  ? () => onGuestCountChanged(guestCount - 1)
                                  : null,
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '$guestCount',
                                textAlign: TextAlign.center,
                                style: (tt.titleMedium ?? const TextStyle())
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            _StepperButton(
                              icon: Icons.add_rounded,
                              onTap: () => onGuestCountChanged(guestCount + 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          helperText,
                          style: (tt.bodySmall ?? const TextStyle()).copyWith(
                            color: extraGuests > 0
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.5),
                            fontWeight: extraGuests > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? cs.primary.withValues(alpha: 0.10)
          : cs.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test — expect pass**

```bash
flutter test test/features/booking/presentation/widgets/party_option_card_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
git add lib/features/booking/presentation/widgets/party_option_card.dart \
        test/features/booking/presentation/widgets/party_option_card_test.dart
git commit -m "feat(widget): add PartyOptionCard"
```

---

### Task 11: Mobile — wire `PartyOptionCard` into `FarmSection`

**Files:**
- Modify: `lib/features/booking/presentation/sections/farm_section.dart` (in `wensa`)

**Interfaces:**
- Consumes: `PartyOptionCard` from Task 10, `FarmShift.partyEnabled`/`.partyIncludedPersons`/`.partyFlatFeeIqd`/`.partyExtraPersonFeeIqd` from Task 8, `BookingSubmit.createFarmBooking(..., partySize: ...)` from Task 9.

- [ ] **Step 1: Add party state notifiers**

Find:

```dart
final _farmPromoProvider =
    NotifierProvider.autoDispose<_FarmPromoNotifier, PromoApplied?>(
        _FarmPromoNotifier.new);

class _FarmPromoNotifier extends Notifier<PromoApplied?> {
  @override
  PromoApplied? build() => null;
  void set(PromoApplied? p) => state = p;
}
```

Replace with:

```dart
final _farmPromoProvider =
    NotifierProvider.autoDispose<_FarmPromoNotifier, PromoApplied?>(
        _FarmPromoNotifier.new);

class _FarmPromoNotifier extends Notifier<PromoApplied?> {
  @override
  PromoApplied? build() => null;
  void set(PromoApplied? p) => state = p;
}

class _FarmPartyOnNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

class _FarmPartyCountNotifier extends Notifier<int> {
  @override
  int build() => 1;
  void set(int v) => state = v;
}

final _farmPartyOnProvider =
    NotifierProvider.autoDispose<_FarmPartyOnNotifier, bool>(
        _FarmPartyOnNotifier.new);

final _farmPartyCountProvider =
    NotifierProvider.autoDispose<_FarmPartyCountNotifier, int>(
        _FarmPartyCountNotifier.new);
```

- [ ] **Step 2: Add the `party_option_card.dart` import**

Find:

```dart
import 'package:future_riverpod/features/booking/presentation/widgets/shift_card.dart';
```

Replace with:

```dart
import 'package:future_riverpod/features/booking/presentation/widgets/party_option_card.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/shift_card.dart';
```

- [ ] **Step 3: Watch the new providers and reset them on date/shift change**

Find:

```dart
    final selectedDate = ref.watch(_farmSelectedDateProvider);
    final selectedShift = ref.watch(_farmSelectedShiftProvider);
```

Replace with:

```dart
    final selectedDate = ref.watch(_farmSelectedDateProvider);
    final selectedShift = ref.watch(_farmSelectedShiftProvider);
    final partyOn = ref.watch(_farmPartyOnProvider);
    final partyCount = ref.watch(_farmPartyCountProvider);
```

Find (the date strip's `onSelect`):

```dart
            onSelect: (date) {
              ref.read(_farmSelectedDateProvider.notifier).set(date);
              ref.read(_farmSelectedShiftProvider.notifier).set(null);
              // Release any pending booking row server-side so the next
              // Proceed doesn't collide with it.
              ref.read(bookingSubmitProvider.notifier).cancelPending();
            },
```

Replace with:

```dart
            onSelect: (date) {
              ref.read(_farmSelectedDateProvider.notifier).set(date);
              ref.read(_farmSelectedShiftProvider.notifier).set(null);
              ref.read(_farmPartyOnProvider.notifier).set(false);
              // Release any pending booking row server-side so the next
              // Proceed doesn't collide with it.
              ref.read(bookingSubmitProvider.notifier).cancelPending();
            },
```

Find (the shift card's `onTap`):

```dart
                        onTap: () {
                          ref
                              .read(_farmSelectedShiftProvider.notifier)
                              .set(isSelected ? null : shift);
                          // Release any pending booking row server-side.
                          ref
                              .read(bookingSubmitProvider.notifier)
                              .cancelPending();
                        },
```

Replace with:

```dart
                        onTap: () {
                          ref
                              .read(_farmSelectedShiftProvider.notifier)
                              .set(isSelected ? null : shift);
                          ref.read(_farmPartyOnProvider.notifier).set(false);
                          // Release any pending booking row server-side.
                          ref
                              .read(bookingSubmitProvider.notifier)
                              .cancelPending();
                        },
```

- [ ] **Step 4: Insert the `PartyOptionCard` between the shift picker and the summary card**

Find:

```dart
          const SizedBox(height: 8),

          // ── Booking summary card (animated) ────────────────────────
          AnimatedSwitcher(
```

Replace with:

```dart
          const SizedBox(height: 8),

          // ── Party option (shown only when the selected shift allows it) ──
          if (selectedShift != null && selectedShift.partyEnabled) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PartyOptionCard(
                includedPersons: selectedShift.partyIncludedPersons,
                flatFeeIqd: selectedShift.partyFlatFeeIqd,
                extraPersonFeeIqd: selectedShift.partyExtraPersonFeeIqd,
                isOn: partyOn,
                guestCount: partyCount,
                onToggle: (v) {
                  ref.read(_farmPartyOnProvider.notifier).set(v);
                  if (v) {
                    ref
                        .read(_farmPartyCountProvider.notifier)
                        .set(selectedShift.partyIncludedPersons);
                  }
                  // A previously-created pending booking (from an earlier
                  // Proceed tap) was priced without this change — release it
                  // so the next Proceed creates a fresh, correctly-priced one.
                  ref.read(bookingSubmitProvider.notifier).cancelPending();
                },
                onGuestCountChanged: (v) {
                  ref.read(_farmPartyCountProvider.notifier).set(v);
                  ref.read(bookingSubmitProvider.notifier).cancelPending();
                },
              ),
            ),
          ],

          // ── Booking summary card (animated) ────────────────────────
          AnimatedSwitcher(
```

- [ ] **Step 5: Include the party surcharge in the subtotal and summary rows**

Find:

```dart
                    final subtotal = selectedShift.priceIqd;
                      final eff = _FarmBookingFormView._resolveEffective(
                        subtotal: subtotal,
                        promo: promo,
                        autoDiscount: autoDiscount,
                      );
```

Replace with:

```dart
                    final partyFee = partyOn
                          ? selectedShift.partyFlatFeeIqd +
                              (partyCount - selectedShift.partyIncludedPersons)
                                      .clamp(0, 1 << 30) *
                                  selectedShift.partyExtraPersonFeeIqd
                          : 0;
                      final subtotal = selectedShift.priceIqd + partyFee;
                      final eff = _FarmBookingFormView._resolveEffective(
                        subtotal: subtotal,
                        promo: promo,
                        autoDiscount: autoDiscount,
                      );
```

Find:

```dart
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
```

Replace with:

```dart
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
                            if (partyOn) ...[
                              BookingSummaryRow(
                                icon: Icons.groups_rounded,
                                label: isAr ? 'رسوم الحفلة' : 'Party fee',
                                value: _FarmBookingFormView._formatIqd(
                                    selectedShift.partyFlatFeeIqd),
                              ),
                              if (partyCount >
                                  selectedShift.partyIncludedPersons)
                                BookingSummaryRow(
                                  icon: Icons.person_add_alt_1_rounded,
                                  label: isAr ? 'ضيوف إضافيون' : 'Extra guests',
                                  value: _FarmBookingFormView._formatIqd(
                                    (partyCount -
                                            selectedShift.partyIncludedPersons) *
                                        selectedShift.partyExtraPersonFeeIqd,
                                  ),
                                ),
                            ],
                          ],
```

- [ ] **Step 6: Pass `partySize` on submit**

Find:

```dart
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
```

Replace with:

```dart
                              orElse: () {
                                final shift = selectedShift;
                                ref
                                    .read(bookingSubmitProvider.notifier)
                                    .createFarmBooking(
                                      placeId: placeId,
                                      date: bookingFormatDate(selectedDate),
                                      shiftType: shift.shiftType,
                                      promoCode: promo?.code,
                                      partySize: partyOn ? partyCount : null,
                                    );
                              },
```

- [ ] **Step 7: Analyze**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
flutter analyze lib/features/booking/presentation/sections/farm_section.dart
```

Expected: no issues.

- [ ] **Step 8: Commit**

```bash
git add lib/features/booking/presentation/sections/farm_section.dart
git commit -m "feat(booking): wire PartyOptionCard into farm shift booking flow"
```

---

### Task 12: Mobile — show party size on the ticket/booking detail page

**Files:**
- Modify: `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart` (in `wensa`)

**Interfaces:**
- Consumes: `booking.categoryData['party_size']` written by Task 1's RPC.

- [ ] **Step 1: Add a conditional guest-count cell in the `shift` case**

Find:

```dart
      case BookingCategory.shift:
        extraCells.add(
          TicketInfoCell(
            label: isArabic ? 'الوردية' : 'Shift',
            value: _shiftTypeLabel(d['shift_type']?.toString() ?? '', isArabic),
          ),
        );
```

Replace with:

```dart
      case BookingCategory.shift:
        extraCells.add(
          TicketInfoCell(
            label: isArabic ? 'الوردية' : 'Shift',
            value: _shiftTypeLabel(d['shift_type']?.toString() ?? '', isArabic),
          ),
        );
        if (d['party_size'] != null) {
          extraCells.add(
            TicketInfoCell(
              label: isArabic ? 'عدد الضيوف' : 'Guests',
              value: d['party_size'].toString(),
            ),
          );
        }
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
flutter analyze lib/features/bookings_history/presentation/pages/ticket_detail_page.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/bookings_history/presentation/pages/ticket_detail_page.dart
git commit -m "feat(tickets): show guest count on shift booking tickets"
```

---

### Task 13: Full regression pass

**Files:** none (verification-only task)

- [ ] **Step 1: Static analysis, full project**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
flutter analyze
```

Expected: no new issues introduced by this feature (pre-existing issues elsewhere, if any, are out of scope).

- [ ] **Step 2: Full test suite**

```bash
flutter test
```

Expected: all tests pass, including the new `farm_shift_test.dart` cases and `party_option_card_test.dart`.

- [ ] **Step 3: Manual end-to-end QA on a device/simulator**

```bash
flutter run
```

Walk through:
1. As merchant/admin in the dashboard, enable party pricing on a farm's day shift: included = 10, flat fee = 20,000 IQD, extra = 5,000 IQD/guest. Leave night/full untouched.
2. In the mobile app, open that farm's shift booking flow, select the day shift — confirm the "Bringing a party?" card appears; select the night shift — confirm it does NOT appear.
3. Re-select the day shift, toggle the party switch on — stepper appears at 10, helper text reads "No extra charge up to 10 guests", summary total includes +20,000 IQD.
4. Tap `+` three times (to 13) — helper text updates to "+15,000 IQD for 3 extra guest(s)", summary total increases by another 15,000 IQD.
5. Apply a promo code — confirm the discount is computed against the full (base + party) subtotal.
6. Complete payment — confirm the booking succeeds; open its ticket — confirm "Guests: 13" appears alongside the shift type.
7. In the dashboard's booking list for that merchant, open the same booking's detail modal — confirm "Party of 13 (+35,000 IQD)" appears.
8. Toggle the party switch off before paying on a fresh attempt — confirm the total reverts to the base shift price and no party fields are sent (verify via the network inspector or by confirming `category_data` on the resulting booking has no `party_size`).

---

## Self-Review Notes

- **Spec coverage:** pricing formula (Task 1), per-shift config (Tasks 1, 3-5), no hard cap (Task 1 has no cap logic, Task 10's stepper has no upper bound), dashboard shared merchant+admin (Tasks 3-5, single shared `PlaceBookingTab`/`ShiftPanel`), edge function passthrough (Task 2, both repos), mobile toggle+stepper+summary (Tasks 8-11), ticket/booking detail display (Tasks 6, 12), out-of-scope items (no hard cap, no other booking types, no restaurant `party_size` changes) — none touched. All covered.
- **Placeholder scan:** the only bracketed text is `<real-place-id>` in Task 1's manual SQL smoke test and `<project-ref>` context notes — both are standard data-substitution instructions matching this codebase's existing plan precedent (`2026-05-11-farm-shift-blocking.md`), not unresolved design gaps.
- **Type consistency:** `FarmShift.partyEnabled/.partyIncludedPersons/.partyFlatFeeIqd/.partyExtraPersonFeeIqd` (Task 8) match the props consumed in Task 11's `PartyOptionCard` instantiation and Task 10's constructor (`includedPersons`, `flatFeeIqd`, `extraPersonFeeIqd`) exactly. `createFarmBooking(..., partySize: int?)` (Task 9) matches the call site in Task 11 Step 6. Dashboard `ShiftRowState.party_*` (Task 3) match the JSX field bindings in Task 5 and the `saveShift` payload exactly.
