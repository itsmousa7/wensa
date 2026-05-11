-- ============================================================
-- Migration: Farm shift availability RPC
-- Date: 2026-05-11
-- ============================================================
--
-- Returns one row per configured shift for a farm + date,
-- with is_available = true when no confirmed booking overlaps
-- that shift's time window. Uses the same overnight logic as
-- create_farm_booking (ends_time <= starts_time → next day).

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
  is_available boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
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
    ) AS is_available
  FROM bookings.farm_shifts fs
  WHERE fs.place_id = p_place_id
  ORDER BY fs.starts_time;
$$;

-- PostgREST-accessible wrapper (shift_type cast to text for JSON serialisation)
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
  is_available boolean
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
    is_available
  FROM bookings.available_farm_shifts(p_place_id, p_date);
$$;

GRANT EXECUTE ON FUNCTION public.available_farm_shifts(uuid, date)
  TO anon, authenticated;
