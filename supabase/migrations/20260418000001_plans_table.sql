-- ============================================================
-- Migration: Plans table (subscription tiers)
-- Date: 2026-04-18
-- Project: wain_flosi
--
-- Creates business.plans with seed data for Basic / Growth / Pro.
-- Every gating decision reads from this table — no hardcoded IDs.
-- ============================================================

CREATE TABLE IF NOT EXISTS business.plans (
  id                      text        PRIMARY KEY,          -- 'basic' | 'growth' | 'pro'
  name                    text        NOT NULL,
  price_iqd               integer     NOT NULL,             -- monthly, 0 for basic
  price_usd               numeric(6,2) NOT NULL,            -- monthly, 0 for basic
  max_places              integer,                          -- null = unlimited
  max_active_events       integer,                          -- null = unlimited
  max_additional_photos   integer,                          -- null = unlimited
  has_direct_contact      boolean     NOT NULL DEFAULT false,
  has_basic_analytics     boolean     NOT NULL DEFAULT false,
  has_advanced_analytics  boolean     NOT NULL DEFAULT false,
  has_priority_placement  boolean     NOT NULL DEFAULT false,
  has_home_feed_promotion boolean     NOT NULL DEFAULT false,
  has_verified_badge      boolean     NOT NULL DEFAULT false,
  has_push_to_followers   boolean     NOT NULL DEFAULT false,
  has_scheduled_posts     boolean     NOT NULL DEFAULT false,
  has_multi_staff         boolean     NOT NULL DEFAULT false,
  max_staff_accounts      integer     NOT NULL DEFAULT 1,
  has_csv_export          boolean     NOT NULL DEFAULT false,
  has_api_access          boolean     NOT NULL DEFAULT false,
  has_priority_support    boolean     NOT NULL DEFAULT false,
  quarterly_banner_slots  integer     NOT NULL DEFAULT 0,
  trial_banner_days       integer     NOT NULL DEFAULT 0,
  sort_order              integer     NOT NULL,
  created_at              timestamptz NOT NULL DEFAULT now()
);

-- Seed the three tiers (idempotent via ON CONFLICT DO UPDATE)
INSERT INTO business.plans (
  id, name,
  price_iqd, price_usd,
  max_places, max_active_events, max_additional_photos,
  has_direct_contact, has_basic_analytics, has_advanced_analytics,
  has_priority_placement, has_home_feed_promotion, has_verified_badge,
  has_push_to_followers, has_scheduled_posts, has_multi_staff,
  max_staff_accounts, has_csv_export, has_api_access, has_priority_support,
  quarterly_banner_slots, trial_banner_days, sort_order
) VALUES
  -- Basic (Free)
  (
    'basic', 'Basic',
    0, 0.00,
    1, 1, 3,
    false, false, false,
    false, false, false,
    false, false, false,
    1, false, false, false,
    0, 3, 1
  ),
  -- Growth (~55,000 IQD / ~$39/mo)
  (
    'growth', 'Growth',
    55000, 39.00,
    NULL, NULL, NULL,
    true, true, false,
    false, false, false,
    false, false, false,
    1, false, false, false,
    0, 3, 2
  ),
  -- Pro (~130,000 IQD / ~$89/mo)
  (
    'pro', 'Pro',
    130000, 89.00,
    NULL, NULL, NULL,
    true, true, true,
    true, true, true,
    true, true, true,
    3, true, true, true,
    2, 0, 3
  )
ON CONFLICT (id) DO UPDATE SET
  name                    = EXCLUDED.name,
  price_iqd               = EXCLUDED.price_iqd,
  price_usd               = EXCLUDED.price_usd,
  max_places              = EXCLUDED.max_places,
  max_active_events       = EXCLUDED.max_active_events,
  max_additional_photos   = EXCLUDED.max_additional_photos,
  has_direct_contact      = EXCLUDED.has_direct_contact,
  has_basic_analytics     = EXCLUDED.has_basic_analytics,
  has_advanced_analytics  = EXCLUDED.has_advanced_analytics,
  has_priority_placement  = EXCLUDED.has_priority_placement,
  has_home_feed_promotion = EXCLUDED.has_home_feed_promotion,
  has_verified_badge      = EXCLUDED.has_verified_badge,
  has_push_to_followers   = EXCLUDED.has_push_to_followers,
  has_scheduled_posts     = EXCLUDED.has_scheduled_posts,
  has_multi_staff         = EXCLUDED.has_multi_staff,
  max_staff_accounts      = EXCLUDED.max_staff_accounts,
  has_csv_export          = EXCLUDED.has_csv_export,
  has_api_access          = EXCLUDED.has_api_access,
  has_priority_support    = EXCLUDED.has_priority_support,
  quarterly_banner_slots  = EXCLUDED.quarterly_banner_slots,
  trial_banner_days       = EXCLUDED.trial_banner_days,
  sort_order              = EXCLUDED.sort_order;

-- Platform-configurable settings (e.g. Pro priority placement weight)
CREATE TABLE IF NOT EXISTS business.platform_settings (
  key         text        PRIMARY KEY,
  value       text        NOT NULL,
  description text,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

INSERT INTO business.platform_settings (key, value, description) VALUES
  ('pro_priority_score_boost', '0.15', 'Added to relevance_score for Pro listings in search/map ordering'),
  ('featured_rotation_salt',   'wansa', 'Salt for daily featured-carousel hash rotation')
ON CONFLICT (key) DO NOTHING;

-- RLS: plans are read-only for all authenticated users; only service_role writes
ALTER TABLE business.plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "plans_read_all"
  ON business.plans FOR SELECT
  USING (true);

ALTER TABLE business.platform_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "platform_settings_read_authenticated"
  ON business.platform_settings FOR SELECT
  USING (auth.role() IN ('authenticated', 'anon'));

-- Grants
GRANT SELECT ON business.plans             TO anon, authenticated;
GRANT ALL    ON business.plans             TO service_role;
GRANT SELECT ON business.platform_settings TO anon, authenticated;
GRANT ALL    ON business.platform_settings TO service_role;
