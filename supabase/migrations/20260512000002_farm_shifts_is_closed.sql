-- ============================================================
-- Migration: Add is_closed to available_farm_shifts RPC
-- Date: 2026-05-12
-- ============================================================
-- Updates the farm shifts RPC to check place-wide closure.
-- If the place is closed on p_date, all shifts are returned with
-- is_available=false and is_closed=true.

-- Drop existing functions first (return type changes require DROP + recreate)
DROP FUNCTION IF EXISTS public.available_farm_shifts(uuid, date);
DROP FUNCTION IF EXISTS bookings.available_farm_shifts(uuid, date);

CREATE OR REPLACE FUNCTION bookings.available_farm_shifts(
  p_place_id uuid,
  p_date     date
)
RETURNS TABLE (
  place_id     uuid,
  shift_type   bookings.farm_shift_type,
  starts_time  time,
  ends_time    time,
  price_iqd    integer,
  is_available boolean,
  is_closed    boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
DECLARE
  v_hours RECORD;
BEGIN
  SELECT * INTO v_hours
  FROM bookings._court_hours(p_place_id, NULL::uuid, p_date);

  IF FOUND AND v_hours.is_closed THEN
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        fs.price_iqd,
        false AS is_available,
        true  AS is_closed
      FROM bookings.farm_shifts fs
      WHERE fs.place_id = p_place_id
      ORDER BY fs.starts_time;
  ELSE
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        fs.price_iqd,
        NOT EXISTS (
          SELECT 1
          FROM bookings.bookings b
          WHERE b.place_id = p_place_id
            AND b.category = 'farm'
            AND b.status   = 'confirmed'
            AND tstzrange(b.starts_at, b.ends_at, '[)') &&
                tstzrange(
                  (p_date::text || ' ' || fs.starts_time::text)::timestamp
                    AT TIME ZONE 'Asia/Baghdad',
                  CASE WHEN fs.ends_time <= fs.starts_time
                    THEN ((p_date + 1)::text || ' ' || fs.ends_time::text)::timestamp
                           AT TIME ZONE 'Asia/Baghdad'
                    ELSE (p_date::text || ' ' || fs.ends_time::text)::timestamp
                           AT TIME ZONE 'Asia/Baghdad'
                  END,
                  '[)'
                )
        ) AS is_available,
        false AS is_closed
      FROM bookings.farm_shifts fs
      WHERE fs.place_id = p_place_id
      ORDER BY fs.starts_time;
  END IF;
END;
$$;

-- Update public wrapper to expose is_closed
CREATE OR REPLACE FUNCTION public.available_farm_shifts(
  p_place_id uuid,
  p_date     date
)
RETURNS TABLE (
  place_id     uuid,
  shift_type   text,
  starts_time  time,
  ends_time    time,
  price_iqd    integer,
  is_available boolean,
  is_closed    boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT
    place_id,
    shift_type::text,
    starts_time,
    ends_time,
    price_iqd,
    is_available,
    is_closed
  FROM bookings.available_farm_shifts(p_place_id, p_date);
$$;

GRANT EXECUTE ON FUNCTION public.available_farm_shifts(uuid, date)
  TO anon, authenticated;
