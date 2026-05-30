-- ============================================================
-- Migration: fix delete_own_account RPC
-- Date: 2026-05-30
--
-- bookings.bookings  and  bookings.memberships  both carry
-- ON DELETE RESTRICT on their user_id FK, so the original
-- function failed trying to delete directly from auth.users.
-- Manually delete those rows first, then remove the auth user
-- (which cascades to profiles.app_users, favorites, reviews,
-- business.merchant_staff, etc.).
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, profiles, auth, public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Remove rows that block ON DELETE RESTRICT on auth.users
  DELETE FROM bookings.bookings    WHERE user_id = v_uid;
  DELETE FROM bookings.memberships WHERE user_id = v_uid;

  -- Deleting the auth user cascades to everything else
  -- (app_users, favorites, reviews, merchant_staff, …)
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
