-- ============================================================
-- Migration: Notifications schema — broadcasts table
-- ============================================================

CREATE SCHEMA IF NOT EXISTS notifications;

-- anon gets no access; authenticated gets read-only via RLS; service_role gets full access
GRANT USAGE ON SCHEMA notifications TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA notifications
  GRANT SELECT ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA notifications
  GRANT ALL ON TABLES TO service_role;

CREATE TABLE notifications.broadcasts (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  type            text          NOT NULL DEFAULT 'general'
                                  CHECK (type IN ('general', 'new_event', 'new_place', 'promo')),
  title_en        text          NOT NULL,
  title_ar        text          NOT NULL,
  body_en         text          NOT NULL,
  body_ar         text          NOT NULL,
  target_user_id  uuid          REFERENCES auth.users(id) ON DELETE SET NULL,
  scheduled_at    timestamptz,
  sent_at         timestamptz,
  sent_count      integer       NOT NULL DEFAULT 0,
  error_count     integer       NOT NULL DEFAULT 0,
  status          text          NOT NULL DEFAULT 'pending'
                                  CHECK (status IN ('pending', 'sending', 'sent', 'partial', 'failed')),
  created_by      uuid          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS broadcasts_status_scheduled_idx
  ON notifications.broadcasts (status, scheduled_at)
  WHERE status = 'pending';

ALTER TABLE notifications.broadcasts ENABLE ROW LEVEL SECURITY;

-- service_role (Edge Function) has unrestricted access — bypasses RLS anyway
CREATE POLICY "service_role_all" ON notifications.broadcasts
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Only verified admins (in admin.admin_roles) can read or write via the portal
CREATE POLICY "admin_only" ON notifications.broadcasts
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin.admin_roles WHERE user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM admin.admin_roles WHERE user_id = auth.uid()));
