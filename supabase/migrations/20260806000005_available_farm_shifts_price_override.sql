-- ============================================================
-- Migration: Resolve per-date price overrides in available_farm_shifts
-- Date: 2026-08-06
-- ============================================================
--
-- price_iqd becomes the effective (possibly overridden) price for the
-- requested date. standard_price_iqd is populated only when an override
-- is active, so the client can show "was X, now Y". RETURNS TABLE's
-- column list can't change via CREATE OR REPLACE, so both functions are
-- dropped and recreated (same two-step as 20260806000002); EXECUTE is
-- re-granted on the public wrapper at the end.

DROP FUNCTION IF EXISTS bookings.available_farm_shifts(uuid, date);

CREATE OR REPLACE FUNCTION bookings.available_farm_shifts(p_place_id uuid, p_date date)
RETURNS TABLE(
  place_id uuid,
  shift_type bookings.farm_shift_type,
  starts_time time without time zone,
  ends_time time without time zone,
  price_iqd integer,
  standard_price_iqd integer,
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
        COALESCE(po.price_iqd, fs.price_iqd) AS price_iqd,
        CASE WHEN po.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
        false AS is_available,
        true  AS is_closed,
        fs.party_enabled,
        fs.party_included_persons,
        fs.party_flat_fee_iqd,
        fs.party_extra_person_fee_iqd
      FROM bookings.farm_shifts fs
      LEFT JOIN bookings.farm_shift_price_overrides po
        ON po.place_id = fs.place_id
       AND po.shift_type = fs.shift_type
       AND po.date = p_date
      WHERE fs.place_id = p_place_id
      ORDER BY fs.starts_time;
  ELSE
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        COALESCE(po.price_iqd, fs.price_iqd) AS price_iqd,
        CASE WHEN po.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
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
      LEFT JOIN bookings.farm_shift_price_overrides po
        ON po.place_id = fs.place_id
       AND po.shift_type = fs.shift_type
       AND po.date = p_date
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
  standard_price_iqd integer,
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
    standard_price_iqd,
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
