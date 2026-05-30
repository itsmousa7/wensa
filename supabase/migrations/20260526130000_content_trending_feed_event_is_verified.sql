-- ============================================================
-- Migration: Surface event.is_verified in content.trending_feed
-- Date: 2026-05-26
--
-- The previous fix (20260526120000_event_verified_from_merchant.sql)
-- recreated only public.trending_feed. The app actually reads from
-- content.trending_feed (via _supabase.schema('content').from('trending_feed')),
-- whose event branch still hard-coded is_verified = false. This
-- migration rebuilds content.trending_feed so verified merchants'
-- events get the badge in the Trending This Week row.
-- ============================================================

DROP VIEW IF EXISTS content.trending_feed;
CREATE VIEW content.trending_feed WITH (security_invoker = true) AS
  SELECT
    p.id,
    'place'::text                AS type,
    p.name_ar                    AS title_ar,
    p.name_en                    AS title_en,
    p.cover_image_url,
    p.city,
    p.area                       AS subtitle_ar,
    p.area                       AS subtitle_en,
    p.hotness_score,
    p.is_verified,
    p.is_featured,
    NULL::timestamp with time zone AS event_start_date,
    NULL::numeric                AS ticket_price,
    p.created_at,
    p.merchant_id
  FROM content.places_mobile p
  WHERE p.hotness_score > 0

UNION ALL

  SELECT
    e.id,
    'event'::text                AS type,
    e.title_ar,
    e.title_en,
    e.cover_image_url,
    e.city,
    to_char((e.start_date AT TIME ZONE 'Asia/Baghdad'), 'DD Mon · HH12:MI AM') AS subtitle_ar,
    to_char((e.start_date AT TIME ZONE 'Asia/Baghdad'), 'DD Mon · HH12:MI AM') AS subtitle_en,
    e.hotness_score,
    e.is_verified,
    e.is_featured,
    e.start_date                 AS event_start_date,
    e.ticket_price,
    e.created_at,
    NULL::uuid                   AS merchant_id
  FROM content.events_mobile e
  WHERE e.hotness_score > 0
    AND (e.end_date IS NULL OR e.end_date > now());

GRANT ALL ON content.trending_feed TO anon, authenticated, service_role;
