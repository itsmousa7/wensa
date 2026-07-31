# Restoring Wayl as the primary PSP (app repo)

**Date:** 2026-07-31
**Repos:** `wensa` (Flutter app) — primary; `wansa-admin-dashboard` — one surgical edit
**Supabase project:** `qvozjwlkzordudkhamcu` (wain_flosi)

## Goal

Wayl is the sole payment service provider again, on the current codebase — not by
rewinding to `main`. Every non-payment improvement made during the HyperPay era
is kept. HyperPay survives as a pushed branch plus an annotated tag, with nothing
left in the app's build path.

## Current state

**Dashboard — already done.** A parallel session restored Wayl on
`feature/wayl-restore` @ `c3cdac5` (2026-07-31 12:48), one commit on top of
`feature/hyperpay-gateway` @ `672a0f7`. Tag `hyperpay-v1` is pushed to origin;
the branch is not pushed yet. `docs/hyperpay-restore.md` documents the frozen
HyperPay surface. That work is **not redone here**.

**App — untouched.** `feature/hyperpay-migration` @ `afa3036`, 26 commits ahead
of `main`, no tags. HyperPay is fully wired: 25 Dart files under
`lib/features/hyperpay_payment/`, 5 test files, 4 `_shared` edge modules, two
edge functions, and ~553k lines of vendored iOS/Android SDK binaries.

**Live.** `create-booking` v58 (HyperPay) deployed 2026-07-24. The Wayl rails
were never dismantled — `wayl-webhook`, `booking-wayl-webhook`, and `wayl-refund`
are all still ACTIVE. `bookings.wayl_code` and `memberships.wayl_code` still
exist on both tables. Volume is pre-launch: 1 saved card, 87
`payment_transactions` rows, **0 pending bookings**.

## Decisions

| # | Decision | Chosen |
|---|---|---|
| 1 | Non-payment branch work | Keep it — surgical payment-only revert |
| 2 | HyperPay backup (app) | Delete from tree; preserve via branch + tag |
| 3 | Cutover | Restore code **and** redeploy edge functions |
| 4 | App payment UI | Full revert to the Wayl webview |
| 5 | Dashboard | Surgical revert — already done by parallel session |
| 6 | Merchant plan/banner payments | Moot: already on Wayl since `525c17f` |
| 7 | Mechanism | Restore-from-`main`, one clean commit per repo |
| 8 | `create-booking` source of truth | One unified file, written into both repos |

Decision 8 was originally "use the dashboard's Wayl copy as the base". Diffing
the two Wayl copies during planning showed that would regress a fix, so the base
is inverted — see below. The outcome is unchanged: one authoritative file, no
drift.

Decision 2 deliberately diverges from the dashboard's freeze-in-tree convention.
The dashboard froze a handful of TypeScript modules; the app would freeze ~553k
lines of vendored `OPPWAMobile.xcframework` and `ipworks3ds_sdk` binaries, which
bloats every clone and Xcode build. The asymmetry is recorded in the restore doc.

## The `create-booking` defect

`create-booking` exists in **both** repos and deploys to the same Supabase
function. Three copies are in play and **none** is currently correct:

| Copy | Wayl | `f3f10c3` client-hint gate | event-discount guard | `callRpc` typed |
|---|---|---|---|---|
| app `HEAD`, 964 lines | no — HyperPay | yes | yes | no |
| app `main`, 952 lines | yes | no | **yes** | no |
| dashboard `feature/wayl-restore`, 933 lines | yes | no | **no** | yes |

**Defect 1 — the client-hint gate.** The dashboard's `CreateBookingModal.tsx:212`
sends `client: "dashboard"`, but its `create-booking` — restored wholesale as a
933-line new file by `3f328af` — has no `isDashboardBooking` gate to consume it.
Deploying it as-is reintroduces the bug `f3f10c3` fixed: a merchant booking at
their own venue *from the mobile app*, with their payment toggle off, takes the
free-booking path — the slot is held and no `payment_url` is returned, so the app
errors on a booking that already exists.

**Defect 2 — the event-discount guard.** `3f328af` restored from a snapshot
predating `main`'s `isEventCategory()` guard. Without it, an app-wide auto
discount (`applies_to: 'bookings'`) bleeds onto venue-seat and general-admission
tickets, which are never supposed to be discounted.

**Resolution.** Base on **`main`'s** copy — the only one with the event-discount
guard — then add the `f3f10c3` gate and the dashboard's `callRpc` typing
improvement. That is the union of all three fixes. Write the identical file into
both repos.

The gate is three renames plus one added condition:

```ts
client?: "dashboard";                       // on the request body type
const hasDashboardRole   = callerRole === "admin" || ...;
const isDashboardBooking = hasDashboardRole && body.client === "dashboard";
const source             = isDashboardBooking ? callerRole : "mobile_app";
if (isDashboardBooking && !(await dashboardPaymentRequired(...))) { ... }
```

## App repo changes — one commit on `feature/hyperpay-migration`

### Restore from `main` verbatim (7 files)

- `lib/features/wayl_payment/config/wayl_config.dart`
- `lib/features/wayl_payment/data/models/wayl_line_item.dart`
- `lib/features/wayl_payment/data/models/wayl_link_request.dart`
- `lib/features/wayl_payment/data/models/wayl_link_response.dart`
- `lib/features/wayl_payment/data/services/wayl_api_service.dart`
- `lib/features/wayl_payment/presentation/screens/wayl_webview_screen.dart`
- `lib/features/booking/presentation/pages/payment_webview_page.dart`

### Restore from `main` (payment-only content, verified)

Every commit that ever touched the booking sections is a payments commit
(`d0130a9`, `e5fe7cb`, `c9170ae`), so restoring them wholesale loses no
non-payment work:

- `sections/{concert,farm,padel,membership,restaurant}_section.dart` — back to
  `PaymentWebViewPage.push(...)` with `paymentUrl` + `waylReferenceId`
- `providers/booking_submit_provider.dart` + `.freezed.dart` + `.g.dart`
- `providers/membership_submit_provider.dart` + `.g.dart`
- `domain/models/booking.dart`, `membership.dart` (+ generated) — `waylCode`
  restored; the DB columns still exist, so no migration is needed
- `lib/features/profile/presentation/widgets/profile_content.dart` — drops the
  Saved Cards tile and its Payment section
- `lib/core/router/router_provider.dart` — drops the HyperPay import and route

### Write the unified `create-booking`

`supabase/functions/create-booking/index.ts` — `main`'s Wayl base, plus the
`f3f10c3` gate and the `callRpc: Promise<Record<string, unknown>>` typing,
byte-identical in both repos.

### Delete

- `lib/features/hyperpay_payment/**` — 25 files
- `test/features/hyperpay_payment/**` — 5 files
- `supabase/functions/verify-payment/`, `supabase/functions/charge-saved-card/`
- `supabase/functions/_shared/{hyperpay.ts,hyperpay_test.ts,payment_flow.ts,payments.ts}`
- iOS: `ios/HyperpaySDK/**` (544 files), `ios/Runner/SceneDelegate.swift`,
  Podfile + Podfile.lock entries
- Android: `app/libs/{oppwa.mobile.aar,ipworks3ds_sdk.aar}`, the channel handler
  in `MainActivity.kt`, `res/layout/async_payment_activity.xml`, and the
  HyperPay-only hunks of `build.gradle.kts`, `proguard-rules.pro`,
  `AndroidManifest.xml`, `values*/strings.xml`, `colors.xml`, `styles.xml`

### Keep

Migrations `20260716000001/2/3` stay applied and in place. Dropping
`bookings.user_payment_tokens` would only make a future return to HyperPay
harder, and `payment_transactions` still backs the dashboard's 87 historical rows.

### Two hand-checks

- `lib/features/bottom_bar/widgets/ios_nav_shell.dart` — `ff2f968` is a mixed
  commit; its small-iPhone bottom-bar hunk must survive.
- `ios/Runner/SceneDelegate.swift` — added by HyperPay commits only, but confirm
  nothing outside HyperPay references it, and that `Info.plist` /
  `project.pbxproj` don't register it, before deleting.

## Cutover

Prerequisite, blocking: confirm `WAYL_API_KEY`, `WAYL_WEBHOOK_SECRET`,
`WAYL_WEBHOOK_URL` / `WAYL_BOOKING_WEBHOOK_URL`, `WAYL_ENV`, and
`APP_DEEP_LINK_BASE` are set in Supabase secrets. Values aren't readable over
MCP; verify presence and stop if any is missing.

Deploy order — no window where a checkout is issued against a function that
can't confirm it:

1. `create-booking` — the unified file written in this work
2. `create-membership` — deployed from the dashboard repo's `feature/wayl-restore`, already restored, no code change here
3. `booking-action` — likewise; carries the `_shared/wayl.ts` `refundPayment()` path

`wayl-webhook`, `booking-wayl-webhook`, and `wayl-refund` are already ACTIVE and
need no redeploy. The `hyperpay-*` functions stay deployed but unused —
`get-payment-transaction` still serves the historical rows. With 0 pending
bookings, the window is clean.

## Backup

- Annotated tag `hyperpay-v1` on `afa3036` in the app repo, pushed to origin —
  mirroring the dashboard's tag of the same name.
- `origin/feature/hyperpay-migration` left untouched; never force-push it.
- `docs/hyperpay-restore.md` in the app repo: what the tag holds, which env vars
  and native SDKs it needs, and the note that the app deletes what the dashboard
  froze.

## Verification

- `flutter analyze` clean; `flutter test` green (HyperPay tests go with the feature)
- `deno check` on each changed edge function
- Grep gate: no `hyperpay` / `checkout_id` / `HYPERPAY_` outside `docs/`
- End-to-end on a real device — the definition of done:
  book → Wayl webview → pay → webhook confirms → booking reads confirmed in the
  app **and** the Wayl Ref appears in the dashboard's bookings and transactions
  sections. Merge is gated on this.

## Risks

- **Parallel session in the dashboard repo.** `feature/wayl-restore` appeared
  mid-session. Re-check `git status` and HEAD there immediately before the
  `create-booking` edit, and make no other change in that repo.
- **`feature/wayl-restore` is unpushed.** A single local branch holds the whole
  dashboard restore. Push it before relying on it.
- **iOS build after pod removal** needs a clean `pod install`; a stale
  `Podfile.lock` referencing `HyperpaySDK` will fail the build.

## Out of scope

- Dashboard restore beyond the `create-booking` gate — already done
- Merchant plan/banner payments — already on Wayl
- Dropping HyperPay tables or deleting `hyperpay-*` edge functions
- Merging either branch to `main`
