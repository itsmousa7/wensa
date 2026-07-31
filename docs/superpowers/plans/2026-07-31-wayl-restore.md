# Wayl Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Wayl the sole payment service provider in the `wensa` Flutter app again, keeping every non-payment improvement made during the HyperPay era.

**Architecture:** Surgical payment-only revert on `feature/hyperpay-migration`. The Wayl surface is restored from `main` verbatim (verified safe: only payment commits ever touched those files). The HyperPay surface is deleted from the tree and preserved via the pushed branch plus an annotated tag. `create-booking` is unified into one file written identically into both repos, carrying the union of three fixes that are currently split across three copies.

**Tech Stack:** Flutter 3.44.0 / Dart, Riverpod + freezed (codegen), go_router, `webview_flutter ^4.10.0`, Supabase Edge Functions (Deno 2.9.2), Supabase CLI 2.108.0.

## Global Constraints

- Repo: `/Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa`, branch `feature/hyperpay-migration`. Do **not** merge to `main`.
- Dashboard repo: `/Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard`, branch `feature/wayl-restore`. Touch **only** `supabase/functions/create-booking/index.ts` there. Nothing else.
- Supabase project ref: `qvozjwlkzordudkhamcu`.
- Never force-push `origin/feature/hyperpay-migration` or `origin/feature/hyperpay-gateway`.
- Do **not** drop any database table or migration. Do **not** delete any `hyperpay-*` edge function from Supabase.
- Preserve `lib/features/bottom_bar/widgets/ios_nav_shell.dart` as it is on `HEAD` — it carries a non-payment fix from the mixed commit `ff2f968`.
- Preserve `android/build.gradle.kts` as it is on `HEAD` — its change merges two duplicate `subprojects {}` blocks and is not HyperPay-specific.
- Do not run `flutter pub upgrade` or edit dependency versions. `pubspec.yaml`'s only branch change is the build bump to `1.0.0+8`; keep it.

---

### Task 1: Tag and document the HyperPay backup

Do this first so the frozen state is recoverable before anything is deleted.

**Files:**
- Create: `docs/hyperpay-restore.md`

**Interfaces:**
- Consumes: nothing
- Produces: tag `hyperpay-v1` pointing at `afa3036`

- [ ] **Step 1: Confirm the tag target exists**

`afa3036` is the last commit with HyperPay fully wired. `HEAD` has since moved
ahead by the spec and plan doc commits, which is expected — the tag targets
`afa3036` explicitly, not `HEAD`.

Run:
```bash
git log --oneline -1 afa3036
git tag -l hyperpay-v1
```
Expected: `afa3036 fix(notifications): time membership reminders to local civil hours`, and no existing `hyperpay-v1` tag. If the tag already exists, stop — do not move it.

- [ ] **Step 2: Create the annotated tag**

```bash
git tag -a hyperpay-v1 afa3036 -m "Frozen HyperPay (OPPWA/COPYandPAY) integration for the Wensa app

Full mSDK integration: Dart feature folder, iOS OPPWAMobile.xcframework +
ipworks3ds pods, Android .aar libs and channel handler, verify-payment and
charge-saved-card edge functions, saved-card tokenization.

Wayl is primary again as of the following commit. See docs/hyperpay-restore.md."
```

- [ ] **Step 3: Verify the tag resolves**

Run: `git log --oneline -1 hyperpay-v1`
Expected: `afa3036 fix(notifications): time membership reminders to local civil hours`

- [ ] **Step 4: Write the restore doc**

Create `docs/hyperpay-restore.md`:

```markdown
# Restoring the HyperPay gateway (Wensa app)

Wayl is the primary PSP again. HyperPay is **deleted from this repo's tree** and
preserved as a tag. This differs from `wansa-admin-dashboard`, which froze its
HyperPay modules in-tree: the dashboard's HyperPay surface is a handful of
TypeScript files, whereas the app's is ~553k lines of vendored iOS/Android SDK
binaries that would bloat every clone and Xcode build.

## Where the code lives

| What | Where |
|---|---|
| Frozen snapshot | tag **`hyperpay-v1`** (= `feature/hyperpay-migration` @ `afa3036`) |
| Branch | `origin/feature/hyperpay-migration` — do not force-push |
| Dashboard counterpart | tag `hyperpay-v1` in `wansa-admin-dashboard` @ `672a0f7` |

```bash
git fetch origin --tags
git show hyperpay-v1
git diff hyperpay-v1 HEAD -- lib/ supabase/    # what the revert changed
```

## What was removed

- `lib/features/hyperpay_payment/**` — 25 Dart files: card form, saved cards,
  payment method sheet, payment result page, method channel, validators
- `test/features/hyperpay_payment/**` — 5 test files
- `supabase/functions/verify-payment/`, `supabase/functions/charge-saved-card/`
- `supabase/functions/_shared/{hyperpay.ts,hyperpay_test.ts,payment_flow.ts,payments.ts}`
- iOS: `ios/HyperpaySDK/**` (OPPWAMobile.xcframework + ipworks3ds_sdk.xcframework,
  544 files), `ios/Runner/SceneDelegate.swift`, the `HyperpaySDK` pod line
- Android: `app/libs/{oppwa.mobile.aar,ipworks3ds_sdk.aar}`, the method-channel
  handler in `MainActivity.kt`, `res/layout/async_payment_activity.xml`,
  `WensaChallengeTheme`, `wensa_challenge_header`, `wensa_challenge_title`,
  viewBinding, minSdk 24 floor, and the mSDK dependency block

## What was kept

Migrations `20260716000001` (`user_payment_tokens`), `20260716000002` and
`20260716000003` (`lock_for_payment` RPCs) are applied and left in place —
dropping them only makes a return to HyperPay harder. `bookings.payment_transactions`
still backs the dashboard's historical rows.

The `hyperpay-*` edge functions remain deployed but unused. `get-payment-transaction`
is still active and serves RRN / return codes for historical HyperPay rows.

## Coming back

1. `git checkout hyperpay-v1 -- lib/features/hyperpay_payment ios/HyperpaySDK android/app/libs`
2. Restore the native wiring: `MainActivity.kt` channel handler, `ios/Podfile`
   pod line, `SceneDelegate.swift`, the Android theme/strings/colors resources.
3. Re-point the four booking sections and the router at `launchHyperpayPayment`.
4. Redeploy `create-booking`, `verify-payment`, `charge-saved-card`.
5. Env vars: `HYPERPAY_BASE`, `HYPERPAY_ENTITY_ID`, `HYPERPAY_AUTH_TOKEN`, `HYPERPAY_ENV`.

## Gotchas if you switch back

- `merchantTransactionId` uses **dashes**, capped at 32 chars — OPPWA returns
  `800.100.156` on any body deviation. See `_shared/hyperpay.ts` at the tag.
- `200.300.404` on an already-consumed checkout session is not a payment failure.
- A 3DS challenge legitimately sits on `000.200.*` — keep polling, never treat
  as pending-forever.
- IQD amounts are integers; `amount.toFixed(2)` with a fractional value is rejected.
```

- [ ] **Step 5: Commit**

```bash
git add docs/hyperpay-restore.md
git commit -m "docs: freeze HyperPay at tag hyperpay-v1 with a restore map

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

- [ ] **Step 6: Push the branch and tag**

```bash
git push origin feature/hyperpay-migration
git push origin hyperpay-v1
```
Expected: both succeed. The tag must exist on origin before Task 4 deletes anything.

---

### Task 2: Build the unified `create-booking`

The union of three fixes currently split across three copies. No Flutter changes here, so it is independently reviewable.

**Files:**
- Modify: `supabase/functions/create-booking/index.ts` (app repo — replace wholesale)
- Modify: `/Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard/supabase/functions/create-booking/index.ts` (write identical copy)

**Interfaces:**
- Consumes: nothing from earlier tasks
- Produces: an edge function returning `{ booking_id?, group_id?, payment_url, hold_until, reference_id, amount_iqd, ... }` — Task 3's Dart providers read `payment_url` and `reference_id` from this shape.

- [ ] **Step 1: Start from `main`'s Wayl copy**

`main`'s copy is the only one with the event-discount guard.

```bash
git checkout main -- supabase/functions/create-booking/index.ts
grep -c "isEventCategory" supabase/functions/create-booking/index.ts
```
Expected: `2` (the helper definition and its call site).

- [ ] **Step 2: Verify it is Wayl and lacks the gate**

```bash
grep -c "thewayl" supabase/functions/create-booking/index.ts     # expect >= 1
grep -c "isDashboardBooking" supabase/functions/create-booking/index.ts  # expect 0
```

- [ ] **Step 3: Add the `client` hint to the request body type**

In `interface BasePaylod`, after the `guest_name` line, add:

```ts
  client?: "dashboard"; // dashboard-only hint; narrows `source` (see below)
```

- [ ] **Step 4: Apply the client-hint gate**

Replace the `isDashboard` / `source` block (the one following the comment about dashboard powers) with:

```ts
    // Dashboard powers (book on behalf of a customer, free path) are limited to
    // admins and to a merchant acting on its OWN merchant. A merchant hitting
    // another merchant's place is treated as a regular paying customer.
    const hasDashboardRole = callerRole === "admin" ||
      (callerRole === "merchant" && callerMerchantId !== null && callerMerchantId === ctx.merchantId);
    // An admin/merchant account can ALSO book through the mobile app as an
    // ordinary customer — `hasDashboardRole` alone can't tell those apart since
    // it's role+ownership only. `client: "dashboard"` is a hint the admin/merchant
    // dashboards' CreateBookingModal sends (the mobile app never does). It is the
    // gate for EVERY dashboard-only power: the free-booking path (payment toggle
    // OFF) and the `source` label. Without it, a merchant booking at their own
    // venue from the MOBILE app would hit the free path when their toggle is off,
    // returning { free: true } with no payment_url — the app then errors on the
    // missing checkout while the slot is already booked. Gating on the hint keeps
    // the toggle scoped to the dashboard; the mobile app always requires payment.
    const isDashboardBooking = hasDashboardRole && body.client === "dashboard";
    const source = isDashboardBooking ? callerRole : "mobile_app";
```

- [ ] **Step 5: Gate the free path on the new flag**

Change the free-path condition to use `isDashboardBooking`:

```ts
    if (isDashboardBooking && !(await dashboardPaymentRequired(SUPABASE_URL, svc, ctx.merchantId))) {
```

- [ ] **Step 6: Apply the `callRpc` typing improvement**

Change the `callRpc` return type:

```ts
): Promise<Record<string, unknown>> {
```

- [ ] **Step 7: Verify no stale `isDashboard` identifier remains**

Run:
```bash
grep -n "isDashboard\b" supabase/functions/create-booking/index.ts
```
Expected: no output. Only `isDashboardBooking` and `hasDashboardRole` should exist.

- [ ] **Step 8: Type-check**

Run: `deno check supabase/functions/create-booking/index.ts`
Expected: no errors. If it reports an unused `DiscountResolved` import or similar, fix it rather than suppressing.

- [ ] **Step 9: Confirm all three fixes are present**

```bash
grep -c "isEventCategory"        supabase/functions/create-booking/index.ts  # 2
grep -c "isDashboardBooking"     supabase/functions/create-booking/index.ts  # 3
grep -c "Promise<Record<string, unknown>>" supabase/functions/create-booking/index.ts  # 1
grep -c "thewayl"                supabase/functions/create-booking/index.ts  # >= 1
grep -ci "hyperpay\|checkout_id"  supabase/functions/create-booking/index.ts  # 0
```

- [ ] **Step 10: Copy the identical file into the dashboard repo**

First confirm the dashboard repo is where it should be and clean:
```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
git rev-parse --abbrev-ref HEAD   # expect: feature/wayl-restore
git status --short supabase/functions/create-booking/index.ts  # expect: no output
```
If HEAD is not `feature/wayl-restore`, stop and ask.

Then copy and verify byte-identity:
```bash
cp /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/supabase/functions/create-booking/index.ts \
   supabase/functions/create-booking/index.ts
diff /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/supabase/functions/create-booking/index.ts \
     supabase/functions/create-booking/index.ts && echo IDENTICAL
```
Expected: `IDENTICAL`.

- [ ] **Step 11: Type-check the dashboard copy**

Run: `deno check supabase/functions/create-booking/index.ts`
Expected: no errors.

- [ ] **Step 12: Commit both repos**

Dashboard:
```bash
git add supabase/functions/create-booking/index.ts
git commit -m "fix(booking): restore event-discount guard and client-hint gate

The wholesale restore in 3f328af came from a snapshot predating both fixes:
auto discounts could bleed onto event tickets, and the client: \"dashboard\"
hint CreateBookingModal sends had no consumer. Now byte-identical to the app
repo's copy.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

App:
```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
git add supabase/functions/create-booking/index.ts
git commit -m "revert(payments): create-booking issues Wayl links again

Unified file: main's Wayl base (event-discount guard) + the f3f10c3
client-hint gate + the dashboard's callRpc typing. Byte-identical in both
repos.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Restore the Wayl payment flow in Dart

Restores the webview flow and removes the HyperPay entry points. The app will not compile until Task 4 removes the dangling HyperPay imports, so Tasks 3 and 4 land as one working commit at the end of Task 4.

**Files:**
- Restore from `main`: `lib/features/wayl_payment/config/wayl_config.dart`, `lib/features/wayl_payment/data/models/wayl_line_item.dart`, `lib/features/wayl_payment/data/models/wayl_link_request.dart`, `lib/features/wayl_payment/data/models/wayl_link_response.dart`, `lib/features/wayl_payment/data/services/wayl_api_service.dart`, `lib/features/wayl_payment/presentation/screens/wayl_webview_screen.dart`, `lib/features/booking/presentation/pages/payment_webview_page.dart`
- Restore from `main`: `lib/features/booking/presentation/sections/{concert,farm,padel,membership,restaurant}_section.dart`
- Restore from `main`: `lib/features/booking/presentation/providers/booking_submit_provider.{dart,freezed.dart,g.dart}`, `membership_submit_provider.{dart,g.dart}`
- Restore from `main`: `lib/features/booking/domain/models/booking.{dart,freezed.dart,g.dart}`, `membership.{dart,freezed.dart,g.dart}`
- Restore from `main`: `lib/features/profile/presentation/widgets/profile_content.dart`
- Modify: `lib/core/router/router_provider.dart`, `lib/core/router/router_names.dart`

**Interfaces:**
- Consumes: Task 2's `create-booking` response shape (`payment_url`, `reference_id`)
- Produces: `PaymentWebViewPage.push(context, paymentUrl, {required String referenceId, String? redirectionUrl, void Function(String, String)? onPaymentSuccess, void Function()? onPaymentFailed, void Function()? onPaymentCancelled})`; `BookingSubmitState.success({required String bookingId, required String paymentUrl, required String holdUntil, required String waylReferenceId})` — a 4-field success record, so `maybeWhen(success: (id, _, _, _) => ...)` takes four positional args.

- [ ] **Step 1: Restore the Wayl feature folder and webview entry point**

```bash
git checkout main -- \
  lib/features/wayl_payment/ \
  lib/features/booking/presentation/pages/payment_webview_page.dart
```

- [ ] **Step 2: Verify the restored files landed**

Run: `git status --short lib/features/wayl_payment lib/features/booking/presentation/pages/`
Expected: 7 files staged as new (`A`).

- [ ] **Step 3: Restore the booking sections**

Safe wholesale — verified that only payment commits (`d0130a9`, `e5fe7cb`, `c9170ae`) ever touched these files, so no non-payment work is lost.

```bash
git checkout main -- lib/features/booking/presentation/sections/
```

- [ ] **Step 4: Restore the submit providers and domain models**

```bash
git checkout main -- \
  lib/features/booking/presentation/providers/booking_submit_provider.dart \
  lib/features/booking/presentation/providers/booking_submit_provider.freezed.dart \
  lib/features/booking/presentation/providers/booking_submit_provider.g.dart \
  lib/features/booking/presentation/providers/membership_submit_provider.dart \
  lib/features/booking/presentation/providers/membership_submit_provider.g.dart \
  lib/features/booking/domain/models/booking.dart \
  lib/features/booking/domain/models/booking.freezed.dart \
  lib/features/booking/domain/models/booking.g.dart \
  lib/features/booking/domain/models/membership.dart \
  lib/features/booking/domain/models/membership.freezed.dart \
  lib/features/booking/domain/models/membership.g.dart
```

- [ ] **Step 5: Confirm `waylCode` is back on both models**

Run:
```bash
grep -n "waylCode\|wayl_code" lib/features/booking/domain/models/booking.dart lib/features/booking/domain/models/membership.dart
```
Expected: two lines per file — the field declaration and the `fromJson` mapping. The DB columns `bookings.wayl_code` and `memberships.wayl_code` already exist, so no migration is needed.

- [ ] **Step 6: Restore the profile page without the Saved Cards tile**

```bash
git checkout main -- lib/features/profile/presentation/widgets/profile_content.dart
grep -c "savedCards\|Saved Cards" lib/features/profile/presentation/widgets/profile_content.dart
```
Expected: `0`.

- [ ] **Step 7: Remove the HyperPay route from the router**

In `lib/core/router/router_provider.dart`, delete the import on line 23:

```dart
import 'package:future_riverpod/features/hyperpay_payment/hyperpay_payment.dart';
```

and delete this whole `GoRoute` block (around lines 130-134):

```dart
      GoRoute(
        path: '/saved-cards',
        name: RouteNames.savedCards,
        builder: (_, s) => SavedCardsPage(isAr: s.extra as bool? ?? false),
      ),
```

- [ ] **Step 8: Remove the now-unused route name**

In `lib/core/router/router_names.dart`, delete line 21:

```dart
  static const savedCards = 'saved-cards';
```

- [ ] **Step 9: Confirm no Dart file still references the HyperPay feature**

Run:
```bash
grep -rn "hyperpay_payment\|launchHyperpayPayment\|SavedCardsPage\|PaymentMethodSheet" --include="*.dart" lib/
```
Expected: no output. If any remains, fix the call site — do not re-add the import.

Do not commit yet; the tree still contains the HyperPay feature folder. Task 4 completes this commit.

---

### Task 4: Delete the HyperPay surface and land the revert

**Files:**
- Delete: `lib/features/hyperpay_payment/**` (25 files), `test/features/hyperpay_payment/**` (5 files)
- Delete: `supabase/functions/verify-payment/`, `supabase/functions/charge-saved-card/`, `supabase/functions/_shared/{hyperpay.ts,hyperpay_test.ts,payment_flow.ts,payments.ts}`
- Delete: `ios/HyperpaySDK/**`, `ios/Runner/SceneDelegate.swift`, `android/app/libs/*.aar`, `android/app/src/main/res/layout/async_payment_activity.xml`, `android/app/src/main/res/values/strings.xml`, `android/app/src/main/res/values-ar/strings.xml`
- Modify: `ios/Podfile`, `android/app/build.gradle.kts`, `android/app/proguard-rules.pro`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/values/colors.xml`, `android/app/src/main/res/values/styles.xml`
- Restore from `main`: `android/app/src/main/kotlin/app/wensa/mobile/MainActivity.kt`

**Interfaces:**
- Consumes: Task 3's restored Wayl flow
- Produces: a compiling app with no HyperPay code

- [ ] **Step 1: Delete the Dart feature and its tests**

```bash
git rm -r --quiet lib/features/hyperpay_payment test/features/hyperpay_payment
```

- [ ] **Step 2: Delete the HyperPay edge functions and shared modules**

```bash
git rm -r --quiet supabase/functions/verify-payment supabase/functions/charge-saved-card
git rm --quiet supabase/functions/_shared/hyperpay.ts \
               supabase/functions/_shared/hyperpay_test.ts \
               supabase/functions/_shared/payment_flow.ts \
               supabase/functions/_shared/payments.ts
```

- [ ] **Step 3: Check whether anything outside HyperPay uses `SceneDelegate`**

```bash
grep -rn "SceneDelegate" ios/ --include="*.swift" --include="*.plist" --include="*.pbxproj" | grep -v "ios/Runner/SceneDelegate.swift"
```
Expected: no output — the file was added by HyperPay commits only and is not registered in `Info.plist` or the Xcode project. If this returns anything, stop and report rather than deleting.

- [ ] **Step 4: Delete the iOS SDK and scene delegate**

```bash
git rm -r --quiet ios/HyperpaySDK ios/Runner/SceneDelegate.swift
```

- [ ] **Step 5: Remove the pod line from `ios/Podfile`**

Delete this line:

```ruby
  pod 'HyperpaySDK', :path => 'HyperpaySDK'
```

- [ ] **Step 6: Delete the Android SDK binaries and HyperPay-only resources**

```bash
git rm --quiet android/app/libs/oppwa.mobile.aar \
                android/app/libs/ipworks3ds_sdk.aar \
                android/app/src/main/res/layout/async_payment_activity.xml \
                android/app/src/main/res/values/strings.xml \
                android/app/src/main/res/values-ar/strings.xml
```

`values/strings.xml` and `values-ar/strings.xml` were created by the HyperPay work and contain only `wensa_challenge_title`, so they go entirely.

- [ ] **Step 7: Restore `MainActivity.kt` from `main`**

`main`'s version is the 5-line Flutter default; the branch added a 352-line method-channel handler.

```bash
git checkout main -- android/app/src/main/kotlin/app/wensa/mobile/MainActivity.kt
cat android/app/src/main/kotlin/app/wensa/mobile/MainActivity.kt
```
Expected: exactly `package app.wensa.mobile`, the `FlutterActivity` import, and `class MainActivity : FlutterActivity()`.

- [ ] **Step 8: Revert the HyperPay hunks in `android/app/build.gradle.kts`**

Remove the `buildFeatures { viewBinding = true }` block, restore the `minSdk` line, and delete the mSDK dependency block. The `minSdk` line becomes:

```kotlin
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
```

Delete these dependency lines entirely:

```kotlin
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.recyclerview:recyclerview:1.4.0")
    implementation("androidx.browser:browser:1.8.0")
    implementation("androidx.fragment:fragment-ktx:1.8.6")
    implementation("androidx.constraintlayout:constraintlayout:2.2.1")
    implementation("androidx.webkit:webkit:1.13.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("com.google.code.gson:gson:2.11.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
```

Leave `android/build.gradle.kts` alone — its change is an unrelated cleanup.

- [ ] **Step 9: Revert the remaining Android resource hunks**

In `android/app/src/main/AndroidManifest.xml`, restore the opening tag to:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
```

and delete the `AsyncPaymentActivity` `<activity>` block.

In `android/app/src/main/res/values/colors.xml`, delete the `wensa_challenge_header` colour and its comment.

In `android/app/src/main/res/values/styles.xml`, delete the `WensaChallengeTheme` style and its comment.

In `android/app/proguard-rules.pro`, delete the `# HyperPay mSDK + ipworks 3DS` comment and the keep rules under it.

- [ ] **Step 10: Confirm the tree is free of HyperPay**

```bash
grep -rni "hyperpay\|oppwa\|ipworks" --include="*.dart" --include="*.ts" --include="*.kt" --include="*.swift" --include="*.kts" --include="*.xml" --include="*.pro" --include="*.rb" \
  lib/ test/ supabase/ android/ ios/Podfile 2>/dev/null
```
Expected: no output.

- [ ] **Step 11: Analyze**

Run: `flutter analyze`
Expected: no errors. Warnings about unused imports in untouched files are acceptable; errors are not.

- [ ] **Step 12: Test**

Run: `flutter test`
Expected: all pass. The 5 HyperPay tests are gone with their feature.

- [ ] **Step 13: Verify the iOS pods resolve**

Run:
```bash
cd ios && pod install && cd ..
```
Expected: succeeds with no `HyperpaySDK` entry. A stale `Podfile.lock` referencing it will fail the build — if `pod install` errors, delete `ios/Podfile.lock` and rerun.

- [ ] **Step 14: Commit the revert**

```bash
git add -A
git commit -m "revert(payments): restore Wayl as the primary PSP, remove HyperPay

Restores the Wayl webview checkout, waylCode on Booking/Membership, and the
Wayl payment flow across all booking sections. Removes the HyperPay Dart
feature, its edge functions, and the vendored iOS/Android mSDKs (~553k lines).

Every non-payment fix from the HyperPay era is kept: notification reminders,
the dashboard-powers booking gate, bottom-bar and iOS shell fixes, Google
sign-in tweaks, build 1.0.0+8.

HyperPay is frozen at tag hyperpay-v1; docs/hyperpay-restore.md is the map back.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Deploy and verify the cutover

**Files:** none — deployment only.

**Interfaces:**
- Consumes: Task 2's unified `create-booking`, Task 4's committed revert

- [ ] **Step 1: Confirm the Wayl secrets are set**

```bash
supabase secrets list --project-ref qvozjwlkzordudkhamcu
```
Expected: `WAYL_API_KEY`, `WAYL_WEBHOOK_SECRET`, `WAYL_WEBHOOK_URL` (or `WAYL_BOOKING_WEBHOOK_URL`), `WAYL_ENV`, `APP_DEEP_LINK_BASE` all present. Values are hashed and not readable — presence is what matters.

**If any is missing, STOP.** Report which, and do not deploy. Deploying a Wayl `create-booking` without its API key breaks checkout outright.

- [ ] **Step 2: Confirm no bookings are mid-flight**

Run this via the Supabase MCP `execute_sql` tool (project `qvozjwlkzordudkhamcu`)
or the SQL editor in the Supabase dashboard — the CLI has no `db query`
subcommand:

```sql
select count(*) from bookings.bookings where status = 'pending';
```
Expected: `0` (it was 0 at planning time). If non-zero, wait for the holds to expire before deploying — an in-flight HyperPay checkout cannot be confirmed once `create-booking` is Wayl.

- [ ] **Step 3: Deploy `create-booking` from the app repo**

```bash
supabase functions deploy create-booking --project-ref qvozjwlkzordudkhamcu
```

- [ ] **Step 4: Deploy the dashboard's restored functions**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
supabase functions deploy create-membership --project-ref qvozjwlkzordudkhamcu
supabase functions deploy booking-action    --project-ref qvozjwlkzordudkhamcu
```

These carry the parallel session's Wayl restore (`_shared/wayl.ts` `refundPayment()`). `wayl-webhook`, `booking-wayl-webhook`, and `wayl-refund` are already ACTIVE and need no redeploy.

- [ ] **Step 5: Confirm the deploys landed**

```bash
supabase functions list --project-ref qvozjwlkzordudkhamcu | grep -E "create-booking|create-membership|booking-action"
```
Expected: version numbers incremented, all `ACTIVE`.

- [ ] **Step 6: End-to-end on a real device**

This is the definition of done. Run the app on a physical device:

1. Start a booking in any section (padel, farm, concert, or membership).
2. Confirm the Wayl webview opens with a payment URL — not a card form.
3. Complete the payment.
4. Confirm the booking flips to confirmed in the app without a manual refresh.
5. In the dashboard's **Bookings** section, confirm the row shows the Wayl Ref.
6. In the dashboard's **Transactions** section, confirm the new payment appears
   alongside the 87 historical HyperPay rows, which must still render.

- [ ] **Step 7: Push**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa
git push origin feature/hyperpay-migration

cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard
git push -u origin feature/wayl-restore
```

The dashboard's `feature/wayl-restore` is currently **unpushed** — a single local branch holds the entire dashboard restore. Push it regardless of how the rest goes.

---

## Rollback

If the cutover misbehaves, HyperPay is one deploy away — nothing was torn down:

```bash
git checkout hyperpay-v1 -- supabase/functions/create-booking/index.ts
supabase functions deploy create-booking --project-ref qvozjwlkzordudkhamcu
```

The `hyperpay-*` functions, `bookings.user_payment_tokens`, and
`bookings.payment_transactions` are all still in place.
