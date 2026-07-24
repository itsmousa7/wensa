-- ============================================================
-- Migration: repair the process-notifications cron invocation
-- Date: 2026-07-24
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- Bug: the every-minute job POSTed to the edge function with no
-- Authorization header. The function is deployed with
-- verify_jwt = true, so the gateway rejected every call with
-- 401 UNAUTHORIZED_NO_AUTH_HEADER and the function body never
-- ran — no booking / membership reminders since 2026-06-17
-- (see net._http_response for the 401 trail).
--
-- Fix: send the project's anon key as the bearer token, the same
-- credential the mobile app uses. It is a public key (it ships
-- inside the app bundle), so storing it here leaks nothing, and
-- keeping verify_jwt = true means the endpoint stays closed to
-- fully anonymous callers.
--
-- Also patches admin.send_test_membership_push, the only other
-- caller of this endpoint that was still headerless — it would
-- silently 401 and look exactly like the bug it exists to test.
-- ============================================================

SELECT cron.unschedule(jobname)
FROM cron.job
WHERE jobname = 'process-notifications-every-minute';

SELECT cron.schedule(
  'process-notifications-every-minute',
  '* * * * *',
  $$
  SELECT net.http_post(
    url := 'https://qvozjwlkzordudkhamcu.supabase.co/functions/v1/process-notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2b3pqd2xrem9yZHVka2hhbWN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwOTA4MzksImV4cCI6MjA4NjY2NjgzOX0.VYsaJ7TST2PuHQFmalwRuENxpeUGylkHI59YiRyjxzc'
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);

-- ── Same header fix for the dev-only membership push tester ───────────────────
-- Body is unchanged from 20260613180000 apart from the headers argument; see
-- that migration for the full explanation of why this is a PROCEDURE.
CREATE OR REPLACE PROCEDURE admin.send_test_membership_push(
  p_membership_id uuid default '6fc5fec5-ec6a-44d6-8a37-8b77ca00371e',
  p_wait_seconds  int  default 12
)
LANGUAGE plpgsql
AS $proc$
declare
  v_orig_ends     date;
  v_orig_reminder timestamptz;
  v_orig_lead     int;
  v_far_ts        timestamptz := timestamptz '2030-06-14 00:00:00+00';
  v_far_date      date        := date '2030-06-14';
begin
  -- 1. Snapshot the current state so we can restore it precisely.
  select ends_at, reminder_sent_at
    into v_orig_ends, v_orig_reminder
  from bookings.memberships
  where id = p_membership_id;
  if not found then
    raise exception 'membership % not found', p_membership_id;
  end if;

  select lead_minutes into v_orig_lead
  from admin.notification_reminders
  where key = 'membership';

  -- 2. Park the membership on a unique far-future date and point the
  --    reminder lead at exactly that instant, so ONLY this row is due.
  update bookings.memberships
  set ends_at = v_far_date, reminder_sent_at = null
  where id = p_membership_id;

  update admin.notification_reminders
  set lead_minutes = ceil(extract(epoch from (v_far_ts - now())) / 60)::int
  where key = 'membership';
  commit;  -- make the parked state visible to pg_net + the edge function

  -- 3. Fire the edge function (identical to the every-minute cron call,
  --    including the Authorization header the gateway requires).
  perform net.http_post(
    url     := 'https://qvozjwlkzordudkhamcu.supabase.co/functions/v1/process-notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2b3pqd2xrem9yZHVka2hhbWN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwOTA4MzksImV4cCI6MjA4NjY2NjgzOX0.VYsaJ7TST2PuHQFmalwRuENxpeUGylkHI59YiRyjxzc'
    ),
    body    := '{}'::jsonb
  );
  commit;  -- let the pg_net background worker pick up the request

  -- 4. Wait while pg_net dispatches and the edge function processes.
  perform pg_sleep(p_wait_seconds);

  -- 5. Restore the original state exactly (incl. reminder_sent_at = null
  --    so the real reminder still fires later).
  update admin.notification_reminders
  set lead_minutes = v_orig_lead
  where key = 'membership';

  update bookings.memberships
  set ends_at = v_orig_ends, reminder_sent_at = v_orig_reminder
  where id = p_membership_id;
  commit;
end;
$proc$;
