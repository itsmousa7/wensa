-- Migration: auto-release the caller's prior pending bookings on retry
--
-- Why
--   When a user starts a booking, gets the Wayl payment link, then closes the
--   payment page without paying, the booking row stays in status='pending' for
--   ~60s (until the bookings_expire_holds cron runs). If they tap "Proceed to
--   Payment" again in that window, create_court_booking / create_farm_booking
--   try to insert a new row whose time range overlaps the still-pending one,
--   which trips the bookings_no_court_overlap / bookings_no_farm_overlap
--   exclusion constraint and returns 500.
--
--   The client-side cancel-on-close path is racy (depends on dispose() timing
--   and on `cancel_booking` being reachable). Doing the cleanup inside the
--   create RPC itself makes the retry UX work atomically and regardless of
--   what the client does.
--
-- How
--   Before INSERT, mark any of the caller's own status='pending' rows for the
--   same scope (court+overlap for hourly, place+overlap for farm) as
--   'cancelled'. Filtering by user_id = auth.uid() means we never touch
--   another user's hold. Same transaction, so no constraint race.

-- ── create_court_booking ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.create_court_booking(
  p_place_id uuid,
  p_court_id uuid,
  p_starts_at timestamptz,
  p_hours integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $function$
DECLARE
  v_user_id      uuid := auth.uid();
  v_merchant_id  uuid;
  v_court        bookings.courts%ROWTYPE;
  v_hours_row    RECORD;
  v_price        integer;
  v_ends_at      timestamptz;
  v_hold_until   timestamptz;
  v_booking_id   uuid;
  v_qr_token     uuid;
  v_tz           text := 'Asia/Baghdad';
  v_starts_local time;
  v_ends_local   time;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  IF p_hours < 1 THEN
    RAISE EXCEPTION 'Minimum booking is 1 hour' USING ERRCODE = 'P0001';
  END IF;

  -- Verify court belongs to this place and is active
  SELECT * INTO v_court
  FROM bookings.courts
  WHERE id = p_court_id AND place_id = p_place_id AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Court not found or inactive' USING ERRCODE = 'P0002';
  END IF;

  -- Validate within opening hours (convert to Baghdad local time before comparing)
  SELECT * INTO v_hours_row
  FROM bookings._court_hours(p_place_id, p_court_id, (p_starts_at AT TIME ZONE v_tz)::date);

  IF FOUND AND v_hours_row.is_closed THEN
    RAISE EXCEPTION 'Court is closed on this date' USING ERRCODE = 'P0003';
  END IF;

  IF FOUND THEN
    v_starts_local := (p_starts_at AT TIME ZONE v_tz)::time;
    v_ends_local   := ((p_starts_at + (p_hours || ' hours')::interval) AT TIME ZONE v_tz)::time;

    IF v_hours_row.closes_at > v_hours_row.opens_at THEN
      IF v_starts_local < v_hours_row.opens_at OR v_ends_local > v_hours_row.closes_at THEN
        RAISE EXCEPTION 'Booking falls outside opening hours' USING ERRCODE = 'P0003';
      END IF;
    ELSE
      IF v_starts_local > v_hours_row.closes_at AND v_starts_local < v_hours_row.opens_at THEN
        RAISE EXCEPTION 'Booking falls outside opening hours' USING ERRCODE = 'P0003';
      END IF;

      IF v_starts_local >= v_hours_row.opens_at THEN
        IF v_ends_local < v_starts_local AND v_ends_local > v_hours_row.closes_at THEN
          RAISE EXCEPTION 'Booking falls outside opening hours' USING ERRCODE = 'P0003';
        END IF;
      ELSE
        IF v_ends_local > v_hours_row.closes_at THEN
          RAISE EXCEPTION 'Booking falls outside opening hours' USING ERRCODE = 'P0003';
        END IF;
      END IF;
    END IF;
  END IF;

  -- Resolve pricing (court-specific wins over place-wide)
  SELECT COALESCE(
    (SELECT hourly_rate_iqd FROM bookings.place_pricing
     WHERE place_id = p_place_id AND court_id = p_court_id),
    (SELECT hourly_rate_iqd FROM bookings.place_pricing
     WHERE place_id = p_place_id AND court_id IS NULL)
  ) INTO v_price;

  IF v_price IS NULL THEN
    RAISE EXCEPTION 'No pricing configured for this court' USING ERRCODE = 'P0004';
  END IF;

  v_merchant_id := bookings._place_merchant(p_place_id);
  v_ends_at     := p_starts_at + (p_hours || ' hours')::interval;
  v_hold_until  := now() + interval '60 seconds';

  -- Release any prior pending bookings by THIS user that would conflict with
  -- the new request. Lets the user retry after a cancelled / abandoned
  -- payment without tripping bookings_no_court_overlap.
  UPDATE bookings.bookings
  SET status = 'cancelled',
      updated_at = now()
  WHERE user_id = v_user_id
    AND status = 'pending'
    AND category = 'sports'
    AND (category_data->>'court_id')::uuid = p_court_id
    AND tstzrange(starts_at, ends_at, '[)') && tstzrange(p_starts_at, v_ends_at, '[)');

  INSERT INTO bookings.bookings (
    user_id, merchant_id, place_id, category, status,
    starts_at, ends_at, amount_iqd, hold_until, category_data
  ) VALUES (
    v_user_id, v_merchant_id, p_place_id, 'sports', 'pending',
    p_starts_at, v_ends_at, v_price * p_hours, v_hold_until,
    jsonb_build_object('court_id', p_court_id)
  )
  RETURNING id, qr_token INTO v_booking_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_booking_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_price * p_hours,
    'hold_until', v_hold_until
  );
END;
$function$;

-- ── create_farm_booking ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.create_farm_booking(
  p_place_id uuid,
  p_date date,
  p_shift_type bookings.farm_shift_type
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $function$
DECLARE
  v_user_id      uuid := auth.uid();
  v_merchant_id  uuid;
  v_shift        bookings.farm_shifts%ROWTYPE;
  v_starts_at    timestamptz;
  v_ends_at      timestamptz;
  v_hold_until   timestamptz;
  v_booking_id   uuid;
  v_qr_token     uuid;
  v_tz           text := 'Asia/Baghdad';
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_shift
  FROM bookings.farm_shifts
  WHERE place_id = p_place_id AND shift_type = p_shift_type;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shift not configured for this farm' USING ERRCODE = 'P0002';
  END IF;

  v_starts_at := (p_date || ' ' || v_shift.starts_time)::timestamp AT TIME ZONE v_tz;

  IF v_shift.ends_time <= v_shift.starts_time THEN
    v_ends_at := ((p_date + 1) || ' ' || v_shift.ends_time)::timestamp AT TIME ZONE v_tz;
  ELSE
    v_ends_at := (p_date || ' ' || v_shift.ends_time)::timestamp AT TIME ZONE v_tz;
  END IF;

  v_merchant_id := bookings._place_merchant(p_place_id);
  v_hold_until  := now() + interval '60 seconds';

  -- Release any prior pending farm bookings by THIS user that would conflict
  -- with the new request. Same rationale as create_court_booking.
  UPDATE bookings.bookings
  SET status = 'cancelled',
      updated_at = now()
  WHERE user_id = v_user_id
    AND status = 'pending'
    AND category = 'farm'
    AND place_id = p_place_id
    AND tstzrange(starts_at, ends_at, '[)') && tstzrange(v_starts_at, v_ends_at, '[)');

  INSERT INTO bookings.bookings (
    user_id, merchant_id, place_id, category, status,
    starts_at, ends_at, amount_iqd, hold_until, category_data
  ) VALUES (
    v_user_id, v_merchant_id, p_place_id, 'farm', 'pending',
    v_starts_at, v_ends_at, v_shift.price_iqd, v_hold_until,
    jsonb_build_object('shift_type', p_shift_type)
  )
  RETURNING id, qr_token INTO v_booking_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_booking_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_shift.price_iqd,
    'hold_until', v_hold_until
  );
END;
$function$;
