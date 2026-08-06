-- ============================================================
-- Migration: Expose party pricing fields from available_farm_shifts
-- Date: 2026-08-06
-- ============================================================
--
-- The mobile app fetches farm shifts via bookings.available_farm_shifts()
-- (BookingRepository.fetchFarmShifts calls the RPC, not a direct table
-- select), so 20260806000001's new farm_shifts columns
-- (party_enabled/party_included_persons/party_flat_fee_iqd/
-- party_extra_person_fee_iqd) were never actually reaching the client —
-- FarmShift.fromJson correctly defaulted them to "off" because the RPC's
-- response simply didn't include those keys. This migration adds them to
-- both the bookings-schema function and its public PostgREST wrapper,
-- preserving all existing logic (is_closed handling, past-start-time
-- blocking, full-day mirroring the day shift, GIST overlap check)
-- unchanged.
--
-- RETURNS TABLE's column list cannot be changed via CREATE OR REPLACE, so
-- both functions are dropped and recreated. Dropping a function clears its
-- grants, so EXECUTE is re-granted on the public wrapper at the end,
-- matching the original migration (20260511000002_farm_shift_availability.sql).

DROP FUNCTION IF EXISTS bookings.available_farm_shifts(uuid, date);

CREATE OR REPLACE FUNCTION bookings.available_farm_shifts(p_place_id uuid, p_date date)
RETURNS TABLE(
  place_id uuid,
  shift_type bookings.farm_shift_type,
  starts_time time without time zone,
  ends_time time without time zone,
  price_iqd integer,
  is_available boolean,
  is_closed boolean,
  party_enabled boolean,
  party_included_persons integer,
  party_flat_fee_iqd integer,
  party_extra_person_fee_iqd integer
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'bookings', 'public'
AS $function$
DECLARE
  v_hours         RECORD;
  v_now_baghdad   timestamp;
  v_today_baghdad date;
BEGIN
  v_now_baghdad   := (NOW() AT TIME ZONE 'Asia/Baghdad');
  v_today_baghdad := v_now_baghdad::date;

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
        true  AS is_closed,
        fs.party_enabled,
        fs.party_included_persons,
        fs.party_flat_fee_iqd,
        fs.party_extra_person_fee_iqd
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
        -- On today: block the shift once its start time has passed.
        -- For 'full' day: also block if the earliest day-shift start has passed,
        -- since a full-day booking can't start mid-day (mirrors Flutter app behaviour).
        (
          p_date > v_today_baghdad
          OR (
            v_now_baghdad::time < fs.starts_time
            AND (
              fs.shift_type <> 'full'
              OR NOT EXISTS (
                SELECT 1 FROM bookings.farm_shifts ds
                WHERE ds.place_id = p_place_id
                  AND ds.shift_type = 'day'
                  AND v_now_baghdad::time >= ds.starts_time
              )
            )
          )
        )
        AND NOT EXISTS (
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
        false AS is_closed,
        fs.party_enabled,
        fs.party_included_persons,
        fs.party_flat_fee_iqd,
        fs.party_extra_person_fee_iqd
      FROM bookings.farm_shifts fs
      WHERE fs.place_id = p_place_id
      ORDER BY fs.starts_time;
  END IF;
END;
$function$;

DROP FUNCTION IF EXISTS public.available_farm_shifts(uuid, date);

CREATE OR REPLACE FUNCTION public.available_farm_shifts(p_place_id uuid, p_date date)
RETURNS TABLE(
  place_id uuid,
  shift_type text,
  starts_time time without time zone,
  ends_time time without time zone,
  price_iqd integer,
  is_available boolean,
  is_closed boolean,
  party_enabled boolean,
  party_included_persons integer,
  party_flat_fee_iqd integer,
  party_extra_person_fee_iqd integer
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'bookings', 'public'
AS $function$
  SELECT
    place_id,
    shift_type::text,
    starts_time,
    ends_time,
    price_iqd,
    is_available,
    is_closed,
    party_enabled,
    party_included_persons,
    party_flat_fee_iqd,
    party_extra_person_fee_iqd
  FROM bookings.available_farm_shifts(p_place_id, p_date);
$function$;

GRANT EXECUTE ON FUNCTION public.available_farm_shifts(uuid, date)
  TO anon, authenticated;
