# Booking reversal → cancellation design

## Problem

When a booking's payment is reversed, there is currently no handling for it
anywhere in the codebase: `bookings.bookings.payment_status` only allows
`pending | paid | failed`, and no reversal/webhook path exists (only
`create-booking`, which issues Wayl payment links, and `process-notifications`,
the reminder/broadcast cron, exist as edge functions). The requirement is that
a reversed booking must never be deleted — it should show as **Cancelled** in
the user's booking history (same as any other cancelled booking), and the user
should get a notification telling them the booking was cancelled and inviting
them to book again, worded for the booking's type (an hour for court sports,
a day for date/shift-based bookings).

## Scope

This spec covers only the `bookings.bookings` table (padel/football/farm/
restaurant/concert). Memberships are a separate table/flow and are out of
scope — nothing about "book another day/hour" applies to a membership renewal.

Out of scope (explicitly deferred, per the "simplest approach" the user chose):
- Building a Wayl (or any) webhook receiver that detects reversals
  automatically. Nothing in this repo currently receives that signal from
  Wayl, and wiring a real webhook is a separate piece of work.
- Any admin-portal UI button to trigger a reversal. For now the action is
  invoked directly (SQL editor / service-role call) by whoever discovers the
  reversal.

The deliverable here is the *handling* once a reversal is known: the DB
function that marks the booking, and the user-facing effects (history display,
notification) that follow from it.

## Data model changes

**`bookings.bookings`** (migration, extending
`20260427000003_bookings_main_table.sql`'s constraint):
- `payment_status` check constraint gains `'reversed'` →
  `CHECK (payment_status IN ('pending', 'paid', 'failed', 'reversed'))`.
- New column `cancellation_notified_at timestamptz NULL` — mirrors the
  existing `reminder_sent_at` claim-column used by the reminder cron, so the
  "your booking was cancelled" push fires exactly once per booking.

**`profiles.user_notifications`** (extending
`20260601000004_user_notifications.sql`'s `kind` check constraint):
- Add `'booking_cancelled'` to the allowed `kind` values.

No change to `bookings.booking_status` — `'cancelled'` already exists and is
already fully handled by the booking-history UI (see below), so a reversed
booking becomes indistinguishable from any other cancelled booking in the UI.
`payment_status = 'reversed'` is the only marker of *why* it was cancelled,
kept for bookkeeping/finance and to let the notification cron find exactly
these bookings.

## `bookings.reverse_booking` RPC

New SQL function, same file family as `cancel_booking`
(`bookings_rpcs.sql` conventions):

```sql
CREATE OR REPLACE FUNCTION bookings.reverse_booking(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, auth, public
AS $$
DECLARE
  v_booking bookings.bookings%ROWTYPE;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_booking FROM bookings.bookings WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_booking.status = 'cancelled' THEN
    RETURN; -- idempotent no-op, matches confirm_payment's style
  END IF;

  UPDATE bookings.bookings
  SET status = 'cancelled', payment_status = 'reversed'
  WHERE id = p_id;

  IF v_booking.category = 'concert' AND v_booking.group_id IS NOT NULL THEN
    DELETE FROM bookings.event_seat_holds WHERE group_id = v_booking.group_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.reverse_booking(p_id uuid)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = bookings, public
AS $$ SELECT bookings.reverse_booking(p_id); $$;
```

- Restricted to admins via `public.is_admin()` (the existing pattern used by
  `cancel_booking`), rather than a bare service-role carve-out — reuses the
  established convention instead of inventing a new one. Concretely,
  `is_admin()` checks `admin.admin_roles` against `auth.uid()`, which is
  `NULL` for a bare service-role call with no user JWT — so this must be
  called by an authenticated admin (e.g. from the merchant/admin portal with
  their own session), not by an unattended service-role script. That's
  intentional for the "manual admin action" scope of this spec.
- Idempotent: calling it twice on an already-cancelled booking is a silent
  no-op, matching `confirm_payment`'s style.
- Mirrors `cancel_booking`'s seat-hold cleanup for concerts.
- No `hold_until`/pending-specific logic needed since a reversal only makes
  sense on an already-paid (`confirmed`) booking.

## Notification delivery

Rather than adding a new event-driven push path (which would duplicate the
FCM/localization plumbing that already exists), this reuses the existing
`process-notifications` cron exactly the way membership-expiry reminders do:
poll for due rows, claim, send, record.

New section in `supabase/functions/process-notifications/index.ts`, after the
existing broadcast section:

- Query: `bookings.bookings` where `payment_status = 'reversed' AND
  cancellation_notified_at IS NULL`.
- Claim: same conditional-`UPDATE ... WHERE cancellation_notified_at IS NULL`
  pattern as `claimReminder`, to stay safe under concurrent cron ticks.
- Wording:
  - Title (en/ar): `"Booking Cancelled"` / `"تم إلغاء الحجز"`.
  - Body depends on `category`:
    - `padel`, `football` (hourly courts) → `"Book another hour"` /
      `"احجز ساعة أخرى"`.
    - `farm`, `restaurant`, `concert` (date/shift-based) → `"Book another
      day"` / `"احجز يومًا آخر"`.
  - Title gets the place/event name appended via the existing
    `titleWithName` helper, same as reminders do.
- Sends via the existing `sendToTokens` (push, per-device locale, stale-token
  pruning) and inserts one row into `profiles.user_notifications` with
  `kind: 'booking_cancelled'`, `data: { booking_id }`.
- Latency: up to one cron tick behind the `reverse_booking` call (the cron
  interval is whatever `process-notifications` already runs on — this spec
  doesn't change that cadence). Acceptable for a cancellation notice.

## Booking history UI

No changes. `TicketStatusBadge` already renders `BookingStatus.cancelled` as
a red "Cancelled" / "ملغى" badge (`ticket_status_badge.dart`), and the
bookings-history queries already include cancelled bookings — a reversed
booking becomes a normal cancelled booking to every existing UI code path.

## Testing

- Neither `cancel_booking` nor `confirm_payment` — the two closest existing
  RPCs — have SQL tests today; `supabase/tests/` holds a single unrelated
  suite (`plans_quotas.sql`), written as manual `RAISE`-assertion `DO` blocks
  rather than pgTAP. `reverse_booking` will follow that same precedent: a new
  `supabase/tests/reverse_booking.sql` covering non-admin rejection, unknown
  id (`P0002`), the happy path (`status`/`payment_status` flip), idempotent
  re-call, and concert seat-hold release.
- `process-notifications`: no existing test harness for the Deno function in
  this repo (the reminder/membership/broadcast sections it already has are
  unverified by automated tests too), so the new section will be verified
  manually against a seeded `reversed` booking after deploy — consistent with
  how the rest of that function is validated today.
- No Flutter-side changes, so no new widget tests — existing
  `bookings_history_page_tabs_test.dart` coverage of the cancelled state
  already applies.
