# Farm Party Toggle / Guest Counter Split Design

**Date:** 2026-08-06
**Status:** Approved

## Problem

The just-shipped party pricing feature (see [2026-08-06-shift-party-pricing-design.md](./2026-08-06-shift-party-pricing-design.md)) bundles two different concepts into one `PartyOptionCard` + one "bringing a party?" toggle:

1. A flat party fee, charged the moment the toggle is switched on.
2. A per-guest overage fee, charged once a guest count (only enterable while the toggle is on) exceeds the merchant's included headcount.

This has three problems, all reported against the live screen:

- The toggle's `Switch.adaptive` looks and behaves differently from the frosted/native switch already used for the language toggle in Settings (`CNSwitch`), so the app feels inconsistent.
- Coupling the guest count to the toggle means a customer who isn't "bringing a party" in the flat-fee sense has no way to tell the merchant how many people are actually coming — so a group that quietly exceeds the included headcount on a "normal" (toggle-off) booking is never charged the overage the merchant configured.
- Visually, the `PartyOptionCard` block and the `BookingSummaryCard` below it render with no vertical gap, so on smaller screens the two containers collide.

## Goal

Split the single card into two independent concerns, restyle the switch, and fix the spacing bug:

1. **Party toggle** — a plain on/off switch, no guest number attached. Adds the shift's flat party fee when on. Uses the same glass/native switch as the Settings language toggle.
2. **Guest counter** — a separate "How many people are going?" stepper, shown whenever the selected shift has party pricing configured (i.e. a guest limit exists), independent of the toggle. Defaults to `1`. Whenever the count exceeds the shift's included-guest limit, the overage fee is charged — regardless of whether the toggle is on.
3. Both fees are additive and fully independent: turning the toggle off does not clear or hide the guest counter, and lowering the guest count back under the limit does not affect the toggle.

## Pricing Formula (revised)

```
total_iqd = shift.price_iqd
          + (party_on ? shift.party_flat_fee_iqd : 0)
          + max(0, guest_count - shift.party_included_persons) * shift.party_extra_person_fee_iqd
```

The overage term drops its `party_on ?` guard — it now applies purely based on `guest_count`, which itself is only collected (defaults to 1, min 1) when `shift.party_enabled` is true.

---

## Section 1 — Database

### New migration (do not edit `20260806000001` — already applied live)

`bookings.create_farm_booking` / `public.create_farm_booking` gain a new parameter `p_bringing_party boolean DEFAULT false`, replacing the current "a guest count implies the flat fee" behavior:

```sql
DROP FUNCTION IF EXISTS bookings.create_farm_booking(uuid, date, bookings.farm_shift_type, integer);

CREATE OR REPLACE FUNCTION bookings.create_farm_booking(
  p_place_id       uuid,
  p_date           date,
  p_shift_type     bookings.farm_shift_type,
  p_party_size     integer DEFAULT NULL,
  p_bringing_party boolean DEFAULT false
)
...
  IF p_party_size IS NOT NULL AND NOT v_shift.party_enabled THEN
    RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
  END IF;
  IF p_party_size IS NOT NULL AND p_party_size < 1 THEN
    RAISE EXCEPTION 'party_size must be at least 1' USING ERRCODE = 'P0004';
  END IF;
  IF p_bringing_party AND NOT v_shift.party_enabled THEN
    RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
  END IF;

  v_party_fee := (CASE WHEN p_bringing_party THEN v_shift.party_flat_fee_iqd ELSE 0 END)
    + GREATEST(0, COALESCE(p_party_size, 1) - v_shift.party_included_persons)
        * v_shift.party_extra_person_fee_iqd;
```

- `category_data` gains `party_size` (when provided), `bringing_party` (when true), and `party_fee_iqd` (when `v_party_fee > 0`) — same pattern as today, just no longer conditioned on each other.
- `public.create_farm_booking` wrapper gets the same new parameter, passed straight through.
- Same `DROP FUNCTION IF EXISTS` + `CREATE OR REPLACE` two-step as the original migration (Postgres can't change a function's argument list via plain `CREATE OR REPLACE`).
- Apply live via Supabase MCP `apply_migration`, same as the prior two migrations in this feature (this repo's `supabase db push` is blocked by unrelated migration-history drift, per the existing commit history).

---

## Section 2 — Edge Function

**File:** `supabase/functions/create-booking/index.ts`

- Add `bringing_party?: boolean` to the `shift`-category request body type (alongside the existing `party_size?: number`).
- Pass both through: `p_party_size: p.party_size ?? null, p_bringing_party: p.bringing_party ?? false`.

---

## Section 3 — Mobile App (Flutter)

### `PartyOptionCard` (rewrite) — `lib/features/booking/presentation/widgets/party_option_card.dart`

Drops the guest stepper and the `AnimatedSize` reveal entirely. Becomes a stateless row: icon, "Bringing a party?" / "هل تحضر مجموعة؟" label, and the switch. Helper text (when `flatFeeIqd > 0`) states the flat fee only, e.g. "20,000 IQD party fee" — no guest-count-derived text since guest count no longer belongs to this widget.

Switch: mirror `profile_content.dart:124-139` —

```dart
Platform.isIOS
    ? CNSwitch(value: isOn, onChanged: onToggle)
    : Switch.adaptive(value: isOn, onChanged: onToggle, activeTrackColor: cs.primary),
```

Props shrink to `{flatFeeIqd, isOn, onToggle}` — `includedPersons`, `extraPersonFeeIqd`, `guestCount`, `onGuestCountChanged` move to the new widget below.

### New `GuestCountCard` — `lib/features/booking/presentation/widgets/guest_count_card.dart`

A second, separate container (own border/shadow, matching `PartyOptionCard`'s visual weight) rendered directly below it:

- Header: "How many people are going?" / "كم عدد الأشخاص القادمين؟"
- Reuses the existing `_StepperButton` −/+ control and number display (moved from `PartyOptionCard`), min `1`, no upper bound.
- Helper text reuses the existing overage-formatting logic verbatim (`No extra charge up to {N} guests` / `+{fee} IQD for {n} extra guest(s)`), now driven purely by `guestCount` vs `includedPersons` — no `flatFeeIqd` concatenation (that text now lives solely on `PartyOptionCard`).
- Props: `{includedPersons, extraPersonFeeIqd, guestCount, onGuestCountChanged}`.

### `farm_section.dart`

- `_farmPartyOnProvider` (bool) stays, still resets to `false` on date/shift change.
- `_farmPartyCountProvider` (int, default `1`) stays, but its `build()`/reset value becomes `1` (not tied to `includedPersons` anymore), and it now also resets on date/shift change (today it silently carries over — harmless since the card was hidden, but needs an explicit reset now that the counter is independently visible).
- Rendering: replace the single `if (partyEnabled) [PartyOptionCard(...)]` block with two blocks in sequence, each wrapped in its own `Padding` + spacing, both gated on `selectedShift.partyEnabled`:
  ```dart
  if (selectedShift != null && selectedShift.partyEnabled) ...[
    const SizedBox(height: 16),
    Padding(..., child: PartyOptionCard(flatFeeIqd: ..., isOn: partyOn, onToggle: ...)),
    const SizedBox(height: 12),
    Padding(..., child: GuestCountCard(includedPersons: ..., extraPersonFeeIqd: ..., guestCount: partyCount, onGuestCountChanged: ...)),
    const SizedBox(height: 16),   // ← fixes the reported overflow/no-gap bug
  ],
  ```
  The trailing `SizedBox(height: 16)` before the `AnimatedSwitcher` is the actual fix for the reported collision — today's `if` block has no spacing after it at all.
- `onToggle` no longer touches `_farmPartyCountProvider` (previously snapped it to `includedPersons` when switched on — removed, since count is independent now).
- Fee computation (both in the summary `Builder` and in the submit `onAction`) becomes:
  ```dart
  final extraGuests = (partyCount - selectedShift.partyIncludedPersons).clamp(0, 1 << 30);
  final partyFee = (partyOn ? selectedShift.partyFlatFeeIqd : 0)
      + extraGuests * selectedShift.partyExtraPersonFeeIqd;
  ```
- Summary rows: "Party fee" shown when `partyOn && flatFeeIqd > 0` (unchanged condition); "Extra guests" shown when `extraGuests > 0` (drops the `partyOn &&` guard it has today).
- `onAction` passes both fields to `createFarmBooking`: `partySize: selectedShift.partyEnabled ? partyCount : null, bringingParty: partyOn`.

### `booking_submit_provider.dart`

`createFarmBooking(...)` gains `bool bringingParty = false`, included in the edge-function body as `'bringing_party': bringingParty` (always sent, matching the RPC's `DEFAULT false`; no need for the `if (... != null)` pattern used for the nullable `partySize`).

### Test updates — `test/features/booking/presentation/widgets/party_option_card_test.dart`

Rewritten for the new narrower `PartyOptionCard` (no more guest-count assertions — those move to a new `guest_count_card_test.dart` covering the stepper/helper-text/min-1 behavior that used to live here).

---

## Data Flow

```
Customer selects a shift with partyEnabled = true
  ├─> PartyOptionCard (flat-fee toggle) — independent
  └─> GuestCountCard (headcount, default 1) — independent
        └─> both feed BookingSummaryCard's live subtotal

Customer taps "Proceed to Payment"
  └─> createFarmBooking(..., partySize: N, bringingParty: bool)
        └─> create-booking edge function
              └─> public.create_farm_booking(..., p_party_size, p_bringing_party)
                    └─> bookings.create_farm_booking (SECURITY DEFINER, authoritative)
                          ├─> flat fee applied iff p_bringing_party
                          ├─> overage applied iff p_party_size > included_persons
                          └─> amount_iqd = price_iqd + flat_fee_component + overage_component
```

## Error Handling

- Same RPC-side validation as today (`party_size < 1`, party fields sent when `party_enabled = false`), now also covering `p_bringing_party = true` on a non-party-enabled shift. Surfaces through the existing `create-booking` error path → `SnackBar`, no new client UI.
- No client-side pre-validation of the merchant disabling party pricing mid-flow — same accepted race as the original design.

## Testing Notes

- Shift with `included: 10, flat: 20,000, extra: 5,000`, toggle **off**, guest count raised to 13 → summary shows base price + `3 * 5,000 = 15,000` "Extra guests" row, **no** "Party fee" row.
- Same shift, toggle **on**, guest count left at 1 → summary shows base price + `20,000` "Party fee" row, **no** "Extra guests" row.
- Toggle on **and** count raised to 13 → both rows shown, total includes both components.
- Switch renders as `CNSwitch` on iOS, `Switch.adaptive` on Android, matching the Settings language toggle's implementation.
- No visible gap/overlap between the party section and `BookingSummaryCard` on a small-height device (the originally reported bug).
- Existing shifts with `party_enabled = false` show neither card — unchanged, regression check.
