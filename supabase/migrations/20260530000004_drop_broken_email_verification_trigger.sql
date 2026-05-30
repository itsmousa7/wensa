-- handle_email_verification() targets public.app_users which does not exist
-- (the table lives in profiles.app_users). This causes every OTP verification
-- to fail with a "relation does not exist" exception, rolling back the
-- auth.users UPDATE and blocking all new registrations.
--
-- The trigger is also redundant: handle_new_user() already inserts the profile
-- row on auth.users INSERT, before email confirmation.

DROP TRIGGER IF EXISTS on_auth_user_email_verified ON auth.users;
DROP FUNCTION IF EXISTS public.handle_email_verification();
