-- ============================================================
-- Migration: Schema Reorganisation
-- Date: 2026-04-07
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- Moves all 15 tables out of public into purpose-built schemas:
--   content   → places, events, categories, tags, place_tags, place_images
--   profiles  → app_users, favorites, reviews
--   business  → merchants, merchant_subscriptions, promoted_banners
--   analytics → place_views, event_views
--   admin     → admin_roles
--
-- ZERO Flutter code changes required: SECURITY INVOKER views
-- recreated in public so every .from('table') call still works.
-- RLS policies, triggers, and indexes move with their tables.
-- ============================================================

-- ============================================================
-- PHASE 1: Create new schemas
-- ============================================================
CREATE SCHEMA IF NOT EXISTS content;
CREATE SCHEMA IF NOT EXISTS profiles;
CREATE SCHEMA IF NOT EXISTS business;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS admin;

-- ============================================================
-- PHASE 2: Drop dependent views (recreated in Phase 8–9)
-- ============================================================
DROP VIEW IF EXISTS public.trending_feed;
DROP VIEW IF EXISTS public.admin_stats;
DROP VIEW IF EXISTS public.admin_users_view;

-- ============================================================
-- PHASE 3: Move tables to their new schemas
-- ============================================================

-- content: discovery content
ALTER TABLE public.categories            SET SCHEMA content;
ALTER TABLE public.tags                  SET SCHEMA content;
ALTER TABLE public.places                SET SCHEMA content;
ALTER TABLE public.events                SET SCHEMA content;
ALTER TABLE public.place_images          SET SCHEMA content;
ALTER TABLE public.place_tags            SET SCHEMA content;

-- profiles: user identity & interactions
ALTER TABLE public.app_users             SET SCHEMA profiles;
ALTER TABLE public.favorites             SET SCHEMA profiles;
ALTER TABLE public.reviews               SET SCHEMA profiles;

-- business: B2B / monetisation
ALTER TABLE public.merchants             SET SCHEMA business;
ALTER TABLE public.merchant_subscriptions SET SCHEMA business;
ALTER TABLE public.promoted_banners      SET SCHEMA business;

-- analytics: high-write telemetry
ALTER TABLE public.place_views           SET SCHEMA analytics;
ALTER TABLE public.event_views           SET SCHEMA analytics;

-- admin: internal ops only
ALTER TABLE public.admin_roles           SET SCHEMA admin;

-- ============================================================
-- PHASE 4: Grant permissions on new schemas
-- ============================================================
GRANT USAGE ON SCHEMA content   TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA profiles  TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA business  TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA analytics TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA admin     TO service_role;  -- never expose admin to clients

GRANT ALL ON ALL TABLES IN SCHEMA content   TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA profiles  TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA business  TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA analytics TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA admin     TO service_role;

-- Future tables in these schemas inherit the same grants
ALTER DEFAULT PRIVILEGES IN SCHEMA content   GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA profiles  GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA business  GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT ALL ON TABLES TO anon, authenticated, service_role;

-- ============================================================
-- PHASE 5: Fix admin functions (they hard-reference admin_roles)
-- ============================================================

-- is_admin() is used by dozens of RLS policies — fix first
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = admin, auth, public
AS $$
  SELECT EXISTS (SELECT 1 FROM admin.admin_roles WHERE user_id = auth.uid());
$$;

CREATE OR REPLACE FUNCTION public.add_admin_by_email(
  admin_email text,
  admin_permissions jsonb DEFAULT '{
    "manage_users": true,
    "manage_admins": false,
    "manage_events": true,
    "manage_places": true,
    "manage_banners": true,
    "manage_reviews": true,
    "manage_settings": true,
    "manage_merchants": true,
    "manage_categories": true
  }'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = admin, auth, public
AS $$
DECLARE
  target_user_id uuid;
BEGIN
  SELECT id INTO target_user_id FROM auth.users WHERE email = admin_email;
  IF target_user_id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not found with this email');
  END IF;
  IF EXISTS (SELECT 1 FROM admin.admin_roles WHERE user_id = target_user_id) THEN
    RETURN jsonb_build_object('error', 'User is already an admin');
  END IF;
  INSERT INTO admin.admin_roles (user_id, permissions) VALUES (target_user_id, admin_permissions);
  RETURN jsonb_build_object('success', true, 'user_id', target_user_id);
END;
$$;

-- DROP+CREATE needed to change return type safely
DROP FUNCTION IF EXISTS public.get_admin_profiles();
CREATE FUNCTION public.get_admin_profiles()
RETURNS TABLE(
  user_id         uuid,
  email           text,
  created_at      timestamptz,
  last_sign_in_at timestamptz,
  granted_at      timestamptz,
  permissions     jsonb
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = admin, auth, public
AS $$
  SELECT
    ar.user_id,
    u.email::text,
    u.created_at,
    u.last_sign_in_at,
    ar.granted_at,
    ar.permissions
  FROM admin.admin_roles ar
  JOIN auth.users u ON u.id = ar.user_id
  ORDER BY ar.granted_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.remove_admin(target_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = admin, auth, public
AS $$
BEGIN
  DELETE FROM admin.admin_roles WHERE user_id = target_user_id;
  RETURN jsonb_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_admin_permissions(target_user_id uuid, new_permissions jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = admin, auth, public
AS $$
BEGIN
  UPDATE admin.admin_roles SET permissions = new_permissions WHERE user_id = target_user_id;
  RETURN jsonb_build_object('success', true);
END;
$$;

-- ============================================================
-- PHASE 6: Fix trigger counter functions
-- Make SECURITY DEFINER so they can write to content.places
-- regardless of the calling user's RLS context
-- ============================================================

CREATE OR REPLACE FUNCTION public._sync_reviews_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = content, profiles, public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE content.places
    SET reviews_count = COALESCE(reviews_count, 0) + 1
    WHERE id = NEW.place_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE content.places
    SET reviews_count = GREATEST(COALESCE(reviews_count, 0) - 1, 0)
    WHERE id = OLD.place_id;
  END IF;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_reviews_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = content, profiles, public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE content.places SET reviews_count = reviews_count + 1 WHERE id = NEW.place_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE content.places SET reviews_count = GREATEST(reviews_count - 1, 0) WHERE id = OLD.place_id;
  END IF;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_saves_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = content, profiles, public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE content.places SET saves_count = saves_count + 1 WHERE id = NEW.place_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE content.places SET saves_count = GREATEST(saves_count - 1, 0) WHERE id = OLD.place_id;
  END IF;
  RETURN NULL;
END;
$$;

-- Update hotness + utility functions to use fully-qualified names
CREATE OR REPLACE FUNCTION public.recalculate_hotness_scores()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = content, public
AS $$
  UPDATE content.places
  SET hotness_score = (
    (view_count     * 1.0) +
    (saves_count    * 3.0) +
    (reviews_count  * 5.0) +
    (shares_count   * 4.0) +
    (checkins_count * 4.0) -
    (EXTRACT(EPOCH FROM (NOW() - created_at)) / 86400.0 * 2.0)
  );
$$;

CREATE OR REPLACE FUNCTION public.recalculate_event_hotness_scores()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = content, public
AS $$
  UPDATE content.events
  SET hotness_score = (
    (view_count     * 1.0) +
    (saves_count    * 3.0) +
    (reviews_count  * 5.0) +
    (shares_count   * 4.0) +
    (checkins_count * 4.0) -
    (EXTRACT(EPOCH FROM (NOW() - created_at)) / 86400.0 * 2.0)
  );
$$;

CREATE OR REPLACE FUNCTION public.increment_view_count(p_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = content, public
AS $$
  UPDATE content.places SET view_count = view_count + 1 WHERE id = p_id;
$$;

CREATE OR REPLACE FUNCTION public.increment_share_count(p_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = content, public
AS $$
  UPDATE content.places SET shares_count = shares_count + 1 WHERE id = p_id;
$$;

-- ============================================================
-- PHASE 7: Create SECURITY INVOKER views in public
-- The Flutter app continues using .from('places') etc. unchanged.
-- SECURITY INVOKER ensures RLS on the underlying tables is
-- evaluated as the calling user — identical behaviour to before.
-- ============================================================

-- content
CREATE VIEW public.places        WITH (security_invoker = true) AS SELECT * FROM content.places;
CREATE VIEW public.events        WITH (security_invoker = true) AS SELECT * FROM content.events;
CREATE VIEW public.categories    WITH (security_invoker = true) AS SELECT * FROM content.categories;
CREATE VIEW public.tags          WITH (security_invoker = true) AS SELECT * FROM content.tags;
CREATE VIEW public.place_tags    WITH (security_invoker = true) AS SELECT * FROM content.place_tags;
CREATE VIEW public.place_images  WITH (security_invoker = true) AS SELECT * FROM content.place_images;

-- profiles
CREATE VIEW public.app_users     WITH (security_invoker = true) AS SELECT * FROM profiles.app_users;
CREATE VIEW public.favorites     WITH (security_invoker = true) AS SELECT * FROM profiles.favorites;
CREATE VIEW public.reviews       WITH (security_invoker = true) AS SELECT * FROM profiles.reviews;

-- business
CREATE VIEW public.promoted_banners        WITH (security_invoker = true) AS SELECT * FROM business.promoted_banners;
CREATE VIEW public.merchants               WITH (security_invoker = true) AS SELECT * FROM business.merchants;
CREATE VIEW public.merchant_subscriptions  WITH (security_invoker = true) AS SELECT * FROM business.merchant_subscriptions;

-- analytics
CREATE VIEW public.place_views   WITH (security_invoker = true) AS SELECT * FROM analytics.place_views;
CREATE VIEW public.event_views   WITH (security_invoker = true) AS SELECT * FROM analytics.event_views;

-- ============================================================
-- PHASE 8: Recreate trending_feed (exact original logic,
--          now pointing at content.places / content.events)
-- ============================================================
CREATE VIEW public.trending_feed WITH (security_invoker = true) AS
  SELECT
    places.id,
    'place'::text                           AS type,
    places.name_ar                          AS title_ar,
    places.name_en                          AS title_en,
    places.cover_image_url,
    places.city,
    places.area                             AS subtitle_ar,
    places.area                             AS subtitle_en,
    places.hotness_score,
    places.is_verified,
    places.is_featured,
    NULL::timestamp with time zone          AS event_start_date,
    NULL::numeric                           AS ticket_price
  FROM content.places
  WHERE places.hotness_score > 0

UNION ALL

  SELECT
    events.id,
    'event'::text                           AS type,
    events.title_ar,
    events.title_en,
    events.cover_image_url,
    events.city,
    to_char((events.start_date AT TIME ZONE 'Asia/Baghdad'), 'DD Mon · HH12:MI AM') AS subtitle_ar,
    to_char((events.start_date AT TIME ZONE 'Asia/Baghdad'), 'DD Mon · HH12:MI AM') AS subtitle_en,
    events.hotness_score,
    false                                   AS is_verified,
    events.is_featured,
    events.start_date                       AS event_start_date,
    events.ticket_price
  FROM content.events
  WHERE events.hotness_score > 0
    AND (events.end_date IS NULL OR events.end_date > now())

  ORDER BY 9 DESC;

-- ============================================================
-- PHASE 9: Recreate admin views with qualified schema paths
-- ============================================================
CREATE VIEW public.admin_stats AS
  SELECT
    (SELECT count(*) FROM business.merchants)                                        AS total_merchants,
    (SELECT count(*) FROM business.merchants WHERE status = 'pending')               AS pending_merchants,
    (SELECT count(*) FROM business.merchants WHERE status = 'approved')              AS approved_merchants,
    (SELECT count(*) FROM content.places)                                            AS total_places,
    (SELECT count(*) FROM content.places WHERE place_status = 'pending_review')      AS pending_places,
    (SELECT count(*) FROM profiles.app_users)                                        AS total_users,
    (SELECT count(*) FROM profiles.reviews)                                          AS total_reviews,
    (SELECT count(*) FROM business.merchant_subscriptions WHERE status = 'active')   AS active_subscriptions;

CREATE VIEW public.admin_users_view AS
  SELECT
    ar.user_id,
    au.email,
    au.created_at AS auth_created_at,
    ar.granted_at
  FROM admin.admin_roles ar
  JOIN auth.users au ON au.id = ar.user_id;

-- ============================================================
-- PHASE 10: Grant permissions on all new public views
-- ============================================================
GRANT ALL ON public.places                  TO anon, authenticated, service_role;
GRANT ALL ON public.events                  TO anon, authenticated, service_role;
GRANT ALL ON public.categories              TO anon, authenticated, service_role;
GRANT ALL ON public.tags                    TO anon, authenticated, service_role;
GRANT ALL ON public.place_tags              TO anon, authenticated, service_role;
GRANT ALL ON public.place_images            TO anon, authenticated, service_role;
GRANT ALL ON public.app_users               TO anon, authenticated, service_role;
GRANT ALL ON public.favorites               TO anon, authenticated, service_role;
GRANT ALL ON public.reviews                 TO anon, authenticated, service_role;
GRANT ALL ON public.promoted_banners        TO anon, authenticated, service_role;
GRANT ALL ON public.merchants               TO anon, authenticated, service_role;
GRANT ALL ON public.merchant_subscriptions  TO anon, authenticated, service_role;
GRANT ALL ON public.place_views             TO anon, authenticated, service_role;
GRANT ALL ON public.event_views             TO anon, authenticated, service_role;
GRANT ALL ON public.trending_feed           TO anon, authenticated, service_role;
GRANT ALL ON public.admin_stats             TO service_role;
GRANT ALL ON public.admin_users_view        TO service_role;
