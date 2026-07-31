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
