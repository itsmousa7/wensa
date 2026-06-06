-- Clears any stale pending email-change state for the calling user so that
-- the next auth.updateUser() call generates a fresh OTP instead of silently
-- reusing the dead pending record.
CREATE OR REPLACE FUNCTION public.clear_email_change()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  UPDATE auth.users
  SET
    email_change              = '',
    email_change_token_new    = '',
    email_change_token_current = '',
    email_change_sent_at      = NULL,
    email_change_confirm_status = 0
  WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.clear_email_change() TO authenticated;
