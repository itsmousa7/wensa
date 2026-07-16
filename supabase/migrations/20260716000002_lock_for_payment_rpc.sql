-- bookings.lock_for_payment — re-validate + extend a hold right before charging.
--
-- Problem: hourly/shift/reservation/general_admission holds last only 60
-- seconds (concert seat holds 10 minutes) — see 20260427000010_bookings_cron.sql
-- (bookings_expire_holds runs every 30s and flips status: 'pending' → 'expired'
-- once hold_until passes). A user filling the card form (or even a one-tap
-- saved-card charge landing a beat late) can easily outlast that window: the
-- charge would succeed at HyperPay, but confirm_payment/_group/_membership
-- only flip rows still WHERE status = 'pending', so the booking is silently
-- left unconfirmed while the user's card was already charged.
--
-- Fix: call this immediately before initiating any charge (both the card-form
-- flow and the saved-card MIT flow). If the slot is still held by the caller
-- and not yet expired, extend the hold long enough to safely cover the
-- payment (form entry + 3DS, or a synchronous MIT charge) and return true.
-- If the hold already expired (or was never the caller's), returns false and
-- the caller must refuse to charge — the client shows "slot no longer
-- available" instead of a payment error.
CREATE OR REPLACE FUNCTION bookings.lock_for_payment(p_kind text, p_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, auth, public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_group_size    integer;
  v_group_locked  integer;
  v_row_count     integer;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  IF p_kind = 'booking' THEN
    UPDATE bookings.bookings
    SET hold_until = now() + interval '5 minutes'
    WHERE id        = p_id
      AND user_id   = v_uid
      AND status    = 'pending'
      AND hold_until > now();
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    RETURN v_row_count > 0;

  ELSIF p_kind = 'concert_group' THEN
    -- All-or-nothing: only extend if every row in the group is still the
    -- caller's live pending hold. A partially-expired group would otherwise
    -- let some seats lock in while others silently drop out from under it.
    SELECT count(*) INTO v_group_size
    FROM bookings.bookings
    WHERE group_id = p_id AND user_id = v_uid;

    IF v_group_size = 0 THEN
      RETURN false;
    END IF;

    SELECT count(*) INTO v_group_locked
    FROM bookings.bookings
    WHERE group_id = p_id
      AND user_id  = v_uid
      AND status   = 'pending'
      AND hold_until > now();

    IF v_group_locked <> v_group_size THEN
      RETURN false;
    END IF;

    UPDATE bookings.bookings
    SET hold_until = now() + interval '5 minutes'
    WHERE group_id = p_id AND user_id = v_uid AND status = 'pending';

    UPDATE bookings.event_seat_holds
    SET expires_at = now() + interval '5 minutes'
    WHERE group_id = p_id AND user_id = v_uid;

    RETURN true;

  ELSIF p_kind = 'membership' THEN
    -- No hold_until column on memberships — the pending window is a flat
    -- 15 minutes from creation (bookings_cleanup_stale_pending cron), which
    -- comfortably outlasts a card payment, so this only re-validates.
    RETURN EXISTS (
      SELECT 1 FROM bookings.memberships
      WHERE id             = p_id
        AND user_id        = v_uid
        AND status         = 'pending'
        AND payment_status <> 'paid'
        AND created_at     > now() - interval '15 minutes'
    );

  ELSE
    RAISE EXCEPTION 'Invalid kind: %', p_kind USING ERRCODE = 'P0002';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.lock_for_payment(p_kind text, p_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.lock_for_payment(p_kind, p_id);
$$;
