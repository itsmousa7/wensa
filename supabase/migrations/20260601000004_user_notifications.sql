-- ============================================================
-- Migration: Per-user notifications inbox
-- ============================================================
-- Lives in the profiles schema (already exposed via PostgREST) so the Flutter
-- client can SELECT/UPDATE through `.schema('profiles')`. The edge function
-- (service_role) writes here when fanning out FCM pushes.

CREATE TABLE IF NOT EXISTS profiles.user_notifications (
  id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kind        text         NOT NULL
                              CHECK (kind IN (
                                'hourly',
                                'concert',
                                'membership',
                                'broadcast_general',
                                'broadcast_new_event',
                                'broadcast_new_place',
                                'broadcast_promo'
                              )),
  title_en    text         NOT NULL,
  title_ar    text         NOT NULL,
  body_en     text         NOT NULL,
  body_ar     text         NOT NULL,
  data        jsonb        NOT NULL DEFAULT '{}'::jsonb,
  read_at     timestamptz,
  created_at  timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS user_notifications_user_created_idx
  ON profiles.user_notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS user_notifications_unread_idx
  ON profiles.user_notifications (user_id)
  WHERE read_at IS NULL;

ALTER TABLE profiles.user_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all" ON profiles.user_notifications
  FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "own_select" ON profiles.user_notifications
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "own_update" ON profiles.user_notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
