-- Concert bookings now insert pending bookings.bookings rows up-front
-- (one per seat, status='pending') instead of relying solely on the
-- short-lived event_seat_holds table. The wayl webhook flips them to
-- 'confirmed' on payment success. Mirrors the padel/farm/restaurant flow,
-- and ensures concert bookings show up in My Bookings / admin / merchant
-- dashboards regardless of how long the payment takes.

CREATE OR REPLACE FUNCTION bookings.create_concert_booking(
  p_event_id uuid,
  p_seat_ids uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'bookings', 'content', 'business', 'auth', 'public'
AS $function$
DECLARE
  v_user_id      uuid := auth.uid();
  v_group_id     uuid := gen_random_uuid();
  v_hold_until   timestamptz := now() + interval '10 minutes';
  v_event        content.events%ROWTYPE;
  v_merchant_id  uuid;
  v_starts_at    timestamptz;
  v_ends_at      timestamptz;
  v_seat         uuid;
  v_seat_row     bookings.venue_seats%ROWTYPE;
  v_tier_price   integer;
  v_total_iqd    integer := 0;
  v_booking_id   uuid;
  v_ids          uuid[] := ARRAY[]::uuid[];
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  IF array_length(p_seat_ids, 1) IS NULL OR array_length(p_seat_ids, 1) = 0 THEN
    RAISE EXCEPTION 'At least one seat is required' USING ERRCODE = 'P0001';
  END IF;

  -- Release any of this user's prior pending concert bookings on the same
  -- seats so the unique partial index doesn't reject the retry.
  UPDATE bookings.bookings
  SET status = 'cancelled', updated_at = now()
  WHERE event_id = p_event_id
    AND user_id = v_user_id
    AND category = 'concert'
    AND status = 'pending'
    AND payment_status <> 'paid'
    AND (category_data->>'seat_id')::uuid = ANY(p_seat_ids);

  DELETE FROM bookings.event_seat_holds
  WHERE event_id = p_event_id
    AND seat_id = ANY(p_seat_ids)
    AND expires_at < now();

  SELECT * INTO v_event FROM content.events WHERE id = p_event_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found: %', p_event_id USING ERRCODE = 'P0002';
  END IF;

  v_merchant_id := v_event.merchant_id;
  IF v_merchant_id IS NULL AND v_event.place_id IS NOT NULL THEN
    SELECT merchant_id INTO v_merchant_id
    FROM content.places WHERE id = v_event.place_id;
  END IF;
  IF v_merchant_id IS NULL THEN
    RAISE EXCEPTION 'Event has no merchant: %', p_event_id USING ERRCODE = 'P0002';
  END IF;

  v_starts_at := v_event.start_date;
  v_ends_at   := COALESCE(v_event.end_date, v_event.start_date + interval '3 hours');
  IF v_ends_at <= v_starts_at THEN
    v_ends_at := v_starts_at + interval '3 hours';
  END IF;

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

    INSERT INTO bookings.bookings (
      user_id, merchant_id, place_id, event_id, category, status,
      starts_at, ends_at, amount_iqd, hold_until, category_data, group_id
    ) VALUES (
      v_user_id, v_merchant_id, v_event.place_id, p_event_id, 'concert', 'pending',
      v_starts_at, v_ends_at, v_tier_price, v_hold_until,
      jsonb_build_object(
        'seat_id',  v_seat,
        'tier_key', v_seat_row.tier_key,
        'row',      v_seat_row.row_label,
        'seat',     v_seat_row.seat_label
      ),
      v_group_id
    )
    RETURNING id INTO v_booking_id;

    v_ids := array_append(v_ids, v_booking_id);

    INSERT INTO bookings.event_seat_holds (
      event_id, seat_id, user_id, group_id, expires_at
    ) VALUES (
      p_event_id, v_seat, v_user_id, v_group_id, v_hold_until
    )
    ON CONFLICT (event_id, seat_id) DO UPDATE
      SET user_id    = EXCLUDED.user_id,
          group_id   = EXCLUDED.group_id,
          expires_at = EXCLUDED.expires_at;
  END LOOP;

  RETURN jsonb_build_object(
    'group_id',    v_group_id,
    'booking_ids', v_ids,
    'seat_count',  array_length(p_seat_ids, 1),
    'total_iqd',   v_total_iqd,
    'hold_until',  v_hold_until,
    'expires_at',  v_hold_until
  );
END;
$function$;
