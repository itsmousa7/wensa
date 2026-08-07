# Farm Party Toggle / Guest Counter Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the farm-shift "Having a Party?" toggle from its guest-count stepper into two independent widgets, restyle the toggle to match the Settings language switch, decouple their fees server-side, and fix a spacing bug where the party card collides with the booking summary card.

**Architecture:** `PartyOptionCard` shrinks to a bare toggle (flat fee only). A new `GuestCountCard` owns the guest stepper (overage fee only), shown whenever the shift has party pricing configured, independent of the toggle. The two fees, previously bundled behind one "guest count implies flat fee" RPC parameter, become two independent RPC parameters (`p_party_size`, `p_bringing_party`) threaded through the `create-booking` edge function and `booking_submit_provider.dart`.

**Tech Stack:** Flutter (Riverpod, freezed), Supabase Postgres (plpgsql RPC via Supabase MCP), Supabase Edge Functions (Deno/TypeScript), `cupertino_native_better` (`CNSwitch`).

## Global Constraints

- Do not edit `supabase/migrations/20260806000001_farm_shift_party_pricing.sql` or `20260806000002_available_farm_shifts_party_fields.sql` — both are already applied live. All DB changes go in a new migration file.
- Migrations in this repo are applied live via the Supabase MCP `apply_migration` tool, not `supabase db push` (blocked by unrelated migration-history drift — see prior commits `db47847`, `392fd56`).
- Changing a Postgres function's argument list requires `DROP FUNCTION IF EXISTS` before `CREATE OR REPLACE FUNCTION` — `CREATE OR REPLACE` alone creates an ambiguous overload instead of replacing it.
- The client never computes or sends a price — the RPC is the sole source of truth for `amount_iqd`.
- Widget helper text and labels follow the existing bilingual pattern (`isAr ? '...' : '...'`) used throughout `farm_section.dart` / `party_option_card.dart`.
- IQD formatting uses the existing `_formatIqd` comma-grouping pattern already duplicated in both `farm_section.dart` and `party_option_card.dart` — keep using it verbatim, don't introduce a third copy.

---

### Task 1: Database — decouple flat fee from guest count in `create_farm_booking`

**Files:**
- Create: `supabase/migrations/20260806000003_farm_party_toggle_guest_split.sql`

**Interfaces:**
- Produces: `bookings.create_farm_booking(p_place_id uuid, p_date date, p_shift_type bookings.farm_shift_type, p_party_size integer DEFAULT NULL, p_bringing_party boolean DEFAULT false)` and the matching `public.create_farm_booking` wrapper — both callable by the edge function via `p_bringing_party` (new) alongside the existing `p_party_size`.

- [ ] **Step 1: Write the migration file**

```sql
-- ============================================================
-- Migration: Farm party toggle / guest counter split
-- Date: 2026-08-06
-- ============================================================
--
-- The party flat fee and the per-guest overage fee were bundled together:
-- sending a guest count at all implied the flat fee applied. This splits
-- them into two independent inputs:
--   - p_bringing_party: customer opted into the flat Extra Guests Fee
--   - p_party_size: headcount, drives the per-guest overage fee
-- regardless of each other.

DROP FUNCTION IF EXISTS bookings.create_farm_booking(uuid, date, bookings.farm_shift_type, integer);

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

-- ── public.create_farm_booking wrapper ──────────────────────────────────────
DROP FUNCTION IF EXISTS public.create_farm_booking(uuid, date, bookings.farm_shift_type, integer);

CREATE OR REPLACE FUNCTION public.create_farm_booking(
  p_place_id       uuid,
  p_date           date,
  p_shift_type     bookings.farm_shift_type,
  p_party_size     integer DEFAULT NULL,
  p_bringing_party boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.create_farm_booking(p_place_id, p_date, p_shift_type, p_party_size, p_bringing_party);
$$;
```

- [ ] **Step 2: Apply the migration live via Supabase MCP**

Use the `mcp__plugin_supabase_supabase__apply_migration` tool with:
- `name`: `farm_party_toggle_guest_split`
- `query`: the full SQL from Step 1

- [ ] **Step 3: Verify both function signatures were replaced (not overloaded)**

Run via `mcp__plugin_supabase_supabase__execute_sql`:

```sql
SELECT p.proname, pg_get_function_arguments(p.oid) AS args
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname = 'create_farm_booking'
ORDER BY n.nspname;
```

Expected: exactly **two** rows (one for `bookings`, one for `public`), each showing `p_party_size integer DEFAULT NULL, p_bringing_party boolean DEFAULT false` at the end of the argument list. If either schema shows more than one row for `create_farm_booking`, the old signature wasn't dropped — re-run the `DROP FUNCTION IF EXISTS` for that schema's 4-arg form and reapply.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260806000003_farm_party_toggle_guest_split.sql
git commit -m "feat(db): decouple farm party flat fee from guest-count overage fee"
```

---

### Task 2: Edge function — pass `bringing_party` through to the RPC

**Files:**
- Modify: `supabase/functions/create-booking/index.ts:57-58` (interface), `:181-186` (RPC call)

**Interfaces:**
- Consumes: `bookings.create_farm_booking(..., p_party_size, p_bringing_party)` from Task 1.
- Produces: `ShiftPayload.bringing_party?: boolean` on the request body — consumed by `booking_submit_provider.dart` in Task 3.

- [ ] **Step 1: Add `bringing_party` to `ShiftPayload`**

In `supabase/functions/create-booking/index.ts`, change:

```ts
interface ShiftPayload extends BasePaylod {
  category: "shift";
  place_id: string;
  date: string;
  shift_type: "day" | "night" | "full";
  party_size?: number;
}
```

to:

```ts
interface ShiftPayload extends BasePaylod {
  category: "shift";
  place_id: string;
  date: string;
  shift_type: "day" | "night" | "full";
  party_size?: number;
  bringing_party?: boolean;
}
```

- [ ] **Step 2: Pass it through in the RPC call**

Change:

```ts
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_farm_booking", {
        p_place_id:   p.place_id,
        p_date:       p.date,
        p_shift_type: p.shift_type,
        p_party_size: p.party_size ?? null,
      });
```

to:

```ts
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_farm_booking", {
        p_place_id:       p.place_id,
        p_date:           p.date,
        p_shift_type:     p.shift_type,
        p_party_size:     p.party_size ?? null,
        p_bringing_party: p.bringing_party ?? false,
      });
```

- [ ] **Step 3: Deploy the function**

Use the `mcp__plugin_supabase_supabase__deploy_edge_function` tool for `create-booking` with the updated file contents (same deployment path used for the prior `create-booking v59` deploy — see `hyperpay-migration-status` history).

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/create-booking/index.ts
git commit -m "feat(functions): thread bringing_party through create-booking"
```

---

### Task 3: `booking_submit_provider.dart` — add `bringingParty` param

**Files:**
- Modify: `lib/features/booking/presentation/providers/booking_submit_provider.dart:65-98`

**Interfaces:**
- Consumes: edge function body field `bringing_party` (Task 2).
- Produces: `createFarmBooking({..., int? partySize, bool bringingParty = false})` — called by `farm_section.dart` in Task 6.

- [ ] **Step 1: Add the parameter and body field**

Change the method signature and body in `createFarmBooking`:

```dart
  Future<void> createFarmBooking({
    required String placeId,
    required String date, // 'yyyy-MM-dd'
    required FarmShiftType shiftType,
    String? promoCode,
    int? partySize,
    bool bringingParty = false,
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
          'bringing_party': bringingParty,
        },
      );
```

(the rest of the method body — response parsing and error handling — is unchanged)

- [ ] **Step 2: Verify with static analysis**

Run: `flutter analyze lib/features/booking/presentation/providers/booking_submit_provider.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/booking/presentation/providers/booking_submit_provider.dart
git commit -m "feat(booking): add bringingParty param to createFarmBooking"
```

---

### Task 4: Rewrite `PartyOptionCard` — bare toggle, native glass switch

**Files:**
- Modify: `lib/features/booking/presentation/widgets/party_option_card.dart` (full rewrite)
- Modify: `test/features/booking/presentation/widgets/party_option_card_test.dart` (full rewrite)

**Interfaces:**
- Produces: `PartyOptionCard({Key? key, required int flatFeeIqd, required bool isOn, required ValueChanged<bool> onToggle})` — consumed by `farm_section.dart` in Task 6. Guest-count props (`includedPersons`, `extraPersonFeeIqd`, `guestCount`, `onGuestCountChanged`) are **removed** from this widget — they move to `GuestCountCard` (Task 5).

- [ ] **Step 1: Write the failing test (full rewrite)**

Replace the entire contents of `test/features/booking/presentation/widgets/party_option_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/party_option_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders label and reflects isOn in the switch value',
      (tester) async {
    await tester.pumpWidget(wrap(PartyOptionCard(
      flatFeeIqd: 20000,
      isOn: false,
      onToggle: (_) {},
    )));
    expect(find.text('Having a Party?'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.pumpWidget(wrap(PartyOptionCard(
      flatFeeIqd: 20000,
      isOn: true,
      onToggle: (_) {},
    )));
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('shows the flat fee helper text when flatFeeIqd > 0',
      (tester) async {
    await tester.pumpWidget(wrap(PartyOptionCard(
      flatFeeIqd: 20000,
      isOn: true,
      onToggle: (_) {},
    )));
    expect(find.text('20,000 IQD Extra Guests Fee'), findsOneWidget);
  });

  testWidgets('hides the helper text when flatFeeIqd is 0', (tester) async {
    await tester.pumpWidget(wrap(PartyOptionCard(
      flatFeeIqd: 0,
      isOn: true,
      onToggle: (_) {},
    )));
    expect(find.text('20,000 IQD Extra Guests Fee'), findsNothing);
  });

  testWidgets('tapping the switch calls onToggle with the flipped value',
      (tester) async {
    bool? toggledTo;
    await tester.pumpWidget(wrap(PartyOptionCard(
      flatFeeIqd: 20000,
      isOn: false,
      onToggle: (v) => toggledTo = v,
    )));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(toggledTo, isTrue);
  });
}
```

Note: this test runs on the default (non-iOS) test platform, so `PartyOptionCard` renders a plain `Switch.adaptive` (a `Switch` subtype — `find.byType(Switch)` matches it), not `CNSwitch`. That's why the test doesn't need platform mocking.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/booking/presentation/widgets/party_option_card_test.dart`
Expected: FAIL — compile errors, since `PartyOptionCard` doesn't yet accept `flatFeeIqd`/`isOn`/`onToggle`-only construction (current constructor requires `includedPersons`, `guestCount`, etc.) and the "20,000 IQD Extra Guests Fee" text doesn't exist standalone.

- [ ] **Step 3: Rewrite the widget**

Replace the entire contents of `lib/features/booking/presentation/widgets/party_option_card.dart`:

```dart
import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

/// Toggle for the flat Extra Guests Fee, shown under the shift picker in
/// [FarmSection] when the selected shift has party pricing enabled.
/// Purely presentational — the caller owns all state. Guest-count
/// entry lives separately in [GuestCountCard].
class PartyOptionCard extends StatelessWidget {
  const PartyOptionCard({
    super.key,
    required this.flatFeeIqd,
    required this.isOn,
    required this.onToggle,
  });

  final int flatFeeIqd;
  final bool isOn;
  final ValueChanged<bool> onToggle;

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
      child: Row(
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
              color: isOn ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'لديك حفلة؟' : 'Having a Party?',
                  style: (tt.titleSmall ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOn ? cs.primary : cs.onSurface,
                  ),
                ),
                if (flatFeeIqd > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? '${_formatIqd(flatFeeIqd)} د.ع رسوم الضيوف الاضافيين'
                        : '${_formatIqd(flatFeeIqd)} IQD Extra Guests Fee',
                    style: (tt.bodySmall ?? const TextStyle())
                        .copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Platform.isIOS
              ? CNSwitch(value: isOn, onChanged: onToggle)
              : Switch.adaptive(
                  value: isOn,
                  onChanged: onToggle,
                  activeTrackColor: cs.primary,
                ),
        ],
      ),
    );
  }
}
```

Note: this mirrors `profile_content.dart:126-139` exactly — bare `import 'dart:io';` and `Platform.isIOS`, no `kIsWeb` guard. Flutter's web SDK ships a `dart:io` shim where `Platform.isIOS` is a hardcoded `false`, so this compiles and falls through to `Switch.adaptive` on web without special-casing — the existing codebase already relies on this.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/booking/presentation/widgets/party_option_card_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/widgets/party_option_card.dart test/features/booking/presentation/widgets/party_option_card_test.dart
git commit -m "refactor(booking): simplify PartyOptionCard to a bare toggle with native switch"
```

---

### Task 5: New `GuestCountCard` widget

**Files:**
- Create: `lib/features/booking/presentation/widgets/guest_count_card.dart`
- Create: `test/features/booking/presentation/widgets/guest_count_card_test.dart`

**Interfaces:**
- Produces: `GuestCountCard({Key? key, required int includedPersons, required int extraPersonFeeIqd, required int guestCount, required ValueChanged<int> onGuestCountChanged})` — consumed by `farm_section.dart` in Task 6.

- [ ] **Step 1: Write the failing test**

Create `test/features/booking/presentation/widgets/guest_count_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/guest_count_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the "how many people" label and the guest count',
      (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 10,
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('How many people are going?'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('No extra charge up to 10 guests'), findsOneWidget);
  });

  testWidgets('shows the overage fee once guestCount exceeds includedPersons',
      (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 12,
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('+10,000 IQD for 2 extra guest(s)'), findsOneWidget);
  });

  testWidgets('tapping + increments the count', (tester) async {
    int? changedTo;
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 12,
      onGuestCountChanged: (v) => changedTo = v,
    )));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(changedTo, 13);
  });

  testWidgets('minus button is disabled when guestCount is 1', (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 5,
      extraPersonFeeIqd: 5000,
      guestCount: 1,
      onGuestCountChanged: (_) {},
    )));
    final minusButton = tester.widget<InkWell>(find.ancestor(
      of: find.byIcon(Icons.remove_rounded),
      matching: find.byType(InkWell),
    ));
    expect(minusButton.onTap, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/booking/presentation/widgets/guest_count_card_test.dart`
Expected: FAIL with "Error: Couldn't resolve the package 'future_riverpod' ... guest_count_card.dart" (file doesn't exist yet)

- [ ] **Step 3: Write the widget**

Create `lib/features/booking/presentation/widgets/guest_count_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

/// Guest-count stepper shown under the shift picker in [FarmSection]
/// whenever the selected shift has party pricing configured — independent
/// of whether the flat-fee toggle in [PartyOptionCard] is on. Whenever the
/// count exceeds [includedPersons], the per-guest overage fee applies.
/// Purely presentational — the caller owns all state.
class GuestCountCard extends StatelessWidget {
  const GuestCountCard({
    super.key,
    required this.includedPersons,
    required this.extraPersonFeeIqd,
    required this.guestCount,
    required this.onGuestCountChanged,
  });

  final int includedPersons;
  final int extraPersonFeeIqd;
  final int guestCount;
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
    final String helperText = extraGuests <= 0
        ? (isAr
            ? 'بدون رسوم إضافية حتى $includedPersons ضيوف'
            : 'No extra charge up to $includedPersons guests')
        : (isAr
            ? '+${_formatIqd(extraTotal)} د.ع لـ $extraGuests ضيوف إضافيين'
            : '+${_formatIqd(extraTotal)} IQD for $extraGuests extra guest(s)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
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
              Expanded(
                child: Text(
                  isAr ? 'كم عدد الأشخاص القادمين؟' : 'How many people are going?',
                  style: (tt.bodyMedium ?? const TextStyle())
                      .copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
              ),
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
              color: extraGuests > 0 ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
              fontWeight: extraGuests > 0 ? FontWeight.w600 : FontWeight.w400,
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

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/booking/presentation/widgets/guest_count_card_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/widgets/guest_count_card.dart test/features/booking/presentation/widgets/guest_count_card_test.dart
git commit -m "feat(booking): add GuestCountCard, independent of the party toggle"
```

---

### Task 6: Wire both cards into `farm_section.dart`, fix spacing, split fee math

**Files:**
- Modify: `lib/features/booking/presentation/sections/farm_section.dart:64-76` (providers), `:322-330` (date-select reset), `:383-392` (shift-select reset), `:402-431` (card rendering), `:449-577` (summary + submit)

**Interfaces:**
- Consumes: `PartyOptionCard({flatFeeIqd, isOn, onToggle})` (Task 4), `GuestCountCard({includedPersons, extraPersonFeeIqd, guestCount, onGuestCountChanged})` (Task 5), `createFarmBooking({..., int? partySize, bool bringingParty})` (Task 3).

- [ ] **Step 1: Reset guest count on date change**

In the `BookingDateStrip.onSelect` callback (around line 322), change:

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

to:

```dart
            onSelect: (date) {
              ref.read(_farmSelectedDateProvider.notifier).set(date);
              ref.read(_farmSelectedShiftProvider.notifier).set(null);
              ref.read(_farmPartyOnProvider.notifier).set(false);
              ref.read(_farmPartyCountProvider.notifier).set(1);
              // Release any pending booking row server-side so the next
              // Proceed doesn't collide with it.
              ref.read(bookingSubmitProvider.notifier).cancelPending();
            },
```

- [ ] **Step 2: Reset guest count on shift change**

In the `ShiftCard.onTap` callback (around line 383), change:

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

to:

```dart
                        onTap: () {
                          ref
                              .read(_farmSelectedShiftProvider.notifier)
                              .set(isSelected ? null : shift);
                          ref.read(_farmPartyOnProvider.notifier).set(false);
                          ref.read(_farmPartyCountProvider.notifier).set(1);
                          // Release any pending booking row server-side.
                          ref
                              .read(bookingSubmitProvider.notifier)
                              .cancelPending();
                        },
```

- [ ] **Step 3: Replace the single party card block with two cards + a trailing gap**

Replace (around lines 402-431):

```dart
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
```

with:

```dart
          // ── Party toggle + guest counter (independent of each other) ─────
          if (selectedShift != null && selectedShift.partyEnabled) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PartyOptionCard(
                flatFeeIqd: selectedShift.partyFlatFeeIqd,
                isOn: partyOn,
                onToggle: (v) {
                  ref.read(_farmPartyOnProvider.notifier).set(v);
                  // A previously-created pending booking (from an earlier
                  // Proceed tap) was priced without this change — release it
                  // so the next Proceed creates a fresh, correctly-priced one.
                  ref.read(bookingSubmitProvider.notifier).cancelPending();
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GuestCountCard(
                includedPersons: selectedShift.partyIncludedPersons,
                extraPersonFeeIqd: selectedShift.partyExtraPersonFeeIqd,
                guestCount: partyCount,
                onGuestCountChanged: (v) {
                  ref.read(_farmPartyCountProvider.notifier).set(v);
                  ref.read(bookingSubmitProvider.notifier).cancelPending();
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
```

The trailing `const SizedBox(height: 16)` is the fix for the reported collision — the original block had no spacing before the `AnimatedSwitcher` summary card that follows.

- [ ] **Step 4: Update the import**

Add the new widget import near the existing `party_option_card.dart` import (around line 10):

```dart
import 'package:future_riverpod/features/booking/presentation/widgets/guest_count_card.dart';
```

- [ ] **Step 5: Split the fee computation in the summary `Builder`**

Replace (around line 453):

```dart
                      final partyFee = partyOn
                          ? selectedShift.partyFlatFeeIqd +
                              (partyCount - selectedShift.partyIncludedPersons)
                                      .clamp(0, 1 << 30) *
                                  selectedShift.partyExtraPersonFeeIqd
                          : 0;
                      final subtotal = selectedShift.priceIqd + partyFee;
```

with:

```dart
                      final extraGuests = (partyCount -
                              selectedShift.partyIncludedPersons)
                          .clamp(0, 1 << 30);
                      final partyFee =
                          (partyOn ? selectedShift.partyFlatFeeIqd : 0) +
                              extraGuests * selectedShift.partyExtraPersonFeeIqd;
                      final subtotal = selectedShift.priceIqd + partyFee;
```

- [ ] **Step 6: Split the summary row conditions**

Replace (around lines 499-517):

```dart
                            if (partyOn && selectedShift.partyFlatFeeIqd > 0)
                              BookingSummaryRow(
                                icon: Icons.groups_rounded,
                                label: isAr ? 'رسوم الضيوف الاضافيين' : 'Extra Guests Fee',
                                value: _FarmBookingFormView._formatIqd(
                                    selectedShift.partyFlatFeeIqd),
                              ),
                            if (partyOn &&
                                partyCount >
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
```

with:

```dart
                            if (partyOn && selectedShift.partyFlatFeeIqd > 0)
                              BookingSummaryRow(
                                icon: Icons.groups_rounded,
                                label: isAr ? 'رسوم الضيوف الاضافيين' : 'Extra Guests Fee',
                                value: _FarmBookingFormView._formatIqd(
                                    selectedShift.partyFlatFeeIqd),
                              ),
                            if (extraGuests > 0)
                              BookingSummaryRow(
                                icon: Icons.person_add_alt_1_rounded,
                                label: isAr ? 'ضيوف إضافيون' : 'Extra guests',
                                value: _FarmBookingFormView._formatIqd(
                                  extraGuests *
                                      selectedShift.partyExtraPersonFeeIqd,
                                ),
                              ),
```

- [ ] **Step 7: Update the submit call**

Replace (around line 567):

```dart
                                    .createFarmBooking(
                                      placeId: placeId,
                                      date: bookingFormatDate(selectedDate),
                                      shiftType: shift.shiftType,
                                      promoCode: promo?.code,
                                      partySize: partyOn ? partyCount : null,
                                    );
```

with:

```dart
                                    .createFarmBooking(
                                      placeId: placeId,
                                      date: bookingFormatDate(selectedDate),
                                      shiftType: shift.shiftType,
                                      promoCode: promo?.code,
                                      partySize:
                                          shift.partyEnabled ? partyCount : null,
                                      bringingParty: partyOn,
                                    );
```

- [ ] **Step 8: Run static analysis**

Run: `flutter analyze lib/features/booking/presentation/sections/farm_section.dart`
Expected: `No issues found!`

- [ ] **Step 9: Run the full booking test suite**

Run: `flutter test test/features/booking/`
Expected: PASS — all tests, including the Task 4/5 widget tests, pass with no regressions in unrelated booking tests (restaurant, discounts, etc. in the same directory).

- [ ] **Step 10: Commit**

```bash
git add lib/features/booking/presentation/sections/farm_section.dart
git commit -m "feat(booking): wire independent party toggle and guest counter into farm flow"
```

---

### Task 7: Manual end-to-end verification on iOS simulator

**Files:** none (verification only)

**Interfaces:**
- Consumes: everything from Tasks 1-6.

- [ ] **Step 1: Launch the app on the iOS simulator**

Run: `flutter run -d "iPhone 17 Pro Max"`

Wait for the app to build and land on the home screen. `CNSwitch` only renders its native form on iOS — this is the only device in `flutter devices` that exercises Task 4's actual switch styling (Chrome/web and macOS desktop fall back to `Switch.adaptive`).

- [ ] **Step 2: Navigate to a farm place with party pricing configured**

Use a place/shift already known to have `party_enabled = true` (per the Testing Notes in the design spec — e.g. the shift used when the original party-pricing feature was verified live). Open its booking screen and select that shift.

- [ ] **Step 3: Verify the toggle renders the native glass switch**

Confirm the "Having a Party?" switch visually matches the language toggle in Settings (Profile → Language) — same frosted/native look, not the flat Material `Switch.adaptive` track.

- [ ] **Step 4: Verify the two cards and spacing**

Confirm: `PartyOptionCard` and `GuestCountCard` render as two visually distinct containers with a gap between them, and there's a visible gap between the guest counter and the "Booking Summary" card below it — no collision/overlap (the originally reported bug).

- [ ] **Step 5: Verify toggle/counter independence**

- With the toggle **off**, raise the guest count above the included limit → confirm the summary shows only an "Extra guests" row (no "Extra Guests Fee" row), and the total reflects the overage.
- Turn the toggle **on** with the guest count still at its default (1, under the limit) → confirm the summary shows only a "Extra Guests Fee" row (no "Extra guests" row).
- With both the toggle on and the guest count above the limit → confirm both rows appear and the total is the sum of both.

- [ ] **Step 6: Complete one booking through to payment**

Tap "Proceed to Payment" with both the toggle on and guests over the limit, and confirm the Wayl payment webview opens with the combined amount (base + flat fee + overage) — confirming the RPC-side fee split from Task 1 matches what the client displayed.

- [ ] **Step 7: Report results**

Summarize pass/fail for each of Steps 3-6 back to the user before considering the feature complete. If any step fails, treat it as a bug against the relevant task above rather than a new task.
