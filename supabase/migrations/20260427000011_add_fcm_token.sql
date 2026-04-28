-- Add FCM token column to app_users for push notifications
ALTER TABLE profiles.app_users
  ADD COLUMN IF NOT EXISTS fcm_token text;

CREATE INDEX IF NOT EXISTS app_users_fcm_token_idx
  ON profiles.app_users (fcm_token)
  WHERE fcm_token IS NOT NULL;
