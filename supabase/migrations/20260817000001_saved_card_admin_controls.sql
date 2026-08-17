-- Admin controls for saved-card tokenization:
--   1. app_settings flag to stop new cards from being saved (checked
--      server-side in verify-payment's saveCardToken()).
--   2. admin RPC to hard-delete saved cards — all of them, or one user's —
--      since RLS on bookings.user_payment_tokens only lets the owning user
--      delete their own row (admin dashboard sessions aren't that user).

INSERT INTO public.app_settings (key, value)
VALUES ('card_saving_enabled', 'true')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.admin_delete_payment_tokens(p_user_id uuid DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF p_user_id IS NULL THEN
    DELETE FROM bookings.user_payment_tokens;
  ELSE
    DELETE FROM bookings.user_payment_tokens WHERE user_id = p_user_id;
  END IF;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_delete_payment_tokens(uuid) TO authenticated;
