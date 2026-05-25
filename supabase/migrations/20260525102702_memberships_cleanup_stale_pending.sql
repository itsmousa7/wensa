-- Cleanup for stale pending memberships:
--   1. One-shot sweep of existing rows abandoned for >15 min.
--   2. cancel_membership RPC so the client can release a row immediately
--      when the user closes the Wayl payment webview.
--   3. cron job that mirrors bookings_expire_holds for the memberships table.

-- 1. One-shot cleanup.
UPDATE bookings.memberships
SET    status = 'expired'
WHERE  status = 'pending'
  AND  payment_status <> 'paid'
  AND  created_at < now() - interval '15 minutes';

-- 2. cancel_membership: mirrors cancel_booking — auth via user/admin/staff,
-- refuses paid rows, idempotent for terminal states.
CREATE OR REPLACE FUNCTION bookings.cancel_membership(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'bookings', 'business', 'admin', 'auth', 'public'
AS $function$
DECLARE
  v_mem  bookings.memberships%ROWTYPE;
  v_uid  uuid := auth.uid();
BEGIN
  SELECT * INTO v_mem FROM bookings.memberships WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Membership not found' USING ERRCODE = 'P0002';
  END IF;

  IF NOT (
    v_mem.user_id = v_uid OR
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM business.merchant_staff
      WHERE user_id = v_uid AND merchant_id = v_mem.merchant_id
    )
  ) THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = 'P0001';
  END IF;

  -- Paid memberships need a refund flow, which is out of scope here.
  IF v_mem.payment_status = 'paid' THEN
    RAISE EXCEPTION 'Paid memberships cannot be cancelled here' USING ERRCODE = 'P0003';
  END IF;

  IF v_mem.status IN ('cancelled', 'expired') THEN
    RETURN;
  END IF;

  UPDATE bookings.memberships
  SET    status = 'cancelled'
  WHERE  id = p_id;
END;
$function$;

-- 3. Schedule the sweeper. Runs every minute; idempotent.
SELECT cron.schedule(
  'memberships_expire_pending',
  '* * * * *',
  $$
    UPDATE bookings.memberships
    SET    status = 'expired'
    WHERE  status = 'pending'
      AND  payment_status <> 'paid'
      AND  created_at < now() - interval '15 minutes';
  $$
);
