# Booking reversal → cancellation design

> **Revised 2026-08-07, same day.** The original version of this spec (below
> this notice, for history) assumed no reversal/cancellation handling existed
> anywhere in the codebase, and designed a new `payment_status = 'reversed'`
> value, a new `reverse_booking` RPC, a new DB column, and cron-based
> notification delivery. That assumption was **wrong**: while auditing the
> live Supabase project it turned out a complete pipeline already exists in
> production, in edge functions that were never pulled into this git
> repository (`booking-action`, `booking-notification`,
> `booking-wayl-webhook`, `wayl-refund`, and others — none of these appear
> anywhere in `supabase/functions/` locally; only `create-booking` and
> `process-notifications` do). This revision describes what's actually there
> and the small, real gap.

## What already exists (live, in production)

- **`booking-action`** (verify_jwt, admin/merchant-only): cancelling a paid
  booking calls Wayl's refund API, then
  `PATCH bookings SET status='cancelled', payment_status='refunded'`. It
  never deletes a row. A free/unpaid booking is cancelled the same way, with
  `payment_status='cancelled'` instead.
- **`booking-notification`** (fired by a DB trigger on `bookings.bookings`
  status changes, `pg_net`-based — the trigger itself isn't in any local
  migration file either): on `new_status === 'cancelled'`, sends a bilingual
  FCM push and writes to `profiles.user_notifications`, deduped on
  `(user_id, kind, data.booking_id)`. Title is already **"Booking Cancelled" /
  "تم إلغاء الحجز"**. Body is generic: *"Your booking has been cancelled.
  Contact us if you have questions."* / *"للأسف تم إلغاء حجزك. تواصل معنا إن
  كان لديك استفسار."* — or, when `payment_status === 'refunded'` (the
  `isRefund` branch, `kind: 'booking_refund'`), a refund-amount-aware body via
  `getRefundCopy()`: *"Your booking at {place} was cancelled and {amount} IQD
  was returned to your account."*
- **Booking history UI** (`ticket_status_badge.dart`, already in this repo):
  renders `BookingStatus.cancelled` as a red "Cancelled"/"ملغى" badge — no
  changes needed, confirmed unchanged from the original spec.

So two of the three original requirements are already met: bookings are never
deleted on reversal, and a "Booking Cancelled" notification already fires.

## The actual gap

Neither `getCopy()`'s `'cancelled'` branch nor `getRefundCopy()` (both in the
live `booking-notification/index.ts`) tell the user to book again, and
neither varies by booking category. That's the only missing piece.

## Scope of the fix

Edit the two copy-producing functions in `booking-notification/index.ts`
(pulled into this repo at `supabase/functions/booking-notification/index.ts`
as part of this change, since it doesn't exist locally yet) so the body ends
with a category-aware call to action:

- `padel`, `football` (hourly courts) → append "Book another hour!" /
  "احجز ساعة أخرى!"
- `farm`, `restaurant`, `concert` (date/shift-based) → append "Book another
  day!" / "احجز يومًا آخر!"

Both the plain-cancellation body (`getCopy`) and the refund body
(`getRefundCopy`) get this treatment, since a payment reversal is exactly the
`isRefund` path (`payment_status === 'refunded'`) — "reversed" in the user's
original request maps to this existing refund flow; there is no separate
`'reversed'` state anywhere in the schema, live or local.

`getRefundCopy()` currently only receives `placeName` and `amountIqd` — it
needs the booking's `category` threaded in too, exactly like `getCopy()`
already receives it.

## Out of scope

- No DB schema changes (no new column, no new enum value, no new RPC) — the
  existing `status`/`payment_status` values and the existing trigger cover
  everything needed.
- No changes to `booking-action`, the DB trigger, `booking-wayl-webhook`, or
  any other function in the pipeline — only the copy inside
  `booking-notification`.
- No attempt to reconcile the broader drift between this git repo and the
  live project (the dozen-plus other untracked edge functions) — out of
  scope for this task.

## Testing

`booking-notification` has no local test harness (it isn't even in the repo
today). Verification is: read the deployed function's source after
`deploy_edge_function` to confirm the new copy is present
(`pg`-style text is not applicable here; use `get_edge_function` and check
the returned source), then trigger a real cancellation against a disposable
test booking (via `booking-action` or a direct status-change on a throwaway
row) and confirm the push/inbox body includes the right CTA for both an
hourly and a date-based category, in both languages.

---

## Original spec (superseded, kept for history)

<details>
<summary>Click to expand the original (incorrect-premise) design</summary>

### Problem

When a booking's payment is reversed, there is currently no handling for it
anywhere in the codebase: `bookings.bookings.payment_status` only allows
`pending | paid | failed`, and no reversal/webhook path exists (only
`create-booking`, which issues Wayl payment links, and `process-notifications`,
the reminder/broadcast cron, exist as edge functions).

*(This premise was wrong — see the revision notice above. The rest of the
original spec, which built a `reverse_booking` RPC, a new
`payment_status = 'reversed'` value, and cron-based notification delivery, is
omitted here since none of it should be built.)*

</details>
