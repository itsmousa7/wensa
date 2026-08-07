# Shift Party Pricing Design

**Date:** 2026-08-06
**Status:** Approved

## Problem

Farm shift bookings (`bookings.farm_shifts` — day / night / full day) currently charge a single flat `price_iqd` per shift regardless of how many guests attend. Merchants who run farms/chalets want to charge more when a customer brings a party: a flat surcharge for hosting a party at all, plus a per-guest surcharge once the party exceeds a merchant-configured included headcount. Today there is no way to configure or charge this — it would have to be handled manually, outside the app.

## Goal

Let merchants (and admins, who share the same dashboard write access) configure, per shift, optional "party pricing":
- Enable/disable
- Included guests (covered by the base shift price)
- Flat Extra Guests Fee (charged the moment the customer says they're Having a Party)
- Extra-guest fee (charged per guest beyond "included guests")

Let customers, in the shift booking flow, toggle "Having a Party?" and enter a guest count, seeing the price update live before paying. The server computes and enforces the final charge — the client only ever transmits a guest count, never a price.

## Pricing Formula

```
total_iqd = shift.price_iqd
          + (party_on ? shift.party_flat_fee_iqd : 0)
          + (party_on ? max(0, guest_count - shift.party_included_persons) * shift.party_extra_person_fee_iqd : 0)
```

No hard cap on guest count — overage scales freely. Party pricing is configured **per shift** (day/night/full can each differ), matching how `price_iqd` is already configured per shift.

---

## Section 1 — Database

### New migration: `20260806000001_farm_shift_party_pricing.sql`

Add four columns to `bookings.farm_shifts`:

```sql
ALTER TABLE bookings.farm_shifts
  ADD COLUMN party_enabled              boolean NOT NULL DEFAULT false,
  ADD COLUMN party_included_persons     integer NOT NULL DEFAULT 1  CHECK (party_included_persons > 0),
  ADD COLUMN party_flat_fee_iqd         integer NOT NULL DEFAULT 0  CHECK (party_flat_fee_iqd >= 0),
  ADD COLUMN party_extra_person_fee_iqd integer NOT NULL DEFAULT 0  CHECK (party_extra_person_fee_iqd >= 0);
```

Defaults are additive/non-breaking — every existing shift row keeps `price_iqd`-only behavior (`party_enabled = false`).

`public.farm_shifts` is `SELECT * FROM bookings.farm_shifts WITH (security_invoker = true)` — no view migration needed, the new columns pass through automatically. Same RLS as today (`is_admin() OR is_merchant_staff_of(...)` for write, public read) — no policy change needed.

### Update `bookings.create_farm_booking` (same migration file, `CREATE OR REPLACE FUNCTION`)

Add parameter `p_party_size integer DEFAULT NULL`. After looking up `v_shift`:

```sql
IF p_party_size IS NOT NULL AND NOT v_shift.party_enabled THEN
  RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
END IF;

v_party_fee := CASE
  WHEN p_party_size IS NOT NULL AND v_shift.party_enabled THEN
    v_shift.party_flat_fee_iqd
      + GREATEST(0, p_party_size - v_shift.party_included_persons) * v_shift.party_extra_person_fee_iqd
  ELSE 0
END;
```

- `amount_iqd` becomes `v_shift.price_iqd + v_party_fee` (was `v_shift.price_iqd`).
- `category_data` gains `party_size` (when provided) and `party_fee_iqd` (when `v_party_fee > 0`), alongside the existing `shift_type`:
  ```sql
  jsonb_build_object('shift_type', p_shift_type)
    || (CASE WHEN p_party_size IS NOT NULL THEN jsonb_build_object('party_size', p_party_size) ELSE '{}'::jsonb END)
    || (CASE WHEN v_party_fee > 0 THEN jsonb_build_object('party_fee_iqd', v_party_fee) ELSE '{}'::jsonb END)
  ```
- `p_party_size`, if provided, must be `>= 1` (`RAISE EXCEPTION` otherwise) — a party of zero doesn't make sense as a distinct state from the toggle being off.

### Update `public.create_farm_booking` wrapper (same migration file)

Add `p_party_size integer DEFAULT NULL` and pass it through:

```sql
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

---

## Section 2 — Edge Function

**File:** `supabase/functions/create-booking/index.ts`

- Accept optional `party_size?: number` in the request body alongside the existing `shift_type` for the `shift` category.
- Pass it through as `p_party_size` in the `callRpc(..., "create_farm_booking", { ..., p_shift_type: p.shift_type, p_party_size: p.party_size ?? null })` call.
- No validation duplication needed — the RPC already rejects invalid combinations (party size sent for a shift without party pricing enabled, size < 1).

---

## Section 3 — Merchant + Admin Dashboard (`wansa-admin-dashboard`)

Both roles render the exact same component today: `PlaceBookingTab` → `ShiftPanel`, from both `PlacesPage.tsx` (admin) and `MyPlacesPage.tsx` (merchant), gated by the same RLS. **One implementation change covers both surfaces.**

**File:** `src/features/bookings/PlaceBookingTab.tsx`

- Extend the `FarmShift` interface with `party_enabled`, `party_included_persons`, `party_flat_fee_iqd`, `party_extra_person_fee_iqd`.
- Extend `ShiftRowState` with the same four fields (party defaults: `enabled: false`, `included_persons: "1"`, `flat_fee_iqd: ""`, `extra_person_fee_iqd: ""`).
- `fetchData()`: populate the new state fields from the fetched row (or defaults) the same way the existing `starts_time`/`ends_time`/`price_iqd` are populated.
- `saveShift(type)`: include the four new fields in the upsert `payload`, parsing numeric inputs the same way `price_iqd` is parsed (strip commas, `parseInt`).
- **UI** — inside each shift card's body (only rendered when the shift itself is `enabled`), below the existing Start/End/Price row, add a divider and a "Party Pricing" sub-section:
  - A `Toggle` — "Allow parties on this shift"
  - When on, three compact fields in a row: **Included Guests** (number), **Extra Guests Fee** (IQD), **Fee per Extra Guest** (IQD)
  - No separate save button — covered by the shift's existing **Save** button
  - Icon: a plain inline SVG people/group icon (never an emoji, per dashboard convention), colored with the shift's existing `SHIFT_COLOR[type]` accent when the sub-toggle is on, `C.text4` otherwise

**Translations** (`src/context/translations/en.ts` / `ar.ts`): add `bkgPartyPricing`, `bkgPartyEnable`, `bkgPartyIncluded`, `bkgPartyFlatFee`, `bkgPartyExtraFee` keys, following the existing `bkgShift*` naming pattern.

**Booking display:** wherever a farm/shift booking's `category_data` is already surfaced in the dashboard (the pending-bookings list pattern used in `ReservationPanel` for `category_data.party_size`), add the same treatment for shift bookings — a small "Party of {party_size}" badge when `category_data.party_size` is present. Exact call site(s) to be confirmed during implementation planning (this repo has more than one bookings list view).

---

## Section 4 — Mobile App (Flutter)

### Model

**File:** `lib/features/booking/domain/models/farm_shift.dart`

Add to the `FarmShift` freezed class:
```dart
@Default(false) bool partyEnabled,
@Default(1) int partyIncludedPersons,
@Default(0) int partyFlatFeeIqd,
@Default(0) int partyExtraPersonFeeIqd,
```
Parse the matching snake_case keys in `fromJson` (defaulting the same way `isAvailable`/`isClosed` already do). Regenerate `farm_shift.freezed.dart` and `farm_shift.g.dart` via `build_runner`.

### Submit provider

**File:** `lib/features/booking/presentation/providers/booking_submit_provider.dart`

`createFarmBooking(...)` gains an optional `int? partySize` parameter, included in the `create-booking` function body as `'party_size': partySize` only when non-null.

### UI

**File:** `lib/features/booking/presentation/sections/farm_section.dart`

- New local state: `_FarmPartyOnNotifier` (bool, default false) and `_FarmPartySizeNotifier` (int, default synced to the selected shift's `partyIncludedPersons`), both `autoDispose`. Reset (like the existing promo reset) whenever the date or shift selection changes.
- New card, `PartyOptionCard` (new widget file `lib/features/booking/presentation/widgets/party_option_card.dart`), rendered between the shift picker and the booking summary card, only when `selectedShift != null && selectedShift.partyEnabled`:
  - Header row: people icon + "Having a Party?" / "لديك حفلة؟" + a `Switch`
  - `AnimatedSize` reveal when on: a guest-count stepper (−/+ buttons around a number), min `1`, starting value = `shift.partyIncludedPersons`
  - Live helper text below the stepper: "No extra charge up to {N} guests" when `count <= included`, or "+{fee} IQD for {n} extra guest(s)" when over
- `BookingSummaryCard` rows: when party is on, add "Extra Guests Fee" (flat fee) and, when `count > included`, "Extra guests" rows before the subtotal — the existing `_resolveEffective` discount logic already operates generically on `subtotal`, so promo/auto-discount naturally apply to the party-inclusive total with no special-casing.
- `subtotal` computation becomes `selectedShift.priceIqd + (partyOn ? partyFlatFee + max(0, count - included) * extraFee : 0)`.
- `onAction` (Proceed to Payment) passes `partySize: partyOn ? count : null` into `createFarmBooking`.

### Booking detail / ticket display (minor)

Wherever a confirmed farm booking's details are shown (bookings history / ticket page), if `categoryData['party_size']` is present, show it alongside the existing shift-type display — same pattern already used for `categoryData`, no model change needed since `categoryData` is already a generic `Map<String, dynamic>`.

---

## Data Flow

```
Customer selects shift with partyEnabled = true
  └─> PartyOptionCard appears
        └─> toggles on → stepper appears, defaults to partyIncludedPersons
              └─> BookingSummaryCard recomputes subtotal live (client-side estimate)

Customer taps "Proceed to Payment"
  └─> createFarmBooking(..., partySize: N)
        └─> create-booking edge function
              └─> public.create_farm_booking(place_id, date, shift_type, party_size)
                    └─> bookings.create_farm_booking (SECURITY DEFINER, authoritative)
                          ├─> validates party_size against shift.party_enabled
                          ├─> computes party_fee server-side
                          ├─> amount_iqd = price_iqd + party_fee
                          └─> category_data += {party_size, party_fee_iqd}
                    └─> booking row inserted, payment flow proceeds as today (Wayl)
```

Merchant/admin configuration flow is unchanged in shape — it's the same `ShiftPanel` save path, just with four more fields per shift.

---

## Error Handling

- RPC rejects `party_size` sent for a shift where `party_enabled = false`, and `party_size < 1` — surfaces through the existing `create-booking` error path (`result.status != 200` → thrown `Exception` → shown via `SnackBar` in `FarmSection`'s existing `ref.listen` error handler). No new client-side error UI needed.
- If the merchant disables party pricing on a shift *after* the customer has it toggled on client-side but *before* they hit Proceed, the RPC rejection surfaces the same way — client does not need to pre-validate this race, it's rare and already-handled generically.
- Dashboard form validation: numeric fields reuse the existing comma-stripping/`parseInt` pattern already used for `price_iqd`; no negative values (enforced by DB `CHECK` as the backstop, matching how court/shift prices are handled today).

## Testing Notes

- Merchant enables party pricing on the day shift (included: 10, flat fee: 20,000 IQD, extra: 5,000 IQD/guest) → mobile shows the toggle only on the day shift, not night/full.
- Toggle on, leave stepper at 10 → summary shows base price + 20,000 IQD, no extra-guest line.
- Increase stepper to 13 → summary adds `20,000 + 3*5,000 = 35,000` IQD on top of base.
- Apply a promo code with party on → discount computed against the full (base + party) subtotal.
- Complete payment → booking's `category_data` contains `party_size: 13` and `party_fee_iqd: 35000`; dashboard pending-bookings view shows "Party of 13".
- Toggle off before paying → price reverts to base shift price, no `party_size` sent.
- Merchant disables party pricing on a shift with no bookings in flight — mobile no longer shows the toggle for that shift on next fetch.
- Existing shifts with no party config (`party_enabled = false` default) behave exactly as before — regression check.
