-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.available_slots_calendar — slots grouped by CALENDAR day.
--
-- A booking date tab should show only the hours that fall on that calendar date
-- (Asia/Baghdad). For venues whose hours cross midnight (e.g. Thu 09:00→04:00),
-- this means a session splits across two tabs:
--   • its daytime hours stay on the day it opened, and
--   • its after-midnight tail (00:00–03:00) lands on the NEXT day's tab.
-- So "tonight after midnight" is booked under tomorrow's date, and a day's own
-- early-morning hours sit at the top of its own tab (and read as passed/closed
-- once that time is behind us).
--
-- Built on bookings.available_slots (the per-session generator): a calendar day
-- D collects the previous day's session tail that falls on D plus D's own
-- session hours that fall on D, then filters by Baghdad calendar date.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.available_slots_calendar(
  p_court_id uuid,
  p_date     date
)
RETURNS TABLE (starts_at timestamptz, ends_at timestamptz, available boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT s.starts_at, s.ends_at, s.available
  FROM (
    SELECT * FROM bookings.available_slots(p_court_id, p_date - 1)
    UNION ALL
    SELECT * FROM bookings.available_slots(p_court_id, p_date)
  ) s
  WHERE (s.starts_at AT TIME ZONE 'Asia/Baghdad')::date = p_date
  ORDER BY s.starts_at;
$$;

GRANT EXECUTE ON FUNCTION bookings.available_slots_calendar(uuid, date) TO anon, authenticated, service_role;

-- Clean up the operating-day helper from an earlier (reverted) session-day
-- approach: under the calendar-day model a booking's ticket date is just its
-- real calendar date, so this roll-back function is unused and would be wrong.
DROP FUNCTION IF EXISTS bookings.operating_date(bookings.bookings);
