-- ─────────────────────────────────────────────────────────────────────────────
--  handle_new_user trigger + backfill + phone NOT NULL
--
--  Until now there was no auth.users → profiles.app_users insert trigger, so
--  new users could end up without a profile row. This migration:
--    1. Adds handle_new_user() and the matching trigger on auth.users.
--    2. Backfills profiles.app_users for any existing auth.users that are
--       missing a row.
--    3. Normalises phone to NOT NULL DEFAULT '' so the app's "complete
--       profile" gate has a single shape to check (empty = needs completion).
--
--  Name extraction order:
--    raw_user_meta_data.first_name  →  split_part(full_name, ' ', 1)
--                                 →  split_part(name,      ' ', 1)
--  Google OAuth populates full_name / name; email signup populates first_name.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, profiles, auth
AS $$
DECLARE
  meta jsonb := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);
  full_name text := COALESCE(
    meta->>'full_name',
    meta->>'name',
    ''
  );
  v_first text;
  v_second text;
BEGIN
  v_first := COALESCE(
    NULLIF(meta->>'first_name', ''),
    NULLIF(split_part(full_name, ' ', 1), ''),
    ''
  );

  v_second := COALESCE(
    NULLIF(meta->>'second_name', ''),
    NULLIF(meta->>'last_name', ''),
    NULLIF(split_part(full_name, ' ', 2), ''),
    ''
  );

  INSERT INTO profiles.app_users (id, email, first_name, second_name, phone)
  VALUES (NEW.id, NEW.email, v_first, v_second, '')
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- ── Backfill ─────────────────────────────────────────────────────────────────
-- Any existing auth.users without a profiles.app_users row gets one now.
INSERT INTO profiles.app_users (id, email, first_name, second_name, phone)
SELECT
  u.id,
  u.email,
  COALESCE(
    NULLIF(u.raw_user_meta_data->>'first_name', ''),
    NULLIF(split_part(COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', ''), ' ', 1), ''),
    ''
  ),
  COALESCE(
    NULLIF(u.raw_user_meta_data->>'second_name', ''),
    NULLIF(u.raw_user_meta_data->>'last_name', ''),
    NULLIF(split_part(COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', ''), ' ', 2), ''),
    ''
  ),
  ''
FROM auth.users u
LEFT JOIN profiles.app_users a ON a.id = u.id
WHERE a.id IS NULL;

-- ── Phone column: NOT NULL DEFAULT '' ────────────────────────────────────────
-- The app treats empty string as "needs completion" — so NOT NULL is safe.
UPDATE profiles.app_users SET phone = '' WHERE phone IS NULL;
ALTER TABLE profiles.app_users
  ALTER COLUMN phone SET DEFAULT '',
  ALTER COLUMN phone SET NOT NULL;
