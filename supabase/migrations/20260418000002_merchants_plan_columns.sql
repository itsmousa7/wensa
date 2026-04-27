-- ============================================================
-- Migration: Extend merchants table with plan columns
-- Date: 2026-04-18
-- Project: wain_flosi
--
-- Adds plan_id FK + banner quota tracking to business.merchants.
-- Adds trigger to keep is_verified in sync with plan_id.
-- ============================================================

-- Add plan columns (idempotent via IF NOT EXISTS)
ALTER TABLE business.merchants
  ADD COLUMN IF NOT EXISTS plan_id                    text        REFERENCES business.plans(id) DEFAULT 'basic',
  ADD COLUMN IF NOT EXISTS plan_activated_at          timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS plan_expires_at            timestamptz,           -- null for Basic
  ADD COLUMN IF NOT EXISTS banner_trial_days_remaining integer    DEFAULT 3,
  ADD COLUMN IF NOT EXISTS quarterly_slots_used       integer    DEFAULT 0,
  ADD COLUMN IF NOT EXISTS quarterly_slots_reset_at   date;                  -- first of next quarter

-- is_verified may already exist; ensure the column is present
ALTER TABLE business.merchants
  ADD COLUMN IF NOT EXISTS is_verified boolean DEFAULT false;

-- Back-fill plan_id for existing merchants who are null
UPDATE business.merchants SET plan_id = 'basic' WHERE plan_id IS NULL;

-- Trigger: keep is_verified in sync with plan_id
CREATE OR REPLACE FUNCTION business.sync_merchant_verified()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, public
AS $$
BEGIN
  NEW.is_verified := (NEW.plan_id = 'pro');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_merchant_verified ON business.merchants;
CREATE TRIGGER trg_sync_merchant_verified
  BEFORE INSERT OR UPDATE OF plan_id
  ON business.merchants
  FOR EACH ROW
  EXECUTE FUNCTION business.sync_merchant_verified();

-- Back-fill is_verified for existing rows
UPDATE business.merchants SET is_verified = (plan_id = 'pro');
