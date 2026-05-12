-- ============================================================
-- Migration: place_closed_dates RPC
-- Date: 2026-05-12
-- ============================================================
-- Returns dates in [p_start_date, p_end_date] where the place is
-- closed, by reusing the existing _court_hours helper with
-- NULL court_id (which resolves place-wide hours only).

CREATE OR REPLACE FUNCTION bookings.place_closed_dates(
  p_place_id   uuid,
  p_start_date date,
  p_end_date   date
)
RETURNS SETOF date
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
DECLARE
  v_date date := p_start_date;
  v_row  RECORD;
BEGIN
  IF p_end_date - p_start_date > 365 THEN
    RAISE EXCEPTION 'Date range exceeds maximum of 365 days' USING ERRCODE = 'P0001';
  END IF;

  WHILE v_date <= p_end_date LOOP
    SELECT * INTO v_row
    FROM bookings._court_hours(p_place_id, NULL::uuid, v_date);
    IF FOUND AND v_row.is_closed THEN
      RETURN NEXT v_date;
    END IF;
    v_date := v_date + 1;
  END LOOP;
END;
$$;

-- PostgREST-accessible wrapper
CREATE OR REPLACE FUNCTION public.place_closed_dates(
  p_place_id   uuid,
  p_start_date date,
  p_end_date   date
)
RETURNS SETOF date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.place_closed_dates(p_place_id, p_start_date, p_end_date);
$$;

GRANT EXECUTE ON FUNCTION public.place_closed_dates(uuid, date, date)
  TO anon, authenticated;
