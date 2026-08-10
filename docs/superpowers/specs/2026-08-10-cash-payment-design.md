# Cash Payment Design

Date: 2026-08-10

## Goal

Add "pay with cash" as a second payment method alongside the existing Wayl
e-payment flow, across all booking types (sports, farm, restaurant, concert,
membership). Merchants can turn cash on/off (default on). The admin and
merchant dashboards can tell cash and e-payment apart everywhere money is
shown, and can see which method is used more.

## Non-goals

- No settlement/reconciliation workflow (no "mark as settled" action, no
  settlement batches). This is visibility only — statistics and per-record
  labeling. A settlement workflow can be layered on top later if needed.
- No per-place/venue granularity for the toggle — one switch per merchant.
- No changes to the Wayl e-payment flow itself; it stays exactly as it works
  today. Cash is purely an additional path.

## 1. Data model

### `business.merchants`

Add:

```sql
ALTER TABLE business.merchants
  ADD COLUMN cash_enabled boolean NOT NULL DEFAULT true;
```

Same shape as the existing `dashboard_payment_required` toggle.

### `bookings.bookings` and `bookings.memberships`

Add:

```sql
ALTER TABLE bookings.bookings
  ADD COLUMN payment_method text NOT NULL DEFAULT 'wayl'
    CHECK (payment_method IN ('wayl', 'cash'));

ALTER TABLE bookings.memberships
  ADD COLUMN payment_method text NOT NULL DEFAULT 'wayl'
    CHECK (payment_method IN ('wayl', 'cash'));
```

Existing rows backfill to `'wayl'` via the column default — accurate, since
Wayl is the only method that has ever existed.

`payment_status` is left as-is (`pending | paid | failed | free | refunded |
cancelled`, per the live `CHECK` constraint). Cash bookings use
`payment_status = 'paid'` — the money did change hands, just directly to the
merchant instead of through the gateway. This keeps cash bookings correctly
included in existing revenue totals wherever they're computed from
`payment_status = 'paid'`. `payment_status = 'free'` is reserved for genuinely
comped bookings (the existing `dashboard_payment_required` path) and is not
reused for cash.

`payment_method` is the sole discriminator dashboards use to split cash vs
e-payment.

## 2. Backend: `create-booking` / `create-membership`

Both edge functions accept a new body field: `payment_method: 'wayl' | 'cash'`
(default `'wayl'` if omitted, for backward compatibility with any caller that
doesn't send it yet).

When `payment_method === 'cash'`:

1. Look up `cash_enabled` for the booking's merchant (same query pattern as
   the existing `dashboardPaymentRequired` helper). If `cash_enabled` is
   `false`, return a 4xx error (e.g. `{ error: "cash_disabled" }`) instead of
   silently falling back — the app is expected to not offer Cash as an option
   when the merchant has it off, so this is a defensive check, not the
   primary UX guard.
2. Skip the Wayl link creation entirely (no `POST /api/v1/links` call).
3. `PATCH` the freshly-created booking/membership row directly to:
   `status: 'confirmed'`, `payment_status: 'paid'`, `payment_method: 'cash'`,
   `hold_until: NULL`. Same shape as the existing free/dashboard-booking
   branch, so it automatically sits outside the 60s hold/auto-expire cron
   (which only touches rows still in `status = 'pending'`).
4. Return `{ booking_id, payment_url: null, cash: true }` (no `hold_until`,
   no `reference_id`, since there's no Wayl link).

When `payment_method === 'wayl'` (or omitted): unchanged — existing Wayl link
flow runs exactly as today, with `payment_method: 'wayl'` written on the
initial insert (via the RPCs' default) so the column is always populated.

Concert group bookings: same branch applies at whatever point group bookings
currently call into the shared paid/free logic — cash groups confirm
immediately, same as a cash single booking.

### Cancellation / refunds

Cash bookings never touch `wayl-refund` (there's no gateway transaction to
reverse). Cancelling a cash booking is a plain status update to `cancelled`,
same code path as cancelling a free/comped booking today. No new function
needed — this falls out of the existing cancel path once `payment_method`
distinguishes cash from Wayl rows, so cancel logic can skip the
gateway-refund call for `payment_method = 'cash'`.

## 3. Mobile app (Flutter)

### New enum

```dart
enum PaymentMethod { wayl, cash }
```

Added alongside `BookingCategory`/`BookingStatus` in `booking_enums.dart`.

### Payment method selection UI

A new step shown as the final screen/sheet before submitting any booking
(all categories, plus membership purchase) — visual style per the provided
reference screenshot: white rounded card, "Payment Method" header, radio rows
with a colored icon badge, label, and one-line subtext.

- **Cash** row: green `$` badge, "Cash", "Pay at the venue".
- **E-Payment** row: existing Wayl branding, "Pay online now".

If the merchant has `cash_enabled = false`, the Cash row is omitted entirely
(not shown disabled) — the merchant's places simply present E-Payment as the
only option, same as today's behavior.

### Submission flow

`BookingSubmit` / `MembershipSubmit` providers gain a `paymentMethod`
parameter, sent through to `create-booking` / `create-membership`.

Response handling:

- `payment_url` present → existing behavior, unchanged: open
  `WaylWebViewScreen`, confirm on success via `confirm_payment` RPC, navigate
  to `/bookings/$bookingId`.
- `cash: true` in the response (no `payment_url`) → skip the webview
  entirely, navigate straight to `/bookings/$bookingId`. The booking is
  already `confirmed`/`paid` server-side by the time the app gets the
  response, so no client-side confirmation call is needed.

No changes needed to the ticket page — it already renders `pending`/
`confirmed` status badges and treats `waylCode` as optional, so a cash
booking (no Wayl code) displays correctly without modification.

## 4. Dashboard (admin + merchant)

### Toggle

- **Merchant side** (`src/features/merchant/ProfilePage.tsx`): new `Switch`,
  "Accept cash payments" (default on), writing `cash_enabled` on the
  logged-in merchant's own row — same `getApi().update("merchants", id,
  {...})` pattern as the existing `dashboard_payment_required` switch.
- **Admin side** (`src/features/merchants/MerchantsPage.tsx`): read-only
  indicator (label + colored dot) showing the merchant's current
  `cash_enabled` value next to the existing `dashboard_payment_required`
  switch. No admin-side control — this toggle is merchant-owned.

### Bookings tables

Both `src/features/bookings/BookingsPage.tsx` (admin) and
`src/features/merchant/MyBookingsPage.tsx` (merchant) get a new "Payment"
column/badge next to Amount: a small colored pill, "Cash" or "Wayl", read
from the new `payment_method` column. Same treatment in each page's detail
modal.

### Transactions page

`src/features/transactions/TransactionsPage.tsx` gets a segmented control at
the top: **E-Payment** / **Cash**.

- **E-Payment tab**: today's page, unchanged — `get-transactions` webhook
  log, gateway fields, refund/reverse actions.
- **Cash tab**: new, simpler table queried directly from `bookings` /
  `memberships` where `payment_method = 'cash'` (no edge function needed,
  same direct-table-query pattern `BookingsPage` already uses). Columns:
  booking id, customer, place/event, amount, merchant (admin view only),
  date. No gateway fields (none exist for cash). Row action is "Cancel
  booking" (plain status cancel) instead of "Refund"/"Reverse".
- The existing summary bar (Total Received / Refunded / Net / Platform
  Profit) is scoped to whichever tab is active, so admins can see e-payment
  and cash totals separately as well as compare them.

### Dashboard stats

Both `src/features/dashboard/DashboardPage.tsx` (platform-wide) and
`src/features/merchant/DashboardPage.tsx` (merchant-scoped) get a new "Cash
vs E-Payment" `DonutChart` (two slices, booking count or revenue — revenue,
to match what the existing summary bars already emphasize), placed alongside
the existing charts, respecting the existing today/7d/30d period picker.
Small numeric callouts (cash revenue, e-payment revenue) sit next to the
donut, mirroring the existing `BookingAnalyticsSection` numbers row.

This directly answers "which is working more" — no new backend endpoint
needed beyond aggregating `bookings`/`memberships` by `payment_method` over
the selected period, same tables the existing analytics section already
queries.

## 5. Testing

- Backend: unit/integration coverage on `create-booking`/`create-membership`
  for: cash with `cash_enabled=true` (confirms immediately, no Wayl call);
  cash with `cash_enabled=false` (rejected); Wayl path unchanged; cron never
  touches a confirmed cash booking.
- App: manual pass through booking flow for one category (e.g. padel/sports)
  and membership purchase, both payment methods, confirming ticket page
  renders correctly for cash (no Wayl code, correct status) and Wayl flow is
  untouched.
- Dashboard: manual check of toggle (merchant on/off, admin visibility),
  Bookings table badge, Transactions tab split, Dashboard donut, on both
  admin and merchant views.
