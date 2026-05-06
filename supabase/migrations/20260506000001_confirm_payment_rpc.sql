-- ============================================================
-- Migration: confirm_payment + confirm_membership_payment RPCs
-- Date: 2026-05-06
--
-- Called from the mobile app immediately after Wayl reports
-- a successful payment, so the booking is marked confirmed
-- before the cron job can expire it.
-- ============================================================

-- ── bookings.confirm_payment ──────────────────────────────────────────────────
-- User-callable. Flips status → confirmed and payment_status → paid.
-- No-ops silently if already confirmed (idempotent).
CREATE OR REPLACE FUNCTION bookings.confirm_payment(
  p_booking_id uuid,
  p_payment_id text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, auth, public
AS $$
DECLARE
  v_uid uuid := auth.uid();
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
  WHERE id        = p_booking_id
    AND user_id   = v_uid
    AND status    = 'pending';
  -- Silently succeeds if already confirmed or not found (idempotent).
END;
$$;

-- ── bookings.confirm_membership_payment ──────────────────────────────────────
-- Same for memberships table.
CREATE OR REPLACE FUNCTION bookings.confirm_membership_payment(
  p_membership_id uuid,
  p_payment_id    text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, auth, public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  UPDATE bookings.memberships
  SET
    payment_status = 'paid',
    payment_id     = COALESCE(p_payment_id, payment_id)
  WHERE id       = p_membership_id
    AND user_id  = v_uid;
END;
$$;

-- ── Public wrappers (PostgREST routing) ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.confirm_payment(
  p_booking_id uuid,
  p_payment_id text DEFAULT NULL
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.confirm_payment(p_booking_id, p_payment_id);
$$;

CREATE OR REPLACE FUNCTION public.confirm_membership_payment(
  p_membership_id uuid,
  p_payment_id    text DEFAULT NULL
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.confirm_membership_payment(p_membership_id, p_payment_id);
$$;
