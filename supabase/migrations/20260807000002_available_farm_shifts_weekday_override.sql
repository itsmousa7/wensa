-- ============================================================
-- Migration: Resolve weekday price overrides in available_farm_shifts
-- Date: 2026-08-07
-- ============================================================
--
-- price_iqd becomes the effective price for p_date's weekday.
-- standard_price_iqd is populated only when that weekday has an
-- override (unchanged meaning from the date-keyed version). New:
-- override_weekdays returns EVERY weekday with an override configured
-- for the shift, independent of p_date, so the client can show "Special
-- price · Thu & Fri" even when the customer isn't currently looking at
-- a Thursday or Friday.

DROP FUNCTION IF EXISTS bookings.available_farm_shifts(uuid, date);

CREATE OR REPLACE FUNCTION bookings.available_farm_shifts(p_place_id uuid, p_date date)
RETURNS TABLE(
  place_id uuid,
  shift_type bookings.farm_shift_type,
  starts_time time without time zone,
  ends_time time without time zone,
  price_iqd integer,
  standard_price_iqd integer,
  override_weekdays smallint[],
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
  v_weekday       smallint;
BEGIN
  v_now_baghdad   := (NOW() AT TIME ZONE 'Asia/Baghdad');
  v_today_baghdad := v_now_baghdad::date;
  v_weekday       := EXTRACT(DOW FROM p_date)::smallint;

  SELECT * INTO v_hours
  FROM bookings._court_hours(p_place_id, NULL::uuid, p_date);

  IF FOUND AND v_hours.is_closed THEN
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        COALESCE(wo.price_iqd, fs.price_iqd) AS price_iqd,
        CASE WHEN wo.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
        (SELECT array_agg(wo2.weekday ORDER BY wo2.weekday)
         FROM bookings.farm_shift_weekday_overrides wo2
         WHERE wo2.place_id = fs.place_id AND wo2.shift_type = fs.shift_type) AS override_weekdays,
        false AS is_available,
        true  AS is_closed,
        fs.party_enabled,
        fs.party_included_persons,
        fs.party_flat_fee_iqd,
        fs.party_extra_person_fee_iqd
      FROM bookings.farm_shifts fs
      LEFT JOIN bookings.farm_shift_weekday_overrides wo
        ON wo.place_id = fs.place_id
       AND wo.shift_type = fs.shift_type
       AND wo.weekday = v_weekday
      WHERE fs.place_id = p_place_id
      ORDER BY fs.starts_time;
  ELSE
    RETURN QUERY
      SELECT
        fs.place_id,
        fs.shift_type,
        fs.starts_time,
        fs.ends_time,
        COALESCE(wo.price_iqd, fs.price_iqd) AS price_iqd,
        CASE WHEN wo.price_iqd IS NOT NULL THEN fs.price_iqd END AS standard_price_iqd,
        (SELECT array_agg(wo2.weekday ORDER BY wo2.weekday)
         FROM bookings.farm_shift_weekday_overrides wo2
         WHERE wo2.place_id = fs.place_id AND wo2.shift_type = fs.shift_type) AS override_weekdays,
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
      LEFT JOIN bookings.farm_shift_weekday_overrides wo
        ON wo.place_id = fs.place_id
       AND wo.shift_type = fs.shift_type
       AND wo.weekday = v_weekday
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
  override_weekdays smallint[],
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
    override_weekdays,
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
