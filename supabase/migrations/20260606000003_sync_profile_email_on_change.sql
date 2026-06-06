-- Keeps profiles.app_users.email in sync with auth.users.email.
--
-- The existing on_auth_user_created trigger only copies the email on INSERT,
-- so when a user changes their email (auth.users.email is updated after they
-- verify the OTP) the profiles row kept the stale address — which is what the
-- app's profile screen reads. This adds an UPDATE-side trigger to mirror the
-- new email, and backfills any rows that already drifted.

CREATE OR REPLACE FUNCTION public.sync_profile_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'profiles', 'auth'
AS $$
BEGIN
  UPDATE profiles.app_users
  SET email = NEW.email
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_email_changed ON auth.users;
CREATE TRIGGER on_auth_user_email_changed
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  WHEN (OLD.email IS DISTINCT FROM NEW.email)
  EXECUTE FUNCTION public.sync_profile_email();

-- Backfill rows that drifted before this trigger existed.
UPDATE profiles.app_users pu
SET email = au.email
FROM auth.users au
WHERE au.id = pu.id
  AND pu.email IS DISTINCT FROM au.email;
