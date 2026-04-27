-- ============================================================
-- Migration: Booking schema — pg_cron scheduled jobs
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- All jobs use the 'postgres' role (pg_cron default).
-- Job names are prefixed with 'bookings_' to avoid collisions.
-- ============================================================

-- Remove any previous versions of these jobs (idempotent)
SELECT cron.unschedule(jobname)
FROM cron.job
WHERE jobname IN (
  'bookings_expire_holds',
  'bookings_complete_confirmed',
  'bookings_expire_restaurant',
  'bookings_expire_memberships'
);

-- ── Every 30 seconds: expire seat holds + unpaid pending bookings ─────────────
SELECT cron.schedule(
  'bookings_expire_holds',
  '30 seconds',
  $$
    -- Release expired concert seat holds
    DELETE FROM bookings.event_seat_holds
    WHERE expires_at < now();

    -- Expire pending bookings whose hold window passed without payment
    UPDATE bookings.bookings
    SET status = 'expired'
    WHERE status = 'pending'
      AND payment_status <> 'paid'
      AND hold_until < now();
  $$
);

-- ── Every minute: confirmed → completed when end time has passed ──────────────
SELECT cron.schedule(
  'bookings_complete_confirmed',
  '* * * * *',
  $$
    UPDATE bookings.bookings
    SET status = 'completed'
    WHERE status = 'confirmed'
      AND ends_at < now();
  $$
);

-- ── Every minute: restaurant pending → expired when slot passed without confirm
SELECT cron.schedule(
  'bookings_expire_restaurant',
  '* * * * *',
  $$
    UPDATE bookings.bookings
    SET status = 'expired'
    WHERE category = 'restaurant'
      AND status = 'pending'
      AND starts_at < now();
  $$
);

-- ── Daily at midnight Baghdad time (UTC+3 → 21:00 UTC): expire memberships ────
SELECT cron.schedule(
  'bookings_expire_memberships',
  '0 21 * * *',
  $$
    UPDATE bookings.memberships
    SET status = 'expired'
    WHERE status = 'active'
      AND ends_at < current_date;
  $$
);
