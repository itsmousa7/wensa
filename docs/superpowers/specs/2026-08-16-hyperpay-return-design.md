# HyperPay returns as the app's sole e-payment gateway

**Date:** 2026-08-16
**Status:** approved design, not yet planned
**Repo scope:** `wensa` (Flutter app) only — `wansa-admin-dashboard` is out of scope
**Supersedes for the app:** `2026-07-31-wayl-restore-design.md`

## Why

HyperPay was frozen at tag `hyperpay-v1` (`afa3036`) on 2026-07-31 and deleted from
this repo's tree; Wayl became the app's PSP again. The user now wants HyperPay back
as the app's payment gateway, without disturbing the features that shipped since.

Two such features exist and are load-bearing. Neither existed at the tag:

1. **Cash payment** (2026-08-11) — `payment_method` on `bookings`/`memberships`,
   `merchants.cash_enabled`, a cash branch in `create-booking`/`create-membership`
   that confirms immediately with no gateway round-trip.
2. **Inline payment method selection** (2026-08-11) — `PaymentMethodSelector`
   rendered above the summary card in every paying flow, replacing the old modal
   sheet.

This is therefore not a revert. `git checkout hyperpay-v1 -- …` on the booking
sections would drag 162 commits of unrelated work backwards. The design below
changes only what "E-Payment" *resolves to* and leaves the cash and selector
architecture untouched.

## Decisions

| Question | Decision |
|---|---|
| Wayl's fate in the app | HyperPay replaces it entirely — `wayl_payment/` and the Wayl webview are deleted |
| Repo scope | This repo only; the dashboard is untouched |
| Saved cards | Restored, **and** the known double-charge bug is fixed |
| `payment_method` value | Add `'hyperpay'` as a third value; `'wayl'` is retained for historical rows |
| Delivery | Feature branch `feature/hyperpay-return`; the user deploys and runs the on-device E2E |

## Non-goals

- Any change to the cash flow's behaviour, copy, or navigation.
- Any change to `wansa-admin-dashboard`, including its copies of the five edge
  functions this repo also carries.
- Any change to `get-transactions` — it already labels a row "HyperPay" when a
  `payment_transactions` row exists, which `verify-payment` writes.
- Rewriting historical `payment_method = 'wayl'` rows.

## Baseline caveat

A concurrent session was writing a *different* HyperPay arrangement into this
repo's edge functions on 2026-08-16 (dashboard→HyperPay, app→Wayl). It has since
stopped. Its work is preserved on two branches:

- `wip/hyperpay-dashboard-inflight-c1` (`d2fc7be`) — the complete final state,
  authored by that session; verified byte-identical to the working tree before it
  was cleaned.
- `wip/hyperpay-backend-inflight` (`3e0ffc3`) — a partial 13:43 snapshot, now
  redundant.

The working tree has been returned to a pristine `main @ 4842811`. §4 describes the
target state, not a diff against that work. Its `client === "dashboard"` gating and
every "mobile stays on Wayl" comment are dead per this design and should be deleted
rather than adapted. One piece is worth cherry-picking: `reversePayment()` /
`buildReverseParams()` (HyperPay RV), which the wensa `_shared/hyperpay.ts` never
had and §4a needs.

Restore `_shared/*` from **this repo's** history (`d03394f^`), not from the admin
repo — the two are not mirrors. The wensa copies are a superset carrying
`isPaid`/`markPaymentFailed`/`setCardScope`, and the wensa `cfg()` uses
`normalizeEnv()` where the admin copy does a bare `as HyperPayEnv` cast.

This spec cites two restore sources, `hyperpay-v1` (`afa3036`) and `d03394f^`
(`300de49`). **They are byte-identical across every path restored here** —
`lib/features/hyperpay_payment`, `test/features/hyperpay_payment`,
`supabase/functions/{verify-payment,charge-saved-card,_shared}`,
`SceneDelegate.swift`, and the Android kotlin tree. Either works; use `d03394f^`
so the restore reads as a direct inverse of the removal commit.

## 1. Payment method vocabulary

One migration, `supabase/migrations/20260816000001_hyperpay_payment_method.sql`,
widens the CHECK constraint on both tables:

```sql
payment_method IN ('wayl', 'cash', 'hyperpay')   -- was ('wayl', 'cash')
```

The column keeps `NOT NULL DEFAULT 'wayl'`. Existing rows are not touched: a
historical Wayl booking keeps saying `'wayl'` and stays truthful about which PSP
took the money.

`PaymentMethod` in `lib/features/booking/domain/models/booking_enums.dart` gains a
`hyperpay` case, and `PaymentMethodFromString` maps `'hyperpay'`. Its default stays
`wayl` — an unknown value must never be read as `cash`, because cash is the
"no money collected yet" state.

`PaymentMethodSelector`'s E-Payment row emits `PaymentMethod.hyperpay` instead of
`.wayl`. The widget is otherwise unchanged; its card icon is already
`Icons.credit_card_rounded`.

**No display code changes anywhere.** The app's `_paymentMethodLabel` and all 13
of the dashboard's `payment_method` references test `== cash` and bucket everything
else as "E-Payment". A third value flows through both correctly with no edits.

## 2. Flutter payment layer

### Restored verbatim from the tag

- `lib/features/hyperpay_payment/**` — 25 files. The folder is self-contained
  behind the `hyperpay_payment.dart` barrel and was deliberately built to depend on
  nothing but Flutter and itself, so it drops back in unchanged.
- `test/features/hyperpay_payment/**` — 5 files.

### Deleted

- `lib/features/wayl_payment/**` — 6 files.
- `lib/features/booking/presentation/pages/payment_webview_page.dart`.

### State shape

`BookingSubmitState.success` swaps its Wayl fields for HyperPay's and **keeps
`cash`**:

```dart
const factory BookingSubmitState.success({
  required String bookingId,
  required String checkoutId,   // was paymentUrl
  required String holdUntil,
  required String referenceId,  // was waylReferenceId
  required String paymentMode,  // new: "LIVE" | "TEST"
  @Default(false) bool cash,
}) = _Success;
```

Every `maybeWhen`/`success:` destructure is positional, so all call sites need an
arity update even where behaviour is unchanged.

### Call sites

Four paying flows swap `openPaymentWebView(...)` for `launchHyperpayPayment(...)`,
plus membership:

| File | Change |
|---|---|
| `sections/padel_section.dart` | local `openPaymentWebView` helper → `launchHyperpayPayment` |
| `sections/farm_section.dart` | same |
| `sections/concert_section.dart` | seat + GA flows; module-level `PaymentWebViewPage.push` at ~L69 |
| `sections/membership_section.dart` | module-level push at ~L95 |
| `sections/restaurant_section.dart` | **arity only** — a reservation request with no payment |

`launchHyperpayPayment` already owns the whole success/decline/cancel outcome
policy, so each section supplies only `onConfirmed` (call `verify-payment`, return
the post-dismiss navigation) and `onAborted` (release the hold). The existing
`goToCashBookingSuccess` branch is untouched in all of them.

The stranded-pending recovery guard changes from `paymentUrl.isNotEmpty || cash` to
`checkoutId.isNotEmpty || cash`.

### Router and profile

`RouteNames.savedCards`, the `/saved-cards` `GoRoute`, its `_redirect` allow-list
entry, and the `hyperpay_payment.dart` import all come back — the removal was a
clean 3-hunk diff. Profile's Payment section regains its "Saved Cards" row.

## 3. Native restore

Only one commit (`d03394f`) ever removed these, and Android has had no other commit
touch it since, so the restore is mechanical.

**iOS:** `ios/HyperpaySDK/**` (OPPWAMobile + ipworks3ds_sdk xcframeworks, 544
files), `ios/Runner/SceneDelegate.swift`, the `HyperpaySDK` pod line in `Podfile`,
`Podfile.lock`.

**Android:** `app/libs/{oppwa.mobile.aar,ipworks3ds_sdk.aar}`, the method-channel
handler in `MainActivity.kt`, `res/layout/async_payment_activity.xml`,
`WensaChallengeTheme` + `wensa_challenge_header`/`wensa_challenge_title` strings
(en + ar) and colors, viewBinding, the minSdk 24 floor, proguard rules, and the
mSDK dependency block.

**Care point.** `ios/Runner/AppDelegate.swift` gained 45 lines *after* the freeze
(commits `98534c2`, `adf83d6`) that swizzle away WKWebView's native form-navigation
toolbar. Restoring `SceneDelegate.swift` must not clobber them. Since those exist
only to fix the Wayl webview's chrome, check whether any WKWebView survives once
`wayl_payment/` is deleted; remove the swizzle only if none does, otherwise keep it.

## 4. Edge functions

| Function | Change |
|---|---|
| `create-booking` | Wayl link creation → `createCheckout` from restored `_shared/hyperpay.ts`. Returns `checkout_id` + `payment_mode`; writes `payment_method: 'hyperpay'`. |
| `create-membership` | Same treatment; returns `checkout_id` + `payment_mode` in place of `payment_url`. |
| `verify-payment` | **Restored from `d03394f^`** — kinds `booking \| concert_group \| membership`, writes `payment_transactions`, and carries the `rowEntityId()` 403 guard. See note below. |
| `charge-saved-card` | Restored + idempotency fix (§5). |
| `booking-action` | Three-way refund (§4a). |
| `get-transactions` | **No change.** |
| `_shared/hyperpay.ts` + `hyperpay_test.ts`, `payment_flow.ts`, `payments.ts` | Restored from tag. |
| `_shared/wayl.ts` | **Kept** (§4a). |

**`verify-payment` is the single biggest gap.** It was never restored by the
concurrent session (confirmed by that session directly — it judged an app-side
confirm path to be scope creep under its mobile-stays-Wayl premise). Without it the
HyperPay confirm path has no server side at all: the card would be charged and the
booking would never flip to confirmed. Recover it from `d03394f^`. The deployed
function is still ACTIVE at v19, so `supabase functions download verify-payment`
gives a second source to diff history against. `charge-saved-card` at `d03394f^` was
independently confirmed byte-identical to the deployed v17, so repo history is
trustworthy for these.

Untouched in `create-booking`/`create-membership`: the cash branch, the free-booking
path, the `client: "dashboard"` hint gate, promo/auto-discount resolution, commission
snapshotting, and all discount audit columns.

Checkout construction follows the frozen rules exactly — `merchantTransactionId` of
`booking-{id}` / `booking-venue-{group_id}`, dashes only, ≤32 chars, no timestamp;
integer IQD via `Math.round`, never `toFixed(2)`; no `customer.*`/`billing.*` blocks.
The local acquirer answers `800.100.156 "format error"` to any deviation.

### 4b. On capping `merchantTransactionId` — verified, no change needed

The concurrent session reported that this repo's `_shared/hyperpay.ts` never caps
`merchantTransactionId`, that the value passed is the 58-char, underscore-bearing
`referenceId`, and that consequently "every checkout would be declined at creation."
**The first half is true; the conclusion is not.** Verified against the tag:

- `_shared/hyperpay.ts` does pass `merchantTransactionId` through raw (L124) — no cap.
- But `create-booking` never passes `referenceId`. It passes
  `` `booking-${customParameter}` `` where `customParameter` is `rpcResult.id` /
  `rpcResult.group_id` — a **UUID**, and it applies `.slice(0, 32)` at the call site.
- `booking-{uuid}` is 44 chars → sliced to 32; UUIDs contain dashes, never
  underscores. The result is already compliant, and it is the exact form that passed
  UAT with this acquirer.

So the frozen path is correct as-is. Do **not** swap the call-site `.slice(0, 32)`
for a hash-suffixing `capMerchantTransactionId()` — that would change the value sent
to the gateway for every booking, which is precisely the class of change that needs
UAT first. Adding a defensive cap inside `_shared/hyperpay.ts` is acceptable only if
it is provably a no-op for already-compliant inputs.

### 4a. Refunds must stay two-gateway

`booking-action` today refunds *any* non-cash paid booking through `_shared/wayl.ts`,
keyed on the Wayl reference stored in `payment_id`. A HyperPay booking has no such
reference. The refund path therefore branches on `payment_method`:

- `cash` → cancel directly, no gateway call (existing behaviour)
- `wayl` → Wayl refund via `_shared/wayl.ts` (existing behaviour)
- `hyperpay` → RV reverse against `payment_transactions.unique_id`

**`_shared/wayl.ts` must not be deleted.** Every historical paid-by-Wayl booking
still inside its 60-minute refund window needs that path alive. "HyperPay replaces
Wayl" is true of the checkout surface only; removing the Wayl refund route would
strand real money.

## 5. Saved cards and the double-charge fix

Tokenization returns as frozen: `tokenize: true` on every checkout, the card
persisted only when `verify-payment` receives `save_card: true`, the save-card
checkbox, the one-tap sheet, and the profile → Saved Cards page. No migration is
needed — `user_payment_tokens` and the `lock_for_payment` RPCs are still applied.

The known bug is fixed. `charge-saved-card` currently randomises
`merchantTransactionId` (`mit-` + 28 uuid-hex chars) per call, which defeats the DB
unique index, so two fast taps can charge a real card twice. It becomes
**deterministic per entity** — derived from the entity kind and id, dashes only,
≤32 chars — so concurrent calls collide on the index and the second is rejected
before any money moves.

**UAT item:** confirm a *declined* attempt can be retried under a stable id. If the
acquirer rejects reuse after a decline, append a bounded attempt counter derived
from persisted `payment_transactions` rows — never a random value, which is what
caused the bug.

## 6. Verification

- Restore the 5 tag test files; update for the new `success` arity.
- `test/.../payment_method_selector_test.dart` (124 lines) must stay green through
  the enum change.
- `flutter analyze` and `flutter test` clean.
- `deno test` on the restored `_shared/hyperpay_test.ts` (441 lines).
- Build both platforms — the native restore is the highest-risk part and a
  successful `flutter build ios` / `flutter build apk` is the only real proof.

## 7. Cutover — user-owned

Implementation stops at the deploy line. The user then:

1. Applies migration `20260816000001`.
2. Deploys `create-booking`, `create-membership`, `verify-payment`,
   `charge-saved-card`.
3. Confirms secrets. Verified live on 2026-08-16 (SHA-256 match against the secrets
   listing, not assumed): `HYPERPAY_ENV` is literally `"test"`, `WAYL_ENV` is
   `"test"`, and **`HYPERPAY_BASE` is explicitly set** and overrides base selection
   by env. So the "unset base defaults by env" hazard from the freeze notes is
   already closed — but re-confirm before flipping `HYPERPAY_ENV` to `live`, since
   that is the switch that makes base selection matter.
4. Confirms **0 pending Wayl bookings** at cutover — in-flight ones die at the
   switch.
5. Runs the on-device E2E: book in each section, confirm a native card form opens
   (not a webview), pay, confirm auto-confirmation without manual refresh; then
   save a card and pay one-tap; then verify the dashboard shows the new rows and
   that the 87 historical HyperPay transaction rows still render.

## Risks

| Risk | Mitigation |
|---|---|
| Backend deploys instantly; the app ships through review | Old app builds keep calling for `payment_url` and will break. Sequence the deploy against a store release, or keep a Wayl fallback branch alive server-side until adoption is high. **Needs a decision before deploy.** |
| Native restore breaks the build | Build both platforms before merge; the SDK is vendored so no network resolution is involved. |
| Refund regression on historical Wayl rows | §4a keeps the Wayl path; cover it with a test that a `payment_method='wayl'` row still routes to `refundPayment`. |
| The dashboard's diverged copies of the 5 shared functions | Out of scope, but a deploy from the dashboard repo would revert this work. Flag to the user; do not deploy from there. |
| Dashboard booking modal breaks if `checkout_id` is absent | Its `CreateBookingModal` keys off `res.checkout_id` and silently closes without collecting payment when it is missing. Returning `checkout_id` *unconditionally* (rather than only for `client:"dashboard"`) is compatible with the dashboard as it now stands — but the cash branch must keep returning `cash: true` with no `checkout_id`, so verify the dashboard never reaches that branch. |
| `HYPERPAY_ENV=live` silently picks the TEST base on the dashboard side | Latent, not triggered today (env is `"test"`). The admin repo's `cfg()` casts without normalising while this repo's uses `normalizeEnv()`. Worth fixing in the dashboard before go-live — out of scope here, but it will bite at the same moment this does. |

## Open items

- The app-version-skew question in Risks has no answer yet and blocks the deploy
  step, not the implementation.
- Whether the AppDelegate WKWebView swizzle survives (§3) is decided during
  implementation by grepping for surviving WKWebView users.
