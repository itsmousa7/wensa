-- Unify all hourly-court sports under a single 'sports' booking category.
-- Rationale: padel, football, basketball, etc. all share identical booking logic.
-- The specific sport is always derivable from place_id → content.places.

-- ── 1. Extend enum ────────────────────────────────────────────────────────────
ALTER TYPE bookings.booking_category ADD VALUE IF NOT EXISTS 'sports';

-- ── 2. Migrate existing rows ──────────────────────────────────────────────────
UPDATE bookings.bookings
SET category = 'sports'
WHERE category IN ('padel', 'football');

-- ── 3. Drop old padel-specific function ───────────────────────────────────────
DROP FUNCTION IF EXISTS bookings.create_padel_booking(uuid, uuid, timestamptz, integer);

-- ── 4. Create unified court booking function ──────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.create_court_booking(
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
$$;

-- ── 5. Replace public wrapper ─────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.create_padel_booking(uuid, uuid, timestamptz, integer);

CREATE OR REPLACE FUNCTION public.create_court_booking(
  p_place_id  uuid,
  p_court_id  uuid,
  p_starts_at timestamptz,
  p_hours     integer
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.create_court_booking(p_place_id, p_court_id, p_starts_at, p_hours);
$$;
