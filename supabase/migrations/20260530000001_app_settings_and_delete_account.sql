-- ============================================================
-- Migration: app_settings table + delete_own_account RPC
-- Date: 2026-05-30
-- Project: wain_flosi
-- ============================================================

-- ── 1. app_settings key-value store ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.app_settings (
  key         text        PRIMARY KEY,
  value       text        NOT NULL DEFAULT '',
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Seed default rows
INSERT INTO public.app_settings (key, value)
VALUES
  ('support_whatsapp_phone', '')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Authenticated + anon users may read (mobile app needs it without sign-in)
DROP POLICY IF EXISTS "app_settings_read" ON public.app_settings;
CREATE POLICY "app_settings_read"
  ON public.app_settings
  FOR SELECT
  TO authenticated, anon
  USING (true);

-- Only admins may write
DROP POLICY IF EXISTS "app_settings_admin_write" ON public.app_settings;
CREATE POLICY "app_settings_admin_write"
  ON public.app_settings
  FOR ALL
  USING (public.is_admin());

GRANT SELECT ON public.app_settings TO authenticated, anon;
GRANT ALL    ON public.app_settings TO service_role;

-- ── 2. delete_own_account RPC ────────────────────────────────────────────────
-- Deletes the calling user from auth.users.
-- Cascades to profiles.app_users and all other FK-linked rows.
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, public, profiles
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
