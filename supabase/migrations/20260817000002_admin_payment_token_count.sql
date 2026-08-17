-- The admin dashboard's per-customer saved-card count queried
-- bookings.user_payment_tokens directly, but RLS (upt_select_own) only lets
-- the owning user read their own rows -- an admin session always got back
-- zero rows, showing "0 saved cards" even when the customer has some.

CREATE OR REPLACE FUNCTION public.admin_get_payment_token_count(p_user_id uuid)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT count(*) INTO v_count FROM bookings.user_payment_tokens WHERE user_id = p_user_id;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_get_payment_token_count(uuid) TO authenticated;
