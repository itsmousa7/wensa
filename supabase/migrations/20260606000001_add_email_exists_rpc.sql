-- Returns true if the given email is already registered in auth.users.
-- Runs as SECURITY DEFINER so the anon role can call it without direct
-- access to auth.users.
CREATE OR REPLACE FUNCTION public.email_exists(p_email text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE email = lower(trim(p_email))
  );
$$;

GRANT EXECUTE ON FUNCTION public.email_exists(text) TO anon, authenticated;
