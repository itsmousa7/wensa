-- User activity + ticket-purchase stats for the admin dashboard.
--
-- 1. Track when a user last opened the app (written by the mobile app).
-- 2. touch_last_seen(): heartbeat the mobile app calls on open/resume.
-- 3. user_ticket_stats(): per-user, per-venue-category counts of *bought*
--    tickets (paid or confirmed/completed/used) for the Users dashboard.

alter table profiles.app_users
    add column if not exists last_seen_at timestamptz;

-- Mobile app heartbeat: stamps the caller's own last_seen_at.
create or replace function public.touch_last_seen()
returns void
language sql
security definer
set search_path = profiles
as $$
    update profiles.app_users
       set last_seen_at = now()
     where id = auth.uid();
$$;

grant execute on function public.touch_last_seen() to authenticated;

-- Per-user ticket purchase counts by venue category. Bookings carry a
-- `category` enum (sports/restaurant/concert/farm); memberships have no
-- category, so they are reported under a synthetic 'membership' bucket.
-- "Bought" = paid, or a status that implies a completed purchase.
create or replace function public.user_ticket_stats()
returns table (user_id uuid, category text, cnt bigint)
language sql
security definer
set search_path = public, bookings, profiles
as $$
    select b.user_id, b.category::text, count(*)::bigint
      from bookings.bookings b
     where b.payment_status = 'paid'
        or b.status in ('confirmed', 'completed', 'used')
     group by b.user_id, b.category
    union all
    select m.user_id, 'membership', count(*)::bigint
      from bookings.memberships m
     where m.payment_status = 'paid'
        or m.status = 'active'
     group by m.user_id;
$$;

grant execute on function public.user_ticket_stats() to authenticated;
