-- Client-side fallback to confirm a concert booking group once Wayl
-- reports a successful payment, mirroring bookings.confirm_payment for
-- single-row bookings. Prevents the booking from being stuck in
-- 'pending' if the Wayl webhook is delayed or fails to fire.
CREATE OR REPLACE FUNCTION bookings.confirm_concert_group_payment(
  p_group_id   uuid,
  p_payment_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, auth, public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_first_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  UPDATE bookings.bookings
  SET
    payment_status = 'paid',
    status         = 'confirmed',
    payment_id     = COALESCE(p_payment_id, payment_id),
    hold_until     = NULL
  WHERE group_id  = p_group_id
    AND user_id   = v_uid
    AND status    = 'pending';

  DELETE FROM bookings.event_seat_holds
  WHERE group_id = p_group_id;

  SELECT id INTO v_first_id
  FROM bookings.bookings
  WHERE group_id = p_group_id AND user_id = v_uid
  ORDER BY created_at ASC
  LIMIT 1;

  RETURN v_first_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.confirm_concert_group_payment(
  p_group_id   uuid,
  p_payment_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.confirm_concert_group_payment(p_group_id, p_payment_id);
$$;
