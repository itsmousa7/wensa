-- ============================================================
-- Dev helper: send yourself a real membership-expiry push to
-- verify the localized place-name wording end-to-end.
--
-- A membership is only "due" ~24h before ends_at, so this can't
-- be tested by triggering the edge function alone. This procedure
-- briefly parks one of your memberships into the due-window, fires
-- the same HTTP call the every-minute cron makes, waits for the
-- edge function to run, then restores everything exactly as it was.
--
-- It MUST be a PROCEDURE (not a function): net.http_post only
-- dispatches after the surrounding transaction commits, and the
-- edge function reads membership state when it runs — so we COMMIT
-- the parked state, trigger, pg_sleep, then COMMIT the restore.
--
-- Run it from the Supabase SQL editor (top-level, not inside an
-- explicit transaction or via PostgREST — the internal COMMITs
-- need a top-level CALL):
--
--   CALL admin.send_test_membership_push();
--
-- Optional args:
--   p_membership_id — which membership to borrow (default: a test row)
--   p_wait_seconds  — how long to wait for the edge function (default 12)
-- ============================================================

create or replace procedure admin.send_test_membership_push(
  p_membership_id uuid default '6fc5fec5-ec6a-44d6-8a37-8b77ca00371e',
  p_wait_seconds  int  default 12
)
language plpgsql
as $$
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

  -- 3. Fire the edge function (identical to the every-minute cron call).
  perform net.http_post(
    url     := 'https://qvozjwlkzordudkhamcu.supabase.co/functions/v1/process-notifications',
    headers := '{"Content-Type": "application/json"}'::jsonb,
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
$$;
