-- ============================================================
-- Migration: promoted_banners (update), merchant_staff, merchant_plan_history
-- Date: 2026-04-18
-- Project: wain_flosi
-- ============================================================

-- ── 2.3  promoted_banners ──────────────────────────────────────────────────
-- Table may already exist from initial setup. Add missing columns safely.
CREATE TABLE IF NOT EXISTS business.promoted_banners (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid        NOT NULL REFERENCES business.merchants(id) ON DELETE CASCADE,
  place_id    uuid        REFERENCES content.places(id) ON DELETE SET NULL,
  start_date  date        NOT NULL,
  end_date    date        NOT NULL,
  cost_iqd    integer     NOT NULL DEFAULT 0,
  paid_via    text        NOT NULL DEFAULT 'paid', -- 'trial' | 'quarterly_slot' | 'paid'
  status      text        NOT NULL DEFAULT 'scheduled', -- 'scheduled'|'active'|'ended'|'refunded'
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Add missing columns to existing table (no-ops if already present)
ALTER TABLE business.promoted_banners
  ADD COLUMN IF NOT EXISTS cost_iqd   integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS paid_via   text    DEFAULT 'paid',
  ADD COLUMN IF NOT EXISTS start_date date,
  ADD COLUMN IF NOT EXISTS end_date   date;

CREATE INDEX IF NOT EXISTS idx_promoted_banners_dates
  ON business.promoted_banners (start_date, end_date)
  WHERE status IN ('scheduled', 'active');

ALTER TABLE business.promoted_banners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "banners_merchant_own" ON business.promoted_banners;
CREATE POLICY "banners_merchant_own"
  ON business.promoted_banners
  FOR ALL
  USING (
    merchant_id IN (
      SELECT id FROM business.merchants WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "banners_admin_all" ON business.promoted_banners;
CREATE POLICY "banners_admin_all"
  ON business.promoted_banners
  FOR ALL
  USING (public.is_admin());

GRANT ALL ON business.promoted_banners TO authenticated, service_role;

-- ── 2.4  merchant_staff ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS business.merchant_staff (
  merchant_id uuid        NOT NULL REFERENCES business.merchants(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES auth.users(id)         ON DELETE CASCADE,
  role        text        NOT NULL DEFAULT 'staff',  -- 'owner' | 'staff'
  added_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (merchant_id, user_id)
);

ALTER TABLE business.merchant_staff ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "staff_merchant_owner" ON business.merchant_staff;
CREATE POLICY "staff_merchant_owner"
  ON business.merchant_staff
  FOR ALL
  USING (
    merchant_id IN (
      SELECT id FROM business.merchants WHERE user_id = auth.uid()
    )
  );

GRANT ALL ON business.merchant_staff TO authenticated, service_role;

-- ── 2.5  merchant_plan_history ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS business.merchant_plan_history (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid        NOT NULL REFERENCES business.merchants(id) ON DELETE CASCADE,
  from_plan_id text,
  to_plan_id  text        NOT NULL,
  changed_at  timestamptz NOT NULL DEFAULT now(),
  reason      text        -- 'upgrade'|'downgrade'|'payment_failure'|'trial_expired'|...
);

CREATE INDEX IF NOT EXISTS idx_merchant_plan_history_merchant
  ON business.merchant_plan_history (merchant_id, changed_at DESC);

ALTER TABLE business.merchant_plan_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "plan_history_merchant_own" ON business.merchant_plan_history;
CREATE POLICY "plan_history_merchant_own"
  ON business.merchant_plan_history
  FOR SELECT
  USING (
    merchant_id IN (
      SELECT id FROM business.merchants WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "plan_history_admin_all" ON business.merchant_plan_history;
CREATE POLICY "plan_history_admin_all"
  ON business.merchant_plan_history
  FOR ALL
  USING (public.is_admin());

GRANT SELECT ON business.merchant_plan_history TO authenticated;
GRANT ALL    ON business.merchant_plan_history TO service_role;
