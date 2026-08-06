-- ============================================================
-- Migration: Charge per-date price overrides in create_farm_booking
-- Date: 2026-08-06
-- ============================================================
--
-- amount_iqd now uses the resolved (possibly overridden) price for the
-- booking's date, via the same farm_shift_price_overrides table
-- available_farm_shifts already reads for display — so the charged
-- amount always matches what the customer saw.

CREATE OR REPLACE FUNCTION bookings.create_farm_booking(
  p_place_id       uuid,
  p_date           date,
  p_shift_type     bookings.farm_shift_type,
  p_party_size     integer DEFAULT NULL,
  p_bringing_party boolean DEFAULT false
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
  v_price_iqd     integer;
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

  -- Resolve the effective price for this date — an override wins if one
  -- exists for (place_id, shift_type, date), otherwise the standing price.
  SELECT po.price_iqd INTO v_price_iqd
  FROM bookings.farm_shift_price_overrides po
  WHERE po.place_id = p_place_id AND po.shift_type = p_shift_type AND po.date = p_date;

  IF v_price_iqd IS NULL THEN
    v_price_iqd := v_shift.price_iqd;
  END IF;

  IF p_party_size IS NOT NULL THEN
    IF NOT v_shift.party_enabled THEN
      RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
    END IF;
    IF p_party_size < 1 THEN
      RAISE EXCEPTION 'party_size must be at least 1' USING ERRCODE = 'P0004';
    END IF;
  END IF;

  IF p_bringing_party AND NOT v_shift.party_enabled THEN
    RAISE EXCEPTION 'Party pricing not enabled for this shift' USING ERRCODE = 'P0003';
  END IF;

  v_party_fee := (CASE WHEN p_bringing_party THEN v_shift.party_flat_fee_iqd ELSE 0 END)
    + GREATEST(0, COALESCE(p_party_size, 1) - v_shift.party_included_persons)
        * v_shift.party_extra_person_fee_iqd;

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
  IF p_bringing_party THEN
    v_category_data := v_category_data || jsonb_build_object('bringing_party', true);
  END IF;
  IF v_party_fee > 0 THEN
    v_category_data := v_category_data || jsonb_build_object('party_fee_iqd', v_party_fee);
  END IF;

  INSERT INTO bookings.bookings (
    user_id, merchant_id, place_id, category, status,
    starts_at, ends_at, amount_iqd, hold_until, category_data
  ) VALUES (
    v_user_id, v_merchant_id, p_place_id, 'farm', 'pending',
    v_starts_at, v_ends_at, v_price_iqd + v_party_fee, v_hold_until,
    v_category_data
  )
  RETURNING id, qr_token INTO v_booking_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_booking_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_price_iqd + v_party_fee,
    'hold_until', v_hold_until
  );
END;
$$;
