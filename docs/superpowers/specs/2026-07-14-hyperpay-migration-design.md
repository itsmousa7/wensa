# HyperPay Migration — Design

**Date:** 2026-07-14
**Branch:** `feature/hyperpay-migration` (isolated from `main` until proven end-to-end)
**Scope:** Replace the Wayl payment gateway with HyperPay (native SDK v7.11, custom card UI) for all paid flows: bookings (padel, farm, restaurant, concert, general admission) **and memberships**.

## Background

Today the app calls Supabase edge functions (`create-booking`, `create-membership`) which create a pending row plus a Wayl payment link. The app opens that link in a webview (`wayl_webview_screen.dart`), a Wayl webhook flips the row to confirmed, and the app polls by `reference_id`.

Reference implementation: the `Flutter_HyperPay` demo (github.com/itsmousa7/Flutter_HyperPay). We take from it only:
- The **custom UI** card-form pattern (Flutter form → MethodChannel → native SDK).
- The **3DS challenge redirect** handling: async transactions return a redirect URL; the demo opens it in a native WebView and intercepts navigation to the app's shopper-result URL scheme to detect completion.
- The Android native integration (`OppPaymentProvider`, `CardPaymentParams`, `shopperResultUrl`) and the SDK dependency list / minSdk 24 requirement.

The demo has **no iOS implementation** — the iOS channel handler is new work written against `OPPWAMobile.xcframework` from `~/Downloads/SDK v7.11/iOS_Frameworks_7.11.0`. Android AARs come from `Android_Frameworks_7.11.0`.

Decisions made with the user:
- Checkout IDs are created **server-side**; HyperPay merchant credentials (entity ID, access token) already live in Supabase secrets and are used by the Wensa dashboard.
- Payment methods: **VISA/Mastercard only.** No Mada, STC Pay, Apple Pay, tokenization, or Ready UI.
- Booking confirmation via a new **`verify-payment` edge function** (server-side status check), not a webhook.
- **Full replacement** of Wayl on this branch — no coexistence flag.

## Architecture

```
Flutter card form (Wensa-styled)
   │  MethodChannel 'app.wensa.mobile/hyperpay'
   ▼
Native SDK (Android Kotlin / iOS Swift)
   │  submitTransaction(CardPaymentParams, shopperResultUrl = wensa://payment-result)
   ├─ SYNC → return "success"
   └─ ASYNC (3DS) → open redirect URL in native WebView,
        intercept wensa:// scheme → return "success"
   ▼
Flutter calls `verify-payment` edge function
   │  GET /v1/checkouts/{id}/payment (server-held credentials)
   ▼
Success code → booking/membership row flipped to confirmed → existing ticket/success flow
```

## Components

### 1. Server — Supabase edge functions

**`create-booking` (modified):** The Wayl link-creation block is replaced with `POST {HYPERPAY_BASE}/v1/checkouts` (entity ID + access token from Supabase secrets, same as the dashboard). `merchantTransactionId` = existing `reference_id`; amount/currency (IQD) and all pending-row/hold/promo/commission logic unchanged. Response returns `checkout_id` (instead of `payment_url`) alongside `booking_id`/`group_id`, `hold_until`, `reference_id`.

**`create-membership` (out-of-repo):** Its source is not in this repo (deployed from the dashboard project). It needs the identical Wayl→HyperPay swap and a `checkout_id` in its response. **Open item:** apply the same change where its source lives, or import the function into this repo first. The app-side changes in this design assume its response shape gains `checkout_id`.

**`verify-payment` (new):** Auth-required. Input: `{ checkout_id, reference_id }`. Steps:
1. Look up the pending booking/membership rows by `reference_id` (`payment_id` column); verify they belong to the calling user.
2. `GET /v1/checkouts/{checkout_id}/payment?entityId=…` with the server-held token.
3. If the result code matches success (`000.000.*`, `000.100.1*`), perform the same DB updates the Wayl webhook does today (status → confirmed, payment_status → paid, notifications), for bookings, concert groups, and memberships.
4. Idempotent: if already confirmed, return success without re-updating.
5. Returns `{ paid: bool, status, message }`; if not paid, rows stay pending and the existing hold-expiry crons clean them up.

### 2. Flutter — `lib/features/hyperpay_payment/` (replaces `lib/features/wayl_payment/`)

- **`data/services/hyperpay_channel.dart`** — wrapper around `MethodChannel('app.wensa.mobile/hyperpay')`. One method: submit card payment with `{ checkoutid, brand, card_number, holder_name, month, year (4-digit), cvv, mode }`. Returns a status string; platform exceptions map to typed failures (cancelled, invalid card, transaction failed).
- **`presentation/screens/card_payment_screen.dart`** — Wensa-styled card form: card number (formatted, 16 digits, Luhn-checked), holder name, MM/YY expiry, CVV. Brand auto-detected (leading 4 → VISA, else MASTER). PAY → channel → on `"success"`/`"SYNC"` call `verify-payment` → on `paid: true` route to the existing post-payment success flow (same destination the Wayl webview used on deep-link success). Failure/cancel shows an inline error and allows retry.
- **`presentation/providers/payment_provider.dart`** — Riverpod state machine: idle → submitting → verifying → paid / failed(message). Retry after a declined/failed attempt reuses the **same checkout ID** (a HyperPay checkout stays valid ~30 minutes and accepts multiple attempts until one succeeds). If HyperPay rejects the checkout as expired/consumed, the screen sends the user back to the booking confirm step to create a fresh booking + checkout — the same recovery path Wayl uses today.
- **Submit providers (`booking_submit_provider.dart`, `membership_submit_provider.dart`):** `BookingSubmitState.success.paymentUrl` → `checkoutId`; `waylReferenceId` → `referenceId`. All booking sections (padel, farm, restaurant, concert, general admission) and the membership section navigate to `CardPaymentScreen(checkoutId, referenceId, bookingId)` instead of the payment webview.
- **Deleted:** `lib/features/wayl_payment/` (all files), `payment_webview_page.dart`, `wayl_webview_screen.dart`, Wayl polling code, and any `thewayl.com` references.

### 3. Android native

- SDK AARs from `Android_Frameworks_7.11.0` → `android/app/libs/`; `implementation(fileTree("libs"))` plus the demo's required dependencies (material, gson, browser, recyclerview, fragment-ktx, constraintlayout, webkit, lifecycle-viewmodel-ktx). **No** Braintree/PayPal/Venmo. `minSdk = maxOf(flutter.minSdkVersion, 24)`.
- `MainActivity.kt` gains the channel handler (Kotlin port of the demo's `MainActivity.java`, card-only paths):
  - Validate with `CardPaymentParams.isNumberValid/isHolderValid/isExpiryMonthValid/isExpiryYearValid/isCvvValid`.
  - `CardPaymentParams(checkoutId, brand, …)` + `setShopperResultUrl("wensa://payment-result")` → `OppPaymentProvider.submitTransaction` (TEST/LIVE from the `mode` argument).
  - `transactionCompleted`: SYNC → resolve `"SYNC"`; async → open `transaction.redirectUrl` in the demo's full-screen WebView dialog, restyled with Wensa colors, intercepting the `wensa` scheme → resolve `"success"`. Close button → typed "cancelled" error.
  - `onNewIntent` fallback for the scheme redirect (external browser case).
  - Channel results marshalled on the main thread; single pending result at a time.

### 4. iOS native (new code)

- Embed `OPPWAMobile.xcframework` (+ bundled 3DS framework) into Runner (Embed & Sign).
- Swift channel handler (AppDelegate or a dedicated `HyperPayHandler` class registered from AppDelegate): same method/params contract as Android.
  - `OPPPaymentProvider(mode:)` + `OPPCardPaymentParams` (with shopperResultURL `wensa://payment-result`) → `submitTransaction`.
  - Async/3DS: open `transaction.redirectURL` in an in-app WKWebView (modal, Wensa-styled, cancellable) intercepting the `wensa` scheme; `SceneDelegate.openURLContexts` also resolves the pending result if the redirect arrives via the OS (scheme already registered in Info.plist).
  - Resolve/reject the FlutterResult exactly once; errors map to the same typed codes as Android.

### 5. Error handling

- Native cancel/failure → typed channel error → form shows localized message, booking hold stays; user may retry or go back (back triggers the existing `cancelPending`).
- `verify-payment` not-paid → stay on form with error; pending rows expire via existing crons.
- Network failure during verify → retry verify (safe, idempotent) without resubmitting payment.

### 6. Testing & acceptance

- `flutter analyze` clean; existing test suite green.
- TEST-mode end-to-end on Android **and** iOS with HyperPay test cards: success (SYNC), 3DS challenge success, 3DS cancel, declined card — for one booking category and one membership.
- Verify booking flips to confirmed in DB and the ticket appears in bookings history.
- Merge to `main` only after both platforms pass.

## Out of scope

- Apple Pay, Mada, STC Pay, card tokenization ("save card"), Ready UI.
- Dashboard repo changes (only flagged: `create-membership` swap must land there or be imported here).
- Refunds.
