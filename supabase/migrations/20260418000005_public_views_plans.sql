-- ============================================================
-- Migration: Public views for new plans-related tables
-- Date: 2026-04-18
-- Project: wain_flosi
--
-- Adds SECURITY INVOKER views in public so Flutter's .from()
-- calls work without schema qualification.
-- ============================================================

-- Drop first to allow recreation (views are cheap to recreate)
DROP VIEW IF EXISTS public.plans;
DROP VIEW IF EXISTS public.platform_settings;
DROP VIEW IF EXISTS public.merchant_staff;
DROP VIEW IF EXISTS public.merchant_plan_history;

CREATE VIEW public.plans
  WITH (security_invoker = true) AS
  SELECT * FROM business.plans;

CREATE VIEW public.platform_settings
  WITH (security_invoker = true) AS
  SELECT * FROM business.platform_settings;

CREATE VIEW public.merchant_staff
  WITH (security_invoker = true) AS
  SELECT * FROM business.merchant_staff;

CREATE VIEW public.merchant_plan_history
  WITH (security_invoker = true) AS
  SELECT * FROM business.merchant_plan_history;

-- Grants on new views
GRANT SELECT ON public.plans                 TO anon, authenticated, service_role;
GRANT SELECT ON public.platform_settings     TO anon, authenticated, service_role;
GRANT ALL    ON public.merchant_staff        TO authenticated, service_role;
GRANT SELECT ON public.merchant_plan_history TO authenticated, service_role;
GRANT ALL    ON public.merchant_plan_history TO service_role;

-- Refresh admin_stats view to include plan distribution
DROP VIEW IF EXISTS public.admin_stats;
CREATE VIEW public.admin_stats AS
  SELECT
    (SELECT count(*) FROM business.merchants)                                        AS total_merchants,
    (SELECT count(*) FROM business.merchants WHERE status = 'pending')               AS pending_merchants,
    (SELECT count(*) FROM business.merchants WHERE status = 'approved')              AS approved_merchants,
    (SELECT count(*) FROM business.merchants WHERE plan_id = 'basic')               AS basic_plan_merchants,
    (SELECT count(*) FROM business.merchants WHERE plan_id = 'growth')              AS growth_plan_merchants,
    (SELECT count(*) FROM business.merchants WHERE plan_id = 'pro')                 AS pro_plan_merchants,
    (SELECT count(*) FROM content.places)                                            AS total_places,
    (SELECT count(*) FROM content.places WHERE place_status = 'pending_review')      AS pending_places,
    (SELECT count(*) FROM profiles.app_users)                                        AS total_users,
    (SELECT count(*) FROM profiles.reviews)                                          AS total_reviews,
    (SELECT count(*) FROM business.merchant_subscriptions WHERE status = 'active')   AS active_subscriptions;

GRANT ALL ON public.admin_stats TO service_role;

-- Update TABLE_SCHEMA map used by delete-account function
-- (No SQL needed — the delete-account function already skips plans/history tables)
