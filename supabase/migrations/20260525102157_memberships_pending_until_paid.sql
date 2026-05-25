-- Memberships now go through a real 'pending' state until payment lands.
-- Previously create_membership inserted rows as status='active' with
-- payment_status='pending', which (a) showed unpaid memberships as Active in
-- history and (b) risked granting service to non-paying users if any consumer
-- of the table gated on status alone.

-- Backfill: any membership row that was inserted as 'active' but never paid
-- (the bug we are fixing) is reclassified as 'pending'.
UPDATE bookings.memberships
SET    status = 'pending'
WHERE  status = 'active'
  AND  payment_status = 'pending';

-- create_membership: insert as 'pending' instead of 'active'.
-- confirm_membership_payment flips it back to 'active' on successful payment.
CREATE OR REPLACE FUNCTION bookings.create_membership(p_place_id uuid, p_plan_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'bookings', 'content', 'business', 'auth', 'public'
AS $function$
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

  SELECT * INTO v_plan
  FROM bookings.membership_plans
  WHERE id = p_plan_id AND place_id = p_place_id AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Membership plan not found or inactive' USING ERRCODE = 'P0002';
  END IF;

  v_merchant_id := bookings._place_merchant(p_place_id);
  v_ends_at     := v_starts_at + v_plan.duration_days;

  INSERT INTO bookings.memberships (
    user_id, place_id, merchant_id, membership_type, plan_id,
    starts_at, ends_at, status, amount_iqd, payment_status
  ) VALUES (
    v_user_id, p_place_id, v_merchant_id, v_plan.membership_type, p_plan_id,
    v_starts_at, v_ends_at, 'pending', v_plan.price_iqd, 'pending'
  )
  RETURNING id, qr_token INTO v_mem_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_mem_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_plan.price_iqd
  );
END;
$function$;

CREATE OR REPLACE FUNCTION bookings.create_membership(p_place_id uuid, p_plan_id uuid, p_force boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'bookings', 'content', 'business', 'auth', 'public'
AS $function$
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

  SELECT * INTO v_plan
  FROM bookings.membership_plans
  WHERE id = p_plan_id AND place_id = p_place_id AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Membership plan not found or inactive' USING ERRCODE = 'P0002';
  END IF;

  v_merchant_id := bookings._place_merchant(p_place_id);
  v_ends_at     := v_starts_at + v_plan.duration_days;

  INSERT INTO bookings.memberships (
    user_id, place_id, merchant_id, membership_type, plan_id,
    starts_at, ends_at, status, amount_iqd, payment_status
  ) VALUES (
    v_user_id, p_place_id, v_merchant_id, v_plan.membership_type, p_plan_id,
    v_starts_at, v_ends_at, 'pending', v_plan.price_iqd, 'pending'
  )
  RETURNING id, qr_token INTO v_mem_id, v_qr_token;

  RETURN jsonb_build_object(
    'id',         v_mem_id,
    'qr_token',   v_qr_token,
    'amount_iqd', v_plan.price_iqd
  );
END;
$function$;

-- confirm_membership_payment now flips both payment_status AND status, but
-- only when the row is still 'pending' (idempotent; won't resurrect cancelled
-- or expired rows).
CREATE OR REPLACE FUNCTION bookings.confirm_membership_payment(p_membership_id uuid, p_payment_id text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'bookings', 'auth', 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  UPDATE bookings.memberships
  SET
    payment_status = 'paid',
    status         = CASE WHEN status = 'pending' THEN 'active'::bookings.membership_status ELSE status END,
    payment_id     = COALESCE(p_payment_id, payment_id)
  WHERE id       = p_membership_id
    AND user_id  = v_uid;
END;
$function$;

-- Column default mirrors the RPC behaviour so any future code path that omits
-- the status column on insert also lands as 'pending'.
ALTER TABLE bookings.memberships ALTER COLUMN status SET DEFAULT 'pending'::bookings.membership_status;
