ALTER TABLE profiles.app_users
  ADD COLUMN IF NOT EXISTS preferred_locale text;
