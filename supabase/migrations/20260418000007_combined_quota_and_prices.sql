-- ============================================================
-- Migration: Combined quota (places+events) + updated IQD prices
-- Date: 2026-04-18
-- Project: wain_flosi
--
-- Changes from user decision:
--   • Basic  → 2 combined items (places + active events total)
--   • Growth → 10 combined items
--   • Pro    → unlimited (null)
--   • Prices → IQD only: Growth 25,000 / Pro 60,000
--   • Adds max_combined_items column to business.plans
-- ============================================================

-- ── Add combined-quota column ──────────────────────────────────────────────
ALTER TABLE business.plans
  ADD COLUMN IF NOT EXISTS max_combined_items integer; -- null = unlimited

-- ── Re-seed all three plans with updated values ───────────────────────────
INSERT INTO business.plans (
  id, name,
  price_iqd, price_usd,
  max_places, max_active_events, max_additional_photos,
  max_combined_items,
  has_direct_contact, has_basic_analytics, has_advanced_analytics,
  has_priority_placement, has_home_feed_promotion, has_verified_badge,
  has_push_to_followers, has_scheduled_posts, has_multi_staff,
  max_staff_accounts, has_csv_export, has_api_access, has_priority_support,
  quarterly_banner_slots, trial_banner_days, sort_order
) VALUES
  -- Basic (Free) — 2 combined items (1+1 or 2+0 or 0+2), 3 additional photos
  (
    'basic', 'Basic',
    0, 0.00,
    NULL, NULL, 3,
    2,
    false, false, false,
    false, false, false,
    false, false, false,
    1, false, false, false,
    0, 3, 1
  ),
  -- Growth — 25,000 IQD / mo, 10 combined items
  (
    'growth', 'Growth',
    25000, 0.00,
    NULL, NULL, NULL,
    10,
    true, true, false,
    false, false, false,
    false, false, false,
    1, false, false, false,
    0, 3, 2
  ),
  -- Pro — 60,000 IQD / mo, unlimited
  (
    'pro', 'Pro',
    60000, 0.00,
    NULL, NULL, NULL,
    NULL,
    true, true, true,
    true, true, true,
    true, true, true,
    3, true, true, true,
    2, 0, 3
  )
ON CONFLICT (id) DO UPDATE SET
  price_iqd               = EXCLUDED.price_iqd,
  price_usd               = EXCLUDED.price_usd,
  max_places              = EXCLUDED.max_places,
  max_active_events       = EXCLUDED.max_active_events,
  max_additional_photos   = EXCLUDED.max_additional_photos,
  max_combined_items      = EXCLUDED.max_combined_items,
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
