-- ============================================================
-- Migration: Propagate merchant verification (Pro plan) to events
-- Date: 2026-05-26
--
-- Mirrors the places.is_verified pattern: an event is considered
-- "verified" when its owning merchant is on the Pro plan
-- (business.merchants.is_verified = true). The flag is denormalised
-- onto content.events so existing views/queries (events_mobile,
-- trending_feed, etc.) can surface it without joins.
-- ============================================================

-- 1. Column ----------------------------------------------------
ALTER TABLE content.events
  ADD COLUMN IF NOT EXISTS is_verified boolean NOT NULL DEFAULT false;

-- 2. Back-fill from current merchant state ---------------------
-- Resolve merchant either directly (events.merchant_id) or via the
-- event's place (content.places.merchant_id).
UPDATE content.events e
SET is_verified = COALESCE(m.is_verified, false)
FROM business.merchants m
WHERE m.id = COALESCE(
  e.merchant_id,
  (SELECT p.merchant_id FROM content.places p WHERE p.id = e.place_id)
);

-- 3. Trigger: keep event.is_verified in sync when the event row
--    is inserted or its merchant/place link changes.
CREATE OR REPLACE FUNCTION content.sync_event_verified()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = content, business, public
AS $$
DECLARE
  v_merchant_id uuid;
  v_verified    boolean;
BEGIN
  v_merchant_id := NEW.merchant_id;
  IF v_merchant_id IS NULL AND NEW.place_id IS NOT NULL THEN
    SELECT merchant_id INTO v_merchant_id
    FROM content.places WHERE id = NEW.place_id;
  END IF;

  IF v_merchant_id IS NULL THEN
    NEW.is_verified := false;
  ELSE
    SELECT COALESCE(is_verified, false) INTO v_verified
    FROM business.merchants WHERE id = v_merchant_id;
    NEW.is_verified := COALESCE(v_verified, false);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_event_verified ON content.events;
CREATE TRIGGER trg_sync_event_verified
  BEFORE INSERT OR UPDATE OF merchant_id, place_id
  ON content.events
  FOR EACH ROW
  EXECUTE FUNCTION content.sync_event_verified();

-- 4. Cascade: when a merchant's verified flag flips (Pro upgrade
--    or downgrade), update every event owned by that merchant —
--    both directly (events.merchant_id) and indirectly (via the
--    event's place).
CREATE OR REPLACE FUNCTION business.cascade_merchant_verified_to_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
BEGIN
  IF NEW.is_verified IS DISTINCT FROM OLD.is_verified THEN
    UPDATE content.events e
    SET is_verified = NEW.is_verified
    WHERE e.merchant_id = NEW.id
       OR e.place_id IN (
         SELECT p.id FROM content.places p WHERE p.merchant_id = NEW.id
       );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cascade_merchant_verified_to_events ON business.merchants;
CREATE TRIGGER trg_cascade_merchant_verified_to_events
  AFTER UPDATE OF is_verified
  ON business.merchants
  FOR EACH ROW
  EXECUTE FUNCTION business.cascade_merchant_verified_to_events();

-- 5. Recreate trending_feed so the events branch surfaces the real
--    verified flag instead of the hard-coded `false` from the
--    20260407 schema-reorg migration. Mirrors the original logic;
--    only the events branch's `is_verified` column changes.
DROP VIEW IF EXISTS public.trending_feed;
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
    events.is_verified,
    events.is_featured,
    events.start_date                       AS event_start_date,
    events.ticket_price
  FROM content.events
  WHERE events.hotness_score > 0
    AND (events.end_date IS NULL OR events.end_date > now())

  ORDER BY 9 DESC;

GRANT ALL ON public.trending_feed TO anon, authenticated, service_role;
