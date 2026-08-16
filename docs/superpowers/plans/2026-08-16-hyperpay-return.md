# HyperPay Return Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore HyperPay as the Wensa app's sole e-payment gateway, replacing Wayl at the checkout surface, without altering the cash-payment or inline-payment-selector features that shipped after the freeze.

**Architecture:** The frozen HyperPay integration is restored verbatim from `d03394f^` (the parent of the commit that removed it) — a self-contained Flutter feature folder plus vendored native SDKs. Only the seam changes: `BookingSubmitState.success` carries a `checkoutId`/`paymentMode` pair instead of a Wayl `paymentUrl`, and each booking flow calls `launchHyperpayPayment` instead of pushing a webview. The cash branch is untouched throughout. Backend `create-booking`/`create-membership` swap Wayl link creation for a HyperPay checkout; `verify-payment` returns to confirm payments server-side.

**Tech Stack:** Flutter 3.10+ / Dart, Riverpod + freezed, go_router, Supabase Edge Functions (Deno/TypeScript), Postgres, HyperPay OPPWA COPYandPAY mSDK (iOS xcframeworks, Android AARs).

**Spec:** `docs/superpowers/specs/2026-08-16-hyperpay-return-design.md`

## Global Constraints

- **Branch:** `feature/hyperpay-return`. Do not merge to `main`; the user deploys and runs the on-device E2E first.
- **Restore source:** `d03394f^` (`300de49`). Byte-identical to tag `hyperpay-v1` for every path restored here — either works, `d03394f^` reads as the direct inverse of the removal.
- **Never change the value sent to the gateway** without flagging it for UAT. `merchantTransactionId` stays `` `booking-{uuid}`/`booking-venue-{group_id}` `` pre-capped with `.slice(0, 32)` at the call site. Dashes only, no underscores, ≤32 chars. The acquirer answers `800.100.156 "format error"` to any deviation.
- **IQD is a 0-decimal currency.** Always `Math.round(amount)`, never `.toFixed(2)`.
- **Never send `customer.*` or `billing.*` blocks** in a checkout body.
- **Do not delete `supabase/functions/_shared/wayl.ts`.** Historical Wayl bookings still need their refund path (Task 13).
- **Do not touch** `wansa-admin-dashboard`, `get-transactions`, the cash branches, the free-booking path, the `client: "dashboard"` hint gate, or any promo/discount/commission logic.
- **Do not unify** the two repos' `merchantTransactionId` capping mechanisms. Both are load-bearing where they sit — see spec §4b.
- `payment_method` wire values: `'cash' | 'hyperpay'` sent by the app; `'wayl'` is historical-only and must never be sent for a new booking.

---

### Task 1: Widen the `payment_method` CHECK constraint

**Files:**
- Create: `supabase/migrations/20260816000001_hyperpay_payment_method.sql`

**Interfaces:**
- Consumes: nothing.
- Produces: `bookings.bookings.payment_method` and `bookings.memberships.payment_method` accept `'hyperpay'`. Tasks 11, 12 write that value.

- [ ] **Step 1: Write the migration**

The constraints created by `20260810080512_add_cash_payment_method.sql` were anonymous, so Postgres auto-named them `bookings_payment_method_check` and `memberships_payment_method_check`.

```sql
-- Widen payment_method to admit HyperPay alongside the historical Wayl value.
-- 'wayl' is retained, never written for new rows: it records which PSP actually
-- took the money for every booking made between 2026-07-31 and this migration.

ALTER TABLE bookings.bookings
  DROP CONSTRAINT IF EXISTS bookings_payment_method_check;
ALTER TABLE bookings.bookings
  ADD CONSTRAINT bookings_payment_method_check
    CHECK (payment_method IN ('wayl', 'cash', 'hyperpay'));

ALTER TABLE bookings.memberships
  DROP CONSTRAINT IF EXISTS memberships_payment_method_check;
ALTER TABLE bookings.memberships
  ADD CONSTRAINT memberships_payment_method_check
    CHECK (payment_method IN ('wayl', 'cash', 'hyperpay'));
```

- [ ] **Step 2: Verify the constraint names match reality**

Run against the project and confirm both rows come back before applying:

```bash
psql "$DATABASE_URL" -c "
SELECT conrelid::regclass AS tbl, conname
FROM pg_constraint
WHERE conname IN ('bookings_payment_method_check','memberships_payment_method_check');"
```

Expected: two rows. If a name differs, correct the migration to the real name — `DROP CONSTRAINT IF EXISTS` on a wrong name silently no-ops and leaves the old constraint in force, which would reject `'hyperpay'` at runtime.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260816000001_hyperpay_payment_method.sql
git commit -m "feat(db): admit 'hyperpay' as a payment_method value"
```

---

### Task 2: Add `hyperpay` to the Dart `PaymentMethod` enum

**Files:**
- Modify: `lib/features/booking/domain/models/booking_enums.dart:3` and `:95-106`
- Modify: `lib/features/booking/presentation/widgets/payment_method_selector.dart:70-80`
- Test: `test/features/booking/presentation/widgets/payment_method_selector_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `PaymentMethod.hyperpay`, serialised as `'hyperpay'` via `.name`. Tasks 6 and 9 send it.

- [ ] **Step 1: Write the failing test**

Add to `test/features/booking/presentation/widgets/payment_method_selector_test.dart`:

```dart
test('hyperpay round-trips through fromString and .name', () {
  expect(PaymentMethodFromString.fromString('hyperpay'), PaymentMethod.hyperpay);
  expect(PaymentMethod.hyperpay.name, 'hyperpay');
});

test('unknown payment_method never resolves to cash', () {
  // Cash means "no money collected yet". Reading an unknown value as cash
  // would mark an unpaid booking as awaiting cash at the venue.
  expect(PaymentMethodFromString.fromString('martian-pay'), isNot(PaymentMethod.cash));
});
```

- [ ] **Step 2: Run it and watch it fail**

```bash
flutter test test/features/booking/presentation/widgets/payment_method_selector_test.dart
```

Expected: FAIL — `PaymentMethod.hyperpay` is not defined.

- [ ] **Step 3: Add the enum case and mapping**

In `booking_enums.dart`, line 3:

```dart
enum PaymentMethod { wayl, cash, hyperpay }
```

And in the `PaymentMethodFromString` extension:

```dart
extension PaymentMethodFromString on PaymentMethod {
  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'hyperpay':
        return PaymentMethod.hyperpay;
      case 'wayl':
        return PaymentMethod.wayl;
      default:
        // Historical rows and unknown future values read as `wayl`, which
        // renders as "E-Payment". Never default to `cash` — see test above.
        return PaymentMethod.wayl;
    }
  }
}
```

- [ ] **Step 4: Point the selector's E-Payment row at hyperpay**

In `payment_method_selector.dart`, the non-cash `_SelectorRow` currently uses `PaymentMethod.wayl` for both `isSelected` and `onTap`. Change both occurrences:

```dart
isSelected: selected == PaymentMethod.hyperpay,
onTap: () => onChanged(PaymentMethod.hyperpay),
```

Leave the icon, copy, and layout alone.

- [ ] **Step 5: Run the full selector suite**

```bash
flutter test test/features/booking/presentation/widgets/payment_method_selector_test.dart
```

Expected: PASS, including the pre-existing 124 lines of tests. If an existing test asserts `PaymentMethod.wayl` selection, update it to `hyperpay` — that is the intended behaviour change, not a regression.

- [ ] **Step 6: Commit**

```bash
git add lib/features/booking/domain/models/booking_enums.dart \
        lib/features/booking/presentation/widgets/payment_method_selector.dart \
        test/features/booking/presentation/widgets/payment_method_selector_test.dart
git commit -m "feat(booking): add PaymentMethod.hyperpay, selector emits it for E-Payment"
```

---

### Task 3: Restore the `hyperpay_payment` Flutter feature folder

**Files:**
- Restore: `lib/features/hyperpay_payment/**` (25 files)
- Restore: `test/features/hyperpay_payment/**` (5 files)

**Interfaces:**
- Consumes: nothing.
- Produces: the `hyperpay_payment.dart` barrel exporting `launchHyperpayPayment(BuildContext, {required String checkoutId, required String referenceId, required String entityKind, required String entityId, required String paymentMode, required Future<VoidCallback?> Function(String orderId) onConfirmed, required Future<void> Function(PaymentAbort reason) onAborted, String cancelledMessage})`, plus `SavedCardsPage`, `HyperpayVerifyService`, `PaymentAbort`. Tasks 4, 6 consume these.

- [ ] **Step 1: Restore both trees from history**

```bash
git checkout d03394f^ -- lib/features/hyperpay_payment test/features/hyperpay_payment
```

- [ ] **Step 2: Confirm the file counts**

```bash
find lib/features/hyperpay_payment -name '*.dart' | wc -l   # expect 25
find test/features/hyperpay_payment -name '*.dart' | wc -l  # expect 5
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/hyperpay_payment
```

Expected: clean. The folder was built to depend on nothing but Flutter and itself, so it should restore without touching anything else. If it reports missing imports, STOP and report — that means something it depended on was deleted separately and the spec's portability assumption is wrong.

- [ ] **Step 4: Commit**

```bash
git add lib/features/hyperpay_payment test/features/hyperpay_payment
git commit -m "feat(payments): restore hyperpay_payment feature folder from d03394f^"
```

---

### Task 4: Restore the `/saved-cards` route and profile entry

**Files:**
- Modify: `lib/core/router/router_names.dart`
- Modify: `lib/core/router/router_provider.dart`
- Modify: `lib/features/profile/presentation/widgets/profile_content.dart`

**Interfaces:**
- Consumes: `SavedCardsPage` from Task 3's barrel.
- Produces: `RouteNames.savedCards` (`'saved-cards'`), route `/saved-cards`.

- [ ] **Step 1: Restore all three files from history**

The removal was a clean 3-hunk diff across these files; restoring them wholesale is safe only if nothing else changed them since. Verify first:

```bash
git log --oneline d03394f..HEAD -- lib/core/router/router_names.dart \
    lib/core/router/router_provider.dart \
    lib/features/profile/presentation/widgets/profile_content.dart
```

If that prints nothing, restore wholesale:

```bash
git checkout d03394f^ -- lib/core/router/router_names.dart \
    lib/core/router/router_provider.dart \
    lib/features/profile/presentation/widgets/profile_content.dart
```

If it prints commits, do NOT restore wholesale — re-apply the three hunks by hand instead:
1. `router_names.dart`: add `static const savedCards = 'saved-cards';`
2. `router_provider.dart`: add the import `package:future_riverpod/features/hyperpay_payment/hyperpay_payment.dart`, the `GoRoute(path: '/saved-cards', name: RouteNames.savedCards, builder: (_, s) => SavedCardsPage(isAr: s.extra as bool? ?? false))`, and `'/saved-cards'` in the `_redirect` allow-list.
3. `profile_content.dart`: restore the Payment `SectionLabel` + `SettingsCard` row with `Icons.credit_card_rounded`, title `'البطاقات المحفوظة'` / `'Saved Cards'`, navigating to `RouteNames.savedCards`.

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/core/router lib/features/profile
```

Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/core/router lib/features/profile
git commit -m "feat(payments): restore /saved-cards route and profile entry"
```

---

### Task 5: Restore the native iOS and Android HyperPay SDKs

**Files:**
- Restore (iOS): `ios/HyperpaySDK/**` (544 files), `ios/Runner/SceneDelegate.swift`, `ios/Podfile`, `ios/Podfile.lock`
- Restore (Android): `android/app/libs/*.aar`, `android/app/src/main/kotlin/app/wensa/mobile/MainActivity.kt`, `android/app/src/main/res/layout/async_payment_activity.xml`, `android/app/src/main/res/values/{strings,colors,styles}.xml`, `android/app/src/main/res/values-ar/strings.xml`, `android/app/build.gradle.kts`, `android/app/proguard-rules.pro`, `android/app/src/main/AndroidManifest.xml`
- Possibly modify: `ios/Runner/AppDelegate.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: the `hyperpay` method channel that `hyperpay_channel.dart` (Task 3) talks to.

- [ ] **Step 1: Restore Android wholesale**

Only `d03394f` has touched `android/` since the freeze, so a wholesale restore is exactly correct:

```bash
git checkout d03394f^ -- android/
git status --short android/
```

- [ ] **Step 2: Restore iOS, excluding AppDelegate**

`ios/` has two post-freeze commits (`98534c2`, `adf83d6`) that both landed in `AppDelegate.swift`. Restore everything else:

```bash
git checkout d03394f^ -- ios/HyperpaySDK ios/Runner/SceneDelegate.swift ios/Podfile ios/Podfile.lock
```

Do NOT `git checkout d03394f^ -- ios/` — that would revert the WKWebView toolbar fixes in `AppDelegate.swift`.

- [ ] **Step 3: Decide the fate of the WKWebView swizzle**

Those 45 lines in `AppDelegate.swift` exist only to hide WKWebView's form-navigation toolbar, which existed for the Wayl webview being deleted in Task 7. Check whether any WKWebView survives:

```bash
grep -rn "WKWebView\|webview_flutter\|InAppWebView" lib/ ios/Runner/ | grep -v Binary
grep -n "webview" pubspec.yaml
```

If there are no remaining WKWebView users, delete the swizzle from `AppDelegate.swift` and note it in the commit message. If any survive (including a transitive package dependency), keep it untouched. When in doubt, keep it — the swizzle is inert when no WKWebView is instantiated.

- [ ] **Step 4: Verify SceneDelegate and AppDelegate coexist**

With a `SceneDelegate.swift` present, UIKit switches to the scene lifecycle. Confirm `ios/Runner/Info.plist` carries the `UIApplicationSceneManifest` key that the restored `SceneDelegate` expects:

```bash
grep -A5 UIApplicationSceneManifest ios/Runner/Info.plist
```

If the key is absent, restore it: `git checkout d03394f^ -- ios/Runner/Info.plist` — but diff first (`git diff d03394f^ HEAD -- ios/Runner/Info.plist`) and hand-merge if it has post-freeze changes.

- [ ] **Step 5: Install pods and build iOS**

```bash
cd ios && pod install && cd ..
flutter build ios --debug --no-codesign
```

Expected: build succeeds. The SDK is vendored, so no network resolution is involved. If it fails on a missing xcframework, confirm Step 2 restored all 544 files (`find ios/HyperpaySDK -type f | wc -l`).

- [ ] **Step 6: Build Android**

```bash
flutter build apk --debug
```

Expected: build succeeds. If it fails on minSdk, confirm `android/app/build.gradle.kts` carries the minSdk 24 floor from the restore.

- [ ] **Step 7: Commit**

```bash
git add ios android
git commit -m "feat(payments): restore HyperPay native SDKs and method channel wiring"
```

---

### Task 6: Cut the app over from Wayl webview to HyperPay sheet

This is the atomic cutover. The state shape and every consumer change together, because renaming a positional freezed field breaks compilation until all call sites move.

**Files:**
- Modify: `lib/features/booking/presentation/providers/booking_submit_provider.dart`
- Modify: `lib/features/booking/presentation/providers/membership_submit_provider.dart`
- Modify: `lib/features/booking/presentation/sections/padel_section.dart`
- Modify: `lib/features/booking/presentation/sections/farm_section.dart`
- Modify: `lib/features/booking/presentation/sections/concert_section.dart`
- Modify: `lib/features/booking/presentation/sections/membership_section.dart`
- Modify: `lib/features/booking/presentation/sections/restaurant_section.dart:100` (arity only)

**Interfaces:**
- Consumes: `launchHyperpayPayment`, `PaymentAbort` (Task 3); `PaymentMethod.hyperpay` (Task 2).
- Produces: `BookingSubmitState.success({bookingId, checkoutId, holdUntil, referenceId, paymentMode, cash})`.

- [ ] **Step 1: Change the state shape**

In `booking_submit_provider.dart`:

```dart
@freezed
abstract class BookingSubmitState with _$BookingSubmitState {
  const factory BookingSubmitState.idle() = _Idle;
  const factory BookingSubmitState.loading() = _Loading;
  const factory BookingSubmitState.success({
    required String bookingId,
    // HyperPay checkout session id — the native mSDK submits the card against
    // this. Empty when the booking was confirmed by cash.
    required String checkoutId,
    required String holdUntil,
    // Our own reference (booking_{uuid}_{ts}), persisted as bookings.payment_id.
    // NOT the merchantTransactionId sent to the gateway.
    required String referenceId,
    // "LIVE" | "TEST" — selects the mSDK's environment.
    @Default('TEST') String paymentMode,
    // True when the booking was confirmed via cash (no checkout exists).
    @Default(false) bool cash,
  }) = _Success;
  const factory BookingSubmitState.error(String message) = _Error;
}
```

Keep `_friendlyErrorMessage` exactly as-is — the `cash_disabled` message still applies.

- [ ] **Step 2: Update all five create* methods**

In each of `createPadelBooking`, `createFarmBooking`, `createRestaurantBooking`, `createGeneralAdmissionBooking`, `createConcertBooking`, replace the success construction. The pattern, using `createPadelBooking` as the model:

```dart
state = BookingSubmitState.success(
  bookingId: data['booking_id'] as String,
  checkoutId: data['checkout_id'] as String? ?? '',
  holdUntil: data['hold_until'] as String? ?? '',
  referenceId: data['reference_id'] as String? ?? '',
  paymentMode: data['payment_mode'] as String? ?? 'TEST',
  cash: data['cash'] == true,
);
```

Per-method deviations to preserve:
- `createRestaurantBooking` passes `holdUntil: ''` and has no `cash` argument — keep both.
- `createGeneralAdmissionBooking` and `createConcertBooking` use the `(data['x'] ?? '') as String` form — keep it.
- `createConcertBooking` maps `bookingId: (data['group_id'] ?? data['booking_id'] ?? '') as String` — keep it.
- Delete the stale doc comment on `createGeneralAdmissionBooking` that says "returns a Wayl payment URL. The webhook flips the row to confirmed"; replace with "returns a HyperPay checkout id. verify-payment flips the row to confirmed."

- [ ] **Step 3: Fix the two `maybeWhen` destructures in the provider**

`cancelPending` (line ~247) uses `success: (id, _, _, _, _) => id` — five positional params. The success factory now has six. Update both `booking_submit_provider.dart` and `membership_submit_provider.dart`:

```dart
success: (id, _, _, _, _, _) => id,
```

- [ ] **Step 4: Update `membership_submit_provider.dart`**

```dart
state = BookingSubmitState.success(
  bookingId: data['membership_id'] as String,
  checkoutId: data['checkout_id'] as String? ?? '',
  holdUntil: '',
  referenceId: data['reference_id'] as String? ?? '',
  paymentMode: data['payment_mode'] as String? ?? 'TEST',
  cash: data['cash'] == true,
);
```

- [ ] **Step 5: Regenerate freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Swap the padel section**

In `padel_section.dart`, replace the whole `openPaymentWebView` function (lines ~280-333) with:

```dart
    // Opens the HyperPay card sheet for the given booking details.
    // Defined here so it can be reused by both ref.listen and onAction.
    void openCardPayment(
      String bookingId,
      String checkoutId,
      String referenceId,
      String paymentMode,
    ) {
      launchHyperpayPayment(
        context,
        checkoutId: checkoutId,
        referenceId: referenceId,
        entityKind: 'booking',
        entityId: bookingId,
        paymentMode: paymentMode,
        onConfirmed: (orderId) async {
          try {
            await ref
                .read(bookingRepositoryProvider)
                .confirmPayment(bookingId, orderId);
          } catch (_) {}
          ref.read(bookingSubmitProvider.notifier).reset();
          ref.read(bookingsRefreshProvider.notifier).bump();
          ref.invalidate(userPurchaseHistoryProvider);
          return () => context.go('/bookings/$bookingId');
        },
        onAborted: (_) async {
          // Release the pending row server-side the moment the payment ends
          // without success, so the slot frees up immediately instead of
          // waiting on the expiry cron.
          await ref.read(bookingSubmitProvider.notifier).cancelPending();
          if (selectedCourt != null) {
            ref.invalidate(
              availableSlotsProvider(
                courtId: selectedCourt.id,
                date: bookingFormatDate(selectedDate),
              ),
            );
          }
        },
      );
    }
```

Then update the `ref.listen` block (line ~335) — note the cash branch is preserved verbatim:

```dart
        success: (bookingId, checkoutId, holdUntil, referenceId, paymentMode, cash) {
          if (checkoutId.isNotEmpty) {
            openCardPayment(bookingId, checkoutId, referenceId, paymentMode);
          } else if (cash) {
            goToCashBookingSuccess(
              context: context,
              ref: ref,
              routeId: bookingId,
              resetSubmitState: ref.read(bookingSubmitProvider.notifier).reset,
            );
          } else {
            ref.read(bookingSubmitProvider.notifier).reset();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Unable to start payment. Please try again.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
```

Update the `hasPendingToResume` guard at line ~259:

```dart
    final hasPendingToResume = submitState.maybeWhen(
      success: (_, checkoutId, _, _, _, cash) => checkoutId.isNotEmpty || cash,
      orElse: () => false,
    );
```

And the second call site at line ~657 inside `onAction` — same rename, `paymentUrl` → `checkoutId`, calling `openCardPayment(bookingId, checkoutId, referenceId, paymentMode)`.

Fix imports: remove `payment_webview_page.dart`, add `package:future_riverpod/features/hyperpay_payment/hyperpay_payment.dart`. Send `PaymentMethod.hyperpay` wherever the section passed `PaymentMethod.wayl`.

- [ ] **Step 7: Swap the farm section**

`farm_section.dart` has the identical structure — a local `openPaymentWebView` at ~280, a `ref.listen` at ~332, and a second call site at ~703. Apply the same transformation as Step 6, with the farm section's own invalidation targets in `onAborted` (whatever provider it currently invalidates in `onPaymentFailed`), and `entityKind: 'booking'`.

- [ ] **Step 8: Swap the concert section (seat + GA)**

`concert_section.dart` pushes `PaymentWebViewPage` at module level (~line 69) rather than through a local helper. Replace that push with `launchHyperpayPayment` using **`entityKind: 'concert_group'`** — concerts confirm by group, not by booking id, and `bookingId` here already holds the `group_id` (see `createConcertBooking`). In `onAborted`, call `cancelConcertGroup(groupId)` rather than `cancelPending()`, matching the existing failure path. Update both the seat flow and the GA flow, and both of their `success:` destructures to six positional params.

- [ ] **Step 9: Swap the membership section**

`membership_section.dart` pushes at module level (~line 95). Replace with `launchHyperpayPayment` using **`entityKind: 'membership'`**. The cash branch routes to `goToCashBookingSuccess` with `routeId: 'm_$membershipId'` — preserve that prefix exactly; it is the id shape `/bookings/:id` expects for memberships.

- [ ] **Step 10: Fix the restaurant section's arity**

`restaurant_section.dart:100` only destructures; no behaviour changes:

```dart
      success: (bookingId, checkoutId, holdUntil, referenceId, paymentMode, cash) =>
          const _RestaurantPendingView(),
```

- [ ] **Step 11: Analyze**

```bash
flutter analyze lib/
```

Expected: clean, and zero references to `paymentUrl`/`waylReferenceId` remain:

```bash
grep -rn "paymentUrl\|waylReferenceId\|PaymentWebViewPage" lib/ | grep -v '\.freezed\.\|\.g\.dart'
```

Expected: no output.

- [ ] **Step 12: Run the test suite**

```bash
flutter test
```

Expected: PASS. Update any test that constructs `BookingSubmitState.success` to the new signature.

- [ ] **Step 13: Commit**

```bash
git add lib/features/booking test/
git commit -m "feat(payments): route every booking flow through HyperPay instead of Wayl"
```

---

### Task 7: Delete the Wayl payment surface from the app

**Files:**
- Delete: `lib/features/wayl_payment/**` (6 files)
- Delete: `lib/features/booking/presentation/pages/payment_webview_page.dart`

**Interfaces:**
- Consumes: nothing. Task 6 removed the last references.
- Produces: nothing.

- [ ] **Step 1: Confirm nothing still imports them**

```bash
grep -rn "wayl_payment\|payment_webview_page" lib/ test/
```

Expected: no output. If anything remains, finish Task 6 first.

- [ ] **Step 2: Delete**

```bash
git rm -r lib/features/wayl_payment
git rm lib/features/booking/presentation/pages/payment_webview_page.dart
```

- [ ] **Step 3: Analyze and test**

```bash
flutter analyze lib/ && flutter test
```

Expected: both clean.

Note: `waylCode`/`wayl_code` fields on `Booking`/`Membership` models are NOT deleted — they carry data for historical tickets.

- [ ] **Step 4: Commit**

```bash
git commit -m "refactor(payments): remove the Wayl webview surface from the app"
```

---

### Task 8: Restore the shared HyperPay edge-function modules

**Files:**
- Restore: `supabase/functions/_shared/hyperpay.ts`, `_shared/hyperpay_test.ts`, `_shared/payment_flow.ts`, `_shared/payments.ts`

**Interfaces:**
- Consumes: nothing.
- Produces: `cfg()`, `createCheckout(opts, cfg)`, `normalizeEnv()`, `isPaid`, `markPaymentFailed`, `setCardScope`, `rowEntityId`. Tasks 9-13 consume these.

- [ ] **Step 1: Restore from this repo's history**

Restore from `d03394f^`, NOT from the admin repo — they are not mirrors. The wensa copies are a superset (`isPaid`/`markPaymentFailed`/`setCardScope`) and use `normalizeEnv()` where the admin copy does a bare cast.

```bash
git checkout d03394f^ -- supabase/functions/_shared/hyperpay.ts \
    supabase/functions/_shared/hyperpay_test.ts \
    supabase/functions/_shared/payment_flow.ts \
    supabase/functions/_shared/payments.ts
```

- [ ] **Step 2: Port `reversePayment` for Task 13**

The wensa copy never had RV (reverse/void); Task 13's HyperPay refund branch needs it. Cherry-pick just that block from the preserved branch:

```bash
git show wip/hyperpay-dashboard-inflight-c1:supabase/functions/_shared/hyperpay.ts | tail -35
```

Append `buildReverseParams()` and `reversePayment()` to `_shared/hyperpay.ts`. Take ONLY those two functions — that branch also contains dual-gateway changes that are dead per this design.

- [ ] **Step 3: Type-check and test**

```bash
deno check supabase/functions/_shared/hyperpay.ts
deno test supabase/functions/_shared/hyperpay_test.ts
```

Expected: check clean, all tests pass.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/_shared
git commit -m "feat(payments): restore shared HyperPay edge modules, port RV reverse"
```

---

### Task 9: Restore `verify-payment`

This is the largest single gap. Without it the card is charged and the booking never confirms.

**Files:**
- Restore: `supabase/functions/verify-payment/index.ts`

**Interfaces:**
- Consumes: `_shared/hyperpay.ts`, `_shared/payments.ts` (Task 8).
- Produces: `POST verify-payment {checkout_id, kind, id, reference_id, save_card?}` → `{paid, description?, merchant_transaction_id?}`. Task 3's `HyperpayVerifyService` already calls exactly this shape.

- [ ] **Step 1: Restore from history**

```bash
git checkout d03394f^ -- supabase/functions/verify-payment
```

- [ ] **Step 2: Confirm the security guard survived**

The `rowEntityId()` guard closed an exploitable hole: `verify-payment` used to look up the persisted payment row by `checkout_id` alone and check only `user_id`, never that the row's entity id matched the `id` being confirmed. One real payment could confirm unlimited later bookings for free, repeatably.

```bash
grep -n "rowEntityId" supabase/functions/verify-payment/index.ts
```

Expected: at least one hit, returning 403 on mismatch. If absent, STOP — do not deploy.

- [ ] **Step 3: Confirm the save-card coupling survived**

```bash
grep -n "save_card\|registrationId\|user_payment_tokens" supabase/functions/verify-payment/index.ts
```

Expected: the `body.save_card === true && statusJson.registrationId` branch writing `user_payment_tokens`. This is the coupling point for Task 12's one-tap flow — if it is missing, saving a card silently no-ops.

- [ ] **Step 4: Type-check**

```bash
deno check supabase/functions/verify-payment/index.ts
```

- [ ] **Step 5: Optionally diff against what is deployed**

The deployed function is still ACTIVE at v19 and is a second source of truth:

```bash
supabase functions download verify-payment --project-ref qvozjwlkzordudkhamcu
```

Diff against the restored file. Differences are informational — history is authoritative for this restore — but a large divergence is worth reporting before proceeding.

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/verify-payment
git commit -m "feat(payments): restore verify-payment with the rowEntityId guard"
```

---

### Task 10: Restore `charge-saved-card` and close the double-charge hole

**Files:**
- Restore then modify: `supabase/functions/charge-saved-card/index.ts`

**Interfaces:**
- Consumes: `_shared/hyperpay.ts` (Task 8), `bookings.lock_for_payment` RPC (already applied).
- Produces: `POST charge-saved-card` one-tap MIT charge.

- [ ] **Step 1: Restore from history**

`d03394f^`'s copy was independently confirmed byte-identical to the deployed v17, so history is trustworthy here.

```bash
git checkout d03394f^ -- supabase/functions/charge-saved-card
```

- [ ] **Step 2: Locate the bug**

```bash
grep -n "merchantTransactionId\|mit-\|randomUUID" supabase/functions/charge-saved-card/index.ts
```

The value is `mit-` + 28 random uuid-hex chars, randomised per call. Because it differs every time, the DB unique index cannot dedupe, so two fast taps produce two independent charges on a real card. There is also a `TODO(payments)` comment marking this.

- [ ] **Step 3: Make the id deterministic per entity**

Derive it from the entity being paid for, so concurrent calls collide on the unique index and the second is rejected before money moves. Must stay ≤32 chars, dashes only, no underscores:

```ts
// Deterministic per entity so the DB unique index dedupes concurrent one-tap
// calls. A random id per call (the old behaviour) defeated that index and let
// two fast taps charge the card twice. Dashes only, <=32 chars — the acquirer
// rejects any deviation with 800.100.156.
const merchantTxnId = `mit-${kind === "membership" ? "m" : "b"}-${
  String(entityId).replace(/-/g, "")
}`.slice(0, 32);
```

**Use the file's own variable names.** `kind` and `entityId` above are illustrative — read the restored file first and substitute whatever it actually calls the entity kind and id (it resolves them while reading the caller's pending row). Verify the output empirically before committing:

```bash
deno eval 'const id="ea2c34dc-bc8f-490a-9f3e-1234567890ab";
const v=`mit-b-${id.replace(/-/g,"")}`.slice(0,32);
console.log(v, v.length, /^[A-Za-z0-9-]+$/.test(v));'
```

Expected: 32 chars, `true` (no underscore). Confirm two different booking ids produce two different values, and the same id twice produces the same value.

Remove the `TODO(payments)` comment in the same edit.

- [ ] **Step 4: Type-check**

```bash
deno check supabase/functions/charge-saved-card/index.ts
```

- [ ] **Step 5: Record the UAT gate**

Add to the file's header comment:

```ts
 * UAT GATE: confirm a DECLINED attempt can be retried under this stable id.
 * If the acquirer rejects reuse after a decline, append an attempt counter
 * derived from persisted payment_transactions rows — never a random value,
 * which is the bug this replaced.
```

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/charge-saved-card
git commit -m "fix(payments): restore charge-saved-card with a deterministic merchantTransactionId"
```

---

### Task 11: Swap `create-booking` from Wayl links to HyperPay checkouts

**Files:**
- Modify: `supabase/functions/create-booking/index.ts`

**Interfaces:**
- Consumes: `cfg`, `createCheckout` (Task 8).
- Produces: response `{booking_id?, group_id?, checkout_id, payment_mode, hold_until, reference_id, amount_iqd, original_amount_iqd, discount_amount_iqd}` for e-payment; the cash response shape is unchanged.

- [ ] **Step 1: Read the reference implementation**

```bash
git show d03394f^:supabase/functions/create-booking/index.ts | sed -n '325,460p'
```

That is the exact frozen checkout block, including the `merchantTxnId` construction and the commission/discount PATCH. Port it, do not reinvent it.

- [ ] **Step 2: Add the import**

```ts
import { cfg, createCheckout } from "../_shared/hyperpay.ts";
```

- [ ] **Step 3: Accept the new payment_method value**

```ts
payment_method?: "hyperpay" | "cash"; // customer's choice; default "hyperpay"
```

- [ ] **Step 4: Replace the Wayl block with the HyperPay checkout**

Delete `WAYL_BASE`, the `waylBody` construction, the `fetch` to `/api/v1/links`, and the `waylCode` handling. In its place:

```ts
    // merchantTransactionId mirrors the dashboard's `banner-{id}` shape:
    //   booking-{booking_id} / booking-venue-{group_id} — no timestamp suffix,
    // capped at 32 chars. Longer values or underscores trigger the acquirer's
    // 800.100.156 "format error". Nothing parses it back — reconciliation is
    // by checkout_id + reference_id.
    const merchantTxnId = (isGroup
      ? `booking-venue-${customParameter}`
      : `booking-${customParameter}`
    ).slice(0, 32);

    const hpConfig = cfg();
    const checkout = await createCheckout(
      { amount: Math.round(finalIqd), merchantTransactionId: merchantTxnId, tokenize: true },
      hpConfig,
    );
    if (!checkout.id) {
      throw new Error(
        `HyperPay checkout error: ${JSON.stringify(checkout.result ?? checkout)}`,
      );
    }
    const checkoutId  = checkout.id;
    const paymentMode = hpConfig.env === "prod" ? "LIVE" : "TEST";
```

Keep the existing commission resolution and the discount-audit PATCH exactly as they are — they are shared with the cash path. Add `payment_method: 'hyperpay'` to the PATCH body alongside `payment_id: referenceId`. Drop `wayl_code` from the PATCH.

- [ ] **Step 5: Update the response**

```ts
    return json({
      booking_id:  !isGroup ? rpcResult.id : undefined,
      group_id:    isGroup  ? rpcResult.group_id : undefined,
      checkout_id:  checkoutId,
      payment_mode: paymentMode,
      hold_until:  rpcResult.hold_until ?? rpcResult.expires_at,
      reference_id: referenceId,
      amount_iqd:          finalIqd,
      original_amount_iqd: subtotalIqd,
      discount_amount_iqd: discountAmount,
    }, 200);
```

- [ ] **Step 6: Update the header comment and env list**

Change the Wayl references to HyperPay; add `HYPERPAY_ENTITY_ID, HYPERPAY_AUTH_TOKEN, HYPERPAY_ENV, HYPERPAY_BASE` to the documented env vars. Leave `WAYL_*` documented — `booking-action` still needs them (Task 13).

- [ ] **Step 7: Verify the untouchables survived**

```bash
grep -n "cash_disabled\|free: true\|client\b.*dashboard\|commission_pct\|promo_code_id" supabase/functions/create-booking/index.ts
```

Expected: the cash branch, the free-booking early return, the `client: "dashboard"` hint gate, and all discount/commission logic all still present.

- [ ] **Step 8: Type-check**

```bash
deno check supabase/functions/create-booking/index.ts
```

- [ ] **Step 9: Commit**

```bash
git add supabase/functions/create-booking
git commit -m "feat(payments): create-booking issues HyperPay checkouts instead of Wayl links"
```

---

### Task 12: Swap `create-membership` from Wayl links to HyperPay checkouts

**Files:**
- Modify: `supabase/functions/create-membership/index.ts`

**Interfaces:**
- Consumes: `cfg`, `createCheckout` (Task 8).
- Produces: `{membership_id, checkout_id, payment_mode, reference_id}` for e-payment; cash response unchanged.

- [ ] **Step 1: Apply the same transformation as Task 11**

`create-membership` has the same structure: a cash branch at ~line 213, a `persistPaymentRefs` helper, then the Wayl link block at ~line 284. Replace the Wayl block with a `createCheckout` call.

The `merchantTransactionId` for memberships follows the same dash-only, ≤32-char rule:

```ts
const merchantTxnId = `membership-${membershipId}`.slice(0, 32);
```

- [ ] **Step 2: Write `payment_method: 'hyperpay'`**

Add it to the payment-refs PATCH; drop `wayl_code`.

- [ ] **Step 3: Update the response**

```ts
      return json({
        membership_id: membershipId,
        checkout_id:   checkout.id,
        payment_mode:  hpConfig.env === "prod" ? "LIVE" : "TEST",
        reference_id:  referenceId,
      }, 200);
```

The `integrity` field the dashboard path used is not needed — the app uses the native mSDK, not the COPYandPAY widget.

- [ ] **Step 4: Verify the cash branch is untouched**

```bash
grep -n "cash_disabled\|cash: true" supabase/functions/create-membership/index.ts
```

- [ ] **Step 5: Type-check and commit**

```bash
deno check supabase/functions/create-membership/index.ts
git add supabase/functions/create-membership
git commit -m "feat(payments): create-membership issues HyperPay checkouts instead of Wayl links"
```

---

### Task 13: Make refunds three-way in `booking-action`

**Files:**
- Modify: `supabase/functions/booking-action/index.ts`

**Interfaces:**
- Consumes: `reversePayment` (Task 8), `refundPayment` from `_shared/wayl.ts` (unchanged).
- Produces: no signature change.

- [ ] **Step 1: Understand what must not break**

`booking-action:105` currently reads `row.payment_status === "paid" && row.payment_method !== "cash"` and refunds via Wayl keyed on `row.payment_id`. After this cutover, three cases coexist and each needs its own route. Historical `'wayl'` rows still inside their 60-minute window are real refundable money — breaking them is the main risk in this task.

- [ ] **Step 2: Add the HyperPay reverse branch**

```ts
    if (row.payment_status === "paid" && row.payment_method !== "cash") {
      if (!isWithinRefundWindow(row.paid_at, Date.now())) {
        return json({ error: "Refund window has passed" }, 409);
      }

      if (row.payment_method === "hyperpay") {
        // HyperPay reverses against the gateway's own unique_id, recorded by
        // verify-payment in bookings.payment_transactions — NOT our reference_id.
        const uniqueId = await lookupHyperpayUniqueId(SUPABASE_URL, svc, id, body.is_membership);
        if (!uniqueId) return json({ error: "No reversible payment found" }, 409);
        const rv = await reversePayment(uniqueId, hyperpayCfg());
        if (!rv.ok) {
          console.log(`booking-action: reverse declined id=${id} uid=${uniqueId} desc=${rv.description}`);
          return json({ error: "Refund declined", description: rv.description }, 409);
        }
      } else {
        // 'wayl' — historical rows only. Keyed on OUR stored reference.
        // ... existing refundPayment(...) block, unchanged ...
      }

      // ... existing cancel + mark-refunded PATCH, shared by both gateways ...
    }
```

Write `lookupHyperpayUniqueId` to select `unique_id` from `bookings.payment_transactions` for the booking/group/membership, newest successful row first.

- [ ] **Step 3: Keep the reconcile path shared**

The existing "refund accepted but cancel PATCH failed" branch logs `RECONCILE` and returns 500 with `reconcile: true`, deliberately not retrying because a retry would submit a second refund. That logic is gateway-agnostic — leave it downstream of both branches, not duplicated inside them.

- [ ] **Step 4: Confirm the concert group-total rule still applies**

The existing code refunds `group_id ? group total : row amount`, because a concert group's single payment covers every seat and a per-row amount would under-refund. That applies to HyperPay reversals too — an RV voids the original payment in full, so verify the group case does not attempt a partial.

- [ ] **Step 5: Type-check**

```bash
deno check supabase/functions/booking-action/index.ts
```

- [ ] **Step 6: Verify `_shared/wayl.ts` is still imported and used**

```bash
grep -n "refundPayment\|_shared/wayl.ts" supabase/functions/booking-action/index.ts
```

Expected: both present. If the Wayl import is gone, historical refunds are broken — fix before committing.

- [ ] **Step 7: Commit**

```bash
git add supabase/functions/booking-action
git commit -m "feat(payments): route refunds three ways — cash, Wayl (historical), HyperPay RV"
```

---

### Task 14: Full-stack verification

**Files:** none modified.

- [ ] **Step 1: Static analysis and unit tests**

```bash
flutter analyze
flutter test
deno check supabase/functions/**/index.ts
deno test supabase/functions/_shared/
```

Expected: all clean.

- [ ] **Step 2: Confirm no Wayl checkout path survives in the app**

```bash
grep -rn "thewayl.com\|wayl_payment\|payment_url" lib/ supabase/functions/create-booking supabase/functions/create-membership
```

Expected: no output. `_shared/wayl.ts` and `booking-action`'s use of it are the ONLY permitted survivors.

- [ ] **Step 3: Confirm the historical refund path survives**

```bash
grep -rn "refundPayment" supabase/functions/
```

Expected: `booking-action/index.ts` still calls it.

- [ ] **Step 4: Build both platforms**

```bash
flutter build ios --debug --no-codesign
flutter build apk --debug
```

Expected: both succeed. This is the real proof for Task 5.

- [ ] **Step 5: Record the save-card coupling as an E2E gate**

This cannot be unit-tested — it needs a real gateway round-trip — so it belongs in the handoff, not in `flutter test`. The user must confirm on device:

1. Pay with the save-card checkbox OFF → `bookings.user_payment_tokens` gains **no** row.
2. Pay with it ON → exactly **one** row appears.
3. Pay again with it ON using the same card → still one row, with `registration_id` refreshed (the dedupe index merges rather than inserting).

If step 2 produces no row, `verify-payment`'s `save_card` branch did not survive Task 9 and one-tap will never populate.

- [ ] **Step 6: Write the handoff summary**

Report to the user: what shipped, the exact deploy sequence from spec §7, and the two open decisions (store-review skew, and confirming they accept keeping Wayl refund code indefinitely). Do NOT deploy and do NOT merge — both are user-owned.

---

## Deploy sequence (user-owned — do not execute)

1. Apply migration `20260816000001`.
2. Deploy `create-booking`, `create-membership`, `verify-payment`, `charge-saved-card`.
3. Confirm secrets. Verified 2026-08-16: `HYPERPAY_ENV="test"`, `HYPERPAY_BASE` explicitly set. Re-confirm before flipping to `live`.
4. Confirm 0 pending Wayl bookings at cutover — in-flight ones die at the switch.
5. On-device E2E: book in each section → native card form opens (not a webview) → pay → auto-confirms without manual refresh. Then save a card, pay one-tap. Then confirm the dashboard shows the new rows and the 87 historical HyperPay transaction rows still render.
