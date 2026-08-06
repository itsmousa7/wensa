-- ============================================================
-- Migration: Farm shift party pricing
-- Date: 2026-08-06
-- ============================================================
--
-- Lets merchants configure, per shift, an optional party surcharge:
--   - party_enabled: on/off
--   - party_included_persons: guests covered by the base shift price
--   - party_flat_fee_iqd: flat charge added when the customer opts into a party
--   - party_extra_person_fee_iqd: per-guest charge beyond party_included_persons
--
-- bookings.create_farm_booking gains p_party_size (nullable) and computes
-- the party surcharge server-side — the client never sends a price.

ALTER TABLE bookings.farm_shifts
  ADD COLUMN party_enabled              boolean NOT NULL DEFAULT false,
  ADD COLUMN party_included_persons     integer NOT NULL DEFAULT 1  CHECK (party_included_persons > 0),
  ADD COLUMN party_flat_fee_iqd         integer NOT NULL DEFAULT 0  CHECK (party_flat_fee_iqd >= 0),
  ADD COLUMN party_extra_person_fee_iqd integer NOT NULL DEFAULT 0  CHECK (party_extra_person_fee_iqd >= 0);

-- ── bookings.create_farm_booking — add p_party_size ─────────────────────────
-- The argument list changes (adds a 4th param). CREATE OR REPLACE cannot
-- "replace" a function when the argument types differ — Postgres would keep
-- the old 3-arg function AND add this as a new overload, making 3-arg calls
-- ambiguous. Drop the old signature first so there's exactly one version.
DROP FUNCTION IF EXISTS bookings.create_farm_booking(uuid, date, bookings.farm_shift_type);

CREATE OR REPLACE FUNCTION bookings.create_farm_booking(
  p_place_id   uuid,
  p_date       date,
  p_shift_type bookings.farm_shift_type,
  p_party_size integer DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $$
DECLARE
  v_user_id       uuid := auth.uid();
  v_merchant_id   uuid;
  v_shift         bookings.farm_shifts%ROWTYPE;
  v_starts_at     timestamptz;
  v_ends_at       timestamptz;
  v_hold_until    timestamptz;
  v_booking_id    uuid;
  v_qr_token      uuid;
  v_tz            text := 'Asia/Baghdad';
  v_party_fee     integer := 0;
  v_category_data jsonb;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  -- Look up shift definition
  SELECT * INTO v_shift
  FROM bookings.farm_shifts
  WHERE place_id = p_place_id AND shift_type = p_shift_type;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shift not configured for this farm' USING ERRCODE = 'P0002';
  END IF;

  IF p_party_size IS NOT NULL THEN
    IF NOT v_shift.party_enabled THEN
      RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
    END IF;
    IF p_party_size < 1 THEN
      RAISE EXCEPTION 'party_size must be at least 1' USING ERRCODE = 'P0004';
    END IF;
    v_party_fee := v_shift.party_flat_fee_iqd
      + GREATEST(0, p_party_size - v_shift.party_included_persons) * v_shift.party_extra_person_fee_iqd;
  END IF;

  -- Build UTC timestamptz from local date + time
  v_starts_at := (p_date || ' ' || v_shift.starts_time)::timestamp
                   AT TIME ZONE v_tz;

  -- Handle overnight shift (ends_time <= starts_time means next calendar day)
  IF v_shift.ends_time <= v_shift.starts_time THEN
    v_ends_at := ((p_date + 1) || ' ' || v_shift.ends_time)::timestamp
                   AT TIME ZONE v_tz;
  ELSE
    v_ends_at := (p_date || ' ' || v_shift.ends_time)::timestamp
                   AT TIME ZONE v_tz;
  END IF;

  v_merchant_id := bookings._place_merchant(p_place_id);
  v_hold_until  := now() + interval '60 seconds';

  v_category_data := jsonb_build_object('shift_type', p_shift_type);
  IF p_party_size IS NOT NULL THEN
    v_category_data := v_category_data || jsonb_build_object('party_size', p_party_size);
  END IF;
  IF v_party_fee > 0 THEN
    v_category_data := v_category_data || jsonb_build_object('party_fee_iqd', v_party_fee);
  END IF;

  INSERT INTO bookings.bookings (
    user_id, merchant_id, place_id, category, status,
    starts_at, ends_at, amount_iqd, hold_until, category_data
  ) VALUES (
    v_user_id, v_merchant_id, p_place_id, 'farm', 'pending',
    v_starts_at, v_ends_at, v_shift.price_iqd + v_party_fee, v_hold_until,
    v_category_data
  )
  RETURNING id, qr_token INTO v_booking_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_booking_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_shift.price_iqd + v_party_fee,
    'hold_until', v_hold_until
  );
END;
$$;

-- ── public.create_farm_booking wrapper — add p_party_size ──────────────────
DROP FUNCTION IF EXISTS public.create_farm_booking(uuid, date, bookings.farm_shift_type);

CREATE OR REPLACE FUNCTION public.create_farm_booking(
  p_place_id   uuid,
  p_date       date,
  p_shift_type bookings.farm_shift_type,
  p_party_size integer DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.create_farm_booking(p_place_id, p_date, p_shift_type, p_party_size);
$$;
