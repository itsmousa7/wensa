-- ============================================================
-- Migration: Booking schema — RPCs
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- All functions are SECURITY DEFINER, validate auth.uid(), and
-- run inside a transaction (Postgres function default).
-- ============================================================

-- ── Helper: resolve merchant_id for a place ───────────────────────────────────
CREATE OR REPLACE FUNCTION bookings._place_merchant(p_place_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = content, business, public
AS $$
  SELECT merchant_id FROM content.places WHERE id = p_place_id;
$$;

-- ── Helper: resolve merchant_id for an event (via its place) ─────────────────
CREATE OR REPLACE FUNCTION bookings._event_merchant(p_event_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = content, business, public
AS $$
  SELECT p.merchant_id
  FROM content.events e
  JOIN content.places p ON p.id = e.place_id
  WHERE e.id = p_event_id;
$$;

-- ── Helper: resolve opening hours for a court+date ───────────────────────────
-- Returns (opens_at, closes_at, is_closed). Override wins over weekly schedule.
CREATE OR REPLACE FUNCTION bookings._court_hours(
  p_place_id  uuid,
  p_court_id  uuid,
  p_date      date
)
RETURNS TABLE (opens_at time, closes_at time, is_closed boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  -- 1. Court-specific override
  SELECT o.opens_at, o.closes_at, o.is_closed
  FROM bookings.place_hours_overrides o
  WHERE o.place_id = p_place_id AND o.court_id = p_court_id AND o.date = p_date

  UNION ALL

  -- 2. Place-wide override (court_id IS NULL)
  SELECT o.opens_at, o.closes_at, o.is_closed
  FROM bookings.place_hours_overrides o
  WHERE o.place_id = p_place_id AND o.court_id IS NULL AND o.date = p_date

  UNION ALL

  -- 3. Court-specific weekly schedule
  SELECT h.opens_at, h.closes_at, h.is_closed
  FROM bookings.place_hours h
  WHERE h.place_id = p_place_id
    AND h.court_id = p_court_id
    AND h.weekday = EXTRACT(DOW FROM p_date)::smallint

  UNION ALL

  -- 4. Place-wide weekly schedule
  SELECT h.opens_at, h.closes_at, h.is_closed
  FROM bookings.place_hours h
  WHERE h.place_id = p_place_id
    AND h.court_id IS NULL
    AND h.weekday = EXTRACT(DOW FROM p_date)::smallint

  LIMIT 1;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.create_padel_booking
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.create_padel_booking(
  p_place_id  uuid,
  p_court_id  uuid,
  p_starts_at timestamptz,
  p_hours     integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $$
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
  v_category     bookings.booking_category;
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

  -- Determine category from place's category name
  SELECT CASE c.name
    WHEN 'Padel'    THEN 'padel'::bookings.booking_category
    WHEN 'Football' THEN 'football'::bookings.booking_category
    ELSE 'padel'::bookings.booking_category
  END INTO v_category
  FROM content.places pl
  JOIN content.categories c ON c.id = pl.category_id
  WHERE pl.id = p_place_id;

  -- Validate within opening hours
  SELECT * INTO v_hours_row
  FROM bookings._court_hours(p_place_id, p_court_id, p_starts_at::date);

  IF FOUND AND v_hours_row.is_closed THEN
    RAISE EXCEPTION 'Court is closed on this date' USING ERRCODE = 'P0003';
  END IF;

  IF FOUND THEN
    IF p_starts_at::time < v_hours_row.opens_at OR
       (p_starts_at + (p_hours || ' hours')::interval)::time > v_hours_row.closes_at THEN
      RAISE EXCEPTION 'Booking falls outside opening hours' USING ERRCODE = 'P0003';
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

  -- Insert (GIST exclusion will reject overlapping pending/confirmed rows)
  INSERT INTO bookings.bookings (
    user_id, merchant_id, place_id, category, status,
    starts_at, ends_at, amount_iqd, hold_until, category_data
  ) VALUES (
    v_user_id, v_merchant_id, p_place_id, v_category, 'pending',
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
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.create_farm_booking
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.create_farm_booking(
  p_place_id   uuid,
  p_date       date,
  p_shift_type bookings.farm_shift_type
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $$
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

  -- Look up shift definition
  SELECT * INTO v_shift
  FROM bookings.farm_shifts
  WHERE place_id = p_place_id AND shift_type = p_shift_type;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shift not configured for this farm' USING ERRCODE = 'P0002';
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
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.create_concert_booking
-- Creates 60-second holds; actual booking rows created by wayl-webhook on
-- payment success. Returns group_id + total for payment link creation.
-- Deletes expired holds before inserting since the unique index on
-- (event_id, seat_id) is not partial (now() disallowed in index predicates).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.create_concert_booking(
  p_event_id  uuid,
  p_seat_ids  uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $$
DECLARE
  v_user_id      uuid := auth.uid();
  v_group_id     uuid := gen_random_uuid();
  v_expires_at   timestamptz := now() + interval '60 seconds';
  v_seat         uuid;
  v_seat_row     bookings.venue_seats%ROWTYPE;
  v_tier_price   integer;
  v_total_iqd    integer := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  IF array_length(p_seat_ids, 1) IS NULL OR array_length(p_seat_ids, 1) = 0 THEN
    RAISE EXCEPTION 'At least one seat is required' USING ERRCODE = 'P0001';
  END IF;

  -- Sweep expired holds for these seats so the unique index doesn't block us
  DELETE FROM bookings.event_seat_holds
  WHERE event_id = p_event_id
    AND seat_id = ANY(p_seat_ids)
    AND expires_at < now();

  FOREACH v_seat IN ARRAY p_seat_ids LOOP
    SELECT * INTO v_seat_row FROM bookings.venue_seats WHERE id = v_seat;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Seat not found: %', v_seat USING ERRCODE = 'P0002';
    END IF;

    SELECT price_iqd INTO v_tier_price
    FROM bookings.event_tiers
    WHERE event_id = p_event_id AND tier_key = v_seat_row.tier_key;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No tier configured for seat tier_key: %', v_seat_row.tier_key
        USING ERRCODE = 'P0004';
    END IF;

    v_total_iqd := v_total_iqd + v_tier_price;

    -- Unique index (event_id, seat_id) rejects a seat already held by someone else
    INSERT INTO bookings.event_seat_holds (
      event_id, seat_id, user_id, group_id, expires_at
    ) VALUES (
      p_event_id, v_seat, v_user_id, v_group_id, v_expires_at
    );
  END LOOP;

  RETURN jsonb_build_object(
    'group_id',    v_group_id,
    'seat_count',  array_length(p_seat_ids, 1),
    'total_iqd',   v_total_iqd,
    'expires_at',  v_expires_at
  );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.create_restaurant_booking
-- Stays pending until merchant confirms; capacity checked before insert.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.create_restaurant_booking(
  p_place_id          uuid,
  p_starts_at         timestamptz,
  p_party_size        integer,
  p_seating_option_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $$
DECLARE
  v_user_id       uuid := auth.uid();
  v_merchant_id   uuid;
  v_config        bookings.restaurant_config%ROWTYPE;
  v_occupied      integer;
  v_slot_end      timestamptz;
  v_hold_until    timestamptz;
  v_booking_id    uuid;
  v_qr_token      uuid;
  v_cat_data      jsonb;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  IF p_party_size < 1 THEN
    RAISE EXCEPTION 'Party size must be at least 1' USING ERRCODE = 'P0001';
  END IF;

  -- Load restaurant config
  SELECT * INTO v_config FROM bookings.restaurant_config WHERE place_id = p_place_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Restaurant bookings not configured for this place' USING ERRCODE = 'P0002';
  END IF;

  v_slot_end := p_starts_at + (v_config.slot_minutes || ' minutes')::interval;

  -- Check slot capacity (sum of pending/confirmed party sizes in this window)
  SELECT COALESCE(SUM((category_data->>'party_size')::integer), 0) INTO v_occupied
  FROM bookings.bookings
  WHERE place_id = p_place_id
    AND category = 'restaurant'
    AND status IN ('pending', 'confirmed')
    AND tstzrange(starts_at, ends_at, '[)') && tstzrange(p_starts_at, v_slot_end, '[)');

  IF v_occupied + p_party_size > v_config.seats_per_slot THEN
    RAISE EXCEPTION 'No capacity available for this time slot' USING ERRCODE = 'P0003';
  END IF;

  v_merchant_id := bookings._place_merchant(p_place_id);
  v_hold_until  := now() + interval '60 seconds';

  v_cat_data := jsonb_build_object('party_size', p_party_size);
  IF p_seating_option_id IS NOT NULL THEN
    v_cat_data := v_cat_data || jsonb_build_object('seating_option_id', p_seating_option_id);
  END IF;

  INSERT INTO bookings.bookings (
    user_id, merchant_id, place_id, category, status,
    starts_at, ends_at, amount_iqd, hold_until, category_data
  )
  SELECT
    v_user_id, v_merchant_id, p_place_id, 'restaurant', 'pending',
    p_starts_at, v_slot_end,
    -- amount comes from create-booking edge function via merchant-configured pricing
    0,
    v_hold_until,
    v_cat_data
  RETURNING id, qr_token INTO v_booking_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_booking_id,
    'qr_token',   v_qr_token,
    'hold_until', v_hold_until
  );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.create_membership
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.create_membership(
  p_place_id  uuid,
  p_plan_id   uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $$
DECLARE
  v_user_id     uuid := auth.uid();
  v_merchant_id uuid;
  v_plan        bookings.membership_plans%ROWTYPE;
  v_starts_at   date := current_date;
  v_ends_at     date;
  v_mem_id      uuid;
  v_qr_token    uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  -- Load plan
  SELECT * INTO v_plan
  FROM bookings.membership_plans
  WHERE id = p_plan_id AND place_id = p_place_id AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Membership plan not found or inactive' USING ERRCODE = 'P0002';
  END IF;

  -- Partial unique on memberships blocks duplicate active/frozen rows
  v_merchant_id := bookings._place_merchant(p_place_id);
  v_ends_at     := v_starts_at + v_plan.duration_days;

  INSERT INTO bookings.memberships (
    user_id, place_id, merchant_id, membership_type, plan_id,
    starts_at, ends_at, status, amount_iqd, payment_status
  ) VALUES (
    v_user_id, p_place_id, v_merchant_id, v_plan.membership_type, p_plan_id,
    v_starts_at, v_ends_at, 'active', v_plan.price_iqd, 'pending'
  )
  RETURNING id, qr_token INTO v_mem_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_mem_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_plan.price_iqd
  );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.confirm_booking — merchant / admin only
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.confirm_booking(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, business, admin, auth, public
AS $$
DECLARE
  v_booking bookings.bookings%ROWTYPE;
BEGIN
  SELECT * INTO v_booking FROM bookings.bookings WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  -- Must be merchant staff for this booking's merchant, or admin
  IF NOT (
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM business.merchant_staff
      WHERE user_id = auth.uid() AND merchant_id = v_booking.merchant_id
    )
  ) THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = 'P0001';
  END IF;

  IF v_booking.status <> 'pending' THEN
    RAISE EXCEPTION 'Only pending bookings can be confirmed' USING ERRCODE = 'P0003';
  END IF;

  UPDATE bookings.bookings SET status = 'confirmed' WHERE id = p_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.cancel_booking — merchant / admin / booking owner
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.cancel_booking(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, business, admin, auth, public
AS $$
DECLARE
  v_booking bookings.bookings%ROWTYPE;
  v_uid     uuid := auth.uid();
BEGIN
  SELECT * INTO v_booking FROM bookings.bookings WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  -- Owner, merchant staff, or admin
  IF NOT (
    v_booking.user_id = v_uid OR
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM business.merchant_staff
      WHERE user_id = v_uid AND merchant_id = v_booking.merchant_id
    )
  ) THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = 'P0001';
  END IF;

  IF v_booking.status IN ('completed', 'cancelled') THEN
    RAISE EXCEPTION 'Booking cannot be cancelled in its current state' USING ERRCODE = 'P0003';
  END IF;

  UPDATE bookings.bookings SET status = 'cancelled' WHERE id = p_id;

  -- Release any lingering concert seat holds for this booking's seats
  IF v_booking.category = 'concert' AND v_booking.group_id IS NOT NULL THEN
    DELETE FROM bookings.event_seat_holds
    WHERE group_id = v_booking.group_id;
  END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.freeze_membership
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.freeze_membership(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, auth, public
AS $$
DECLARE
  v_mem  bookings.memberships%ROWTYPE;
  v_plan bookings.membership_plans%ROWTYPE;
BEGIN
  SELECT * INTO v_mem FROM bookings.memberships WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Membership not found' USING ERRCODE = 'P0002'; END IF;

  -- Only the owner can freeze
  IF v_mem.user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_plan FROM bookings.membership_plans WHERE id = v_mem.plan_id;
  IF NOT v_plan.allow_freeze THEN
    RAISE EXCEPTION 'This plan does not allow freezing' USING ERRCODE = 'P0003';
  END IF;

  IF v_mem.status <> 'active' THEN
    RAISE EXCEPTION 'Only active memberships can be frozen' USING ERRCODE = 'P0003';
  END IF;

  UPDATE bookings.memberships SET status = 'frozen' WHERE id = p_id;

  INSERT INTO bookings.membership_freezes (membership_id, starts_at)
  VALUES (p_id, current_date);
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.resume_membership
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.resume_membership(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, auth, public
AS $$
DECLARE
  v_mem      bookings.memberships%ROWTYPE;
  v_freeze   bookings.membership_freezes%ROWTYPE;
  v_days     integer;
BEGIN
  SELECT * INTO v_mem FROM bookings.memberships WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Membership not found' USING ERRCODE = 'P0002'; END IF;

  IF v_mem.user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = 'P0001';
  END IF;

  IF v_mem.status <> 'frozen' THEN
    RAISE EXCEPTION 'Membership is not frozen' USING ERRCODE = 'P0003';
  END IF;

  -- Close the open freeze period
  SELECT * INTO v_freeze
  FROM bookings.membership_freezes
  WHERE membership_id = p_id AND ends_at IS NULL
  ORDER BY starts_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No open freeze period found' USING ERRCODE = 'P0004';
  END IF;

  v_days := current_date - v_freeze.starts_at;

  UPDATE bookings.membership_freezes
  SET ends_at = current_date
  WHERE id = v_freeze.id;

  -- Extend the membership by the number of frozen days
  UPDATE bookings.memberships
  SET status   = 'active',
      ends_at  = ends_at + v_days
  WHERE id = p_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.validate_qr
-- One-shot redemption: first eligible scan flips status to 'used'.
-- Handles both bookings.bookings and bookings.memberships.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.validate_qr(p_qr_token uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, business, admin, auth, public
AS $$
DECLARE
  v_uid      uuid := auth.uid();
  v_booking  bookings.bookings%ROWTYPE;
  v_mem      bookings.memberships%ROWTYPE;
  v_eligible text;
BEGIN
  -- ── Try bookings.bookings first ──────────────────────────────────────────
  SELECT * INTO v_booking FROM bookings.bookings WHERE qr_token = p_qr_token;

  IF FOUND THEN
    -- Caller must be merchant staff for this booking's merchant, or admin
    IF NOT (
      public.is_admin() OR
      EXISTS (
        SELECT 1 FROM business.merchant_staff
        WHERE user_id = v_uid AND merchant_id = v_booking.merchant_id
      )
    ) THEN
      RAISE EXCEPTION 'Forbidden' USING ERRCODE = 'P0001';
    END IF;

    -- Determine eligibility
    v_eligible := CASE
      WHEN v_booking.status = 'used'                         THEN 'used'
      WHEN v_booking.status = 'cancelled'                    THEN 'cancelled'
      WHEN v_booking.status = 'expired'                      THEN 'expired'
      WHEN v_booking.status NOT IN ('confirmed', 'completed') THEN 'not_yet_active'
      WHEN v_booking.ends_at < now()                         THEN 'expired'
      WHEN v_booking.starts_at > now() + interval '15 minutes' THEN 'not_yet_active'
      ELSE 'eligible'
    END;

    -- One-shot: atomically flip to 'used' on first eligible scan
    IF v_eligible = 'eligible' THEN
      UPDATE bookings.bookings SET status = 'used' WHERE id = v_booking.id;
      v_booking.status := 'used';
    END IF;

    RETURN jsonb_build_object(
      'type',        'booking',
      'booking',     row_to_json(v_booking),
      'eligibility', v_eligible
    );
  END IF;

  -- ── Try bookings.memberships ─────────────────────────────────────────────
  SELECT * INTO v_mem FROM bookings.memberships WHERE qr_token = p_qr_token;

  IF FOUND THEN
    IF NOT (
      public.is_admin() OR
      EXISTS (
        SELECT 1 FROM business.merchant_staff
        WHERE user_id = v_uid AND merchant_id = v_mem.merchant_id
      )
    ) THEN
      RAISE EXCEPTION 'Forbidden' USING ERRCODE = 'P0001';
    END IF;

    -- Memberships show active/expired/etc — no one-shot flip
    v_eligible := CASE
      WHEN v_mem.status = 'cancelled'                THEN 'cancelled'
      WHEN v_mem.status = 'expired'                  THEN 'expired'
      WHEN v_mem.status = 'frozen'                   THEN 'not_yet_active'
      WHEN v_mem.status = 'active' AND v_mem.ends_at >= current_date THEN 'eligible'
      ELSE 'expired'
    END;

    RETURN jsonb_build_object(
      'type',        'membership',
      'booking',     row_to_json(v_mem),
      'eligibility', v_eligible
    );
  END IF;

  RAISE EXCEPTION 'QR token not found' USING ERRCODE = 'P0002';
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.available_slots — returns hourly slots for a court on a date
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.available_slots(
  p_court_id  uuid,
  p_date      date
)
RETURNS TABLE (
  starts_at  timestamptz,
  ends_at    timestamptz,
  available  boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
DECLARE
  v_place_id  uuid;
  v_hours_row RECORD;
  v_opens     timestamptz;
  v_closes    timestamptz;
  v_slot      timestamptz;
  v_tz        text := 'Asia/Baghdad';
BEGIN
  SELECT place_id INTO v_place_id FROM bookings.courts WHERE id = p_court_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Court not found' USING ERRCODE = 'P0002'; END IF;

  SELECT * INTO v_hours_row
  FROM bookings._court_hours(v_place_id, p_court_id, p_date);

  -- No hours configured or closed → return empty
  IF NOT FOUND OR v_hours_row.is_closed THEN
    RETURN;
  END IF;

  v_opens  := (p_date || ' ' || v_hours_row.opens_at)::timestamp AT TIME ZONE v_tz;
  v_closes := (p_date || ' ' || v_hours_row.closes_at)::timestamp AT TIME ZONE v_tz;

  v_slot := v_opens;
  WHILE v_slot + interval '1 hour' <= v_closes LOOP
    starts_at := v_slot;
    ends_at   := v_slot + interval '1 hour';
    available := NOT EXISTS (
      SELECT 1 FROM bookings.bookings b
      WHERE (b.category_data->>'court_id')::uuid = p_court_id
        AND b.status IN ('pending', 'confirmed')
        AND tstzrange(b.starts_at, b.ends_at, '[)') &&
            tstzrange(v_slot, v_slot + interval '1 hour', '[)')
    );
    RETURN NEXT;
    v_slot := v_slot + interval '1 hour';
  END LOOP;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- bookings.available_seats — returns all seats with hold/booking status
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.available_seats(p_event_id uuid)
RETURNS TABLE (
  seat_id    uuid,
  row_label  text,
  seat_label text,
  tier_key   text,
  x          integer,
  y          integer,
  price_iqd  integer,
  status     text       -- 'free' | 'held' | 'taken'
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, content, public
AS $$
  SELECT
    vs.id                          AS seat_id,
    vs.row_label,
    vs.seat_label,
    vs.tier_key,
    vs.x,
    vs.y,
    et.price_iqd,
    CASE
      WHEN b.id IS NOT NULL              THEN 'taken'
      WHEN h.id IS NOT NULL              THEN 'held'
      ELSE                                    'free'
    END                            AS status
  FROM bookings.venue_seats vs
  JOIN bookings.venue_seat_maps   vsm ON vsm.id = vs.seat_map_id
  JOIN content.events             e   ON e.place_id = vsm.venue_id
  LEFT JOIN bookings.event_tiers  et  ON et.event_id = p_event_id
                                      AND et.tier_key = vs.tier_key
  LEFT JOIN bookings.bookings     b   ON b.event_id = p_event_id
                                      AND (b.category_data->>'seat_id') = vs.id::text
                                      AND b.status IN ('pending', 'confirmed', 'used')
  LEFT JOIN bookings.event_seat_holds h
                                      ON h.event_id = p_event_id
                                      AND h.seat_id = vs.id
                                      AND h.expires_at > now()
  WHERE e.id = p_event_id;
$$;
