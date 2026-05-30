-- ============================================================
-- Migration: Add p_force parameter to create_membership
-- Date: 2026-05-15
--
-- When p_force = true, any existing active/frozen membership
-- for the same user+place is cancelled before creating a new one.
-- This allows the "subscribe for a friend" flow from the app.
-- ============================================================

CREATE OR REPLACE FUNCTION bookings.create_membership(
  p_place_id  uuid,
  p_plan_id   uuid,
  p_force     boolean DEFAULT false
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

  -- When forcing, cancel any existing active/frozen membership first
  -- so the partial unique index (user_id, place_id) WHERE status IN ('active','frozen')
  -- does not block the new insert.
  IF p_force THEN
    UPDATE bookings.memberships
    SET status = 'cancelled'
    WHERE user_id  = v_user_id
      AND place_id = p_place_id
      AND status   IN ('active', 'frozen');
  END IF;

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
