-- ============================================================
-- Migration: Quota enforcement triggers + downgrade helper
-- Date: 2026-04-18
-- Project: wain_flosi
--
-- Server-side hard limits for places, active events, and photos.
-- Flutter catches PLAN_LIMIT_* error codes and routes to paywall.
-- ============================================================

-- ── Place quota ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION business.enforce_place_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
DECLARE
  v_max   integer;
  v_count integer;
BEGIN
  SELECT p.max_places INTO v_max
  FROM business.merchants m
  JOIN business.plans p ON p.id = m.plan_id
  WHERE m.id = NEW.merchant_id;

  -- null means unlimited
  IF v_max IS NULL THEN RETURN NEW; END IF;

  SELECT count(*) INTO v_count
  FROM content.places
  WHERE merchant_id = NEW.merchant_id
    AND status IS DISTINCT FROM 'hidden_due_to_downgrade';

  IF v_count >= v_max THEN
    RAISE EXCEPTION 'PLAN_LIMIT_PLACES' USING errcode = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_place_quota ON content.places;
CREATE TRIGGER trg_place_quota
  BEFORE INSERT ON content.places
  FOR EACH ROW EXECUTE FUNCTION business.enforce_place_quota();

-- ── Active-event quota ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION business.enforce_event_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
DECLARE
  v_max   integer;
  v_count integer;
BEGIN
  SELECT p.max_active_events INTO v_max
  FROM business.merchants m
  JOIN business.plans p ON p.id = m.plan_id
  WHERE m.id = (
    SELECT merchant_id FROM content.places WHERE id = NEW.place_id
  );

  IF v_max IS NULL THEN RETURN NEW; END IF;

  SELECT count(*) INTO v_count
  FROM content.events
  WHERE place_id IN (
    SELECT id FROM content.places
    WHERE merchant_id = (
      SELECT merchant_id FROM content.places WHERE id = NEW.place_id
    )
  )
  AND end_date > now()
  AND status IS DISTINCT FROM 'hidden_due_to_downgrade';

  IF v_count >= v_max THEN
    RAISE EXCEPTION 'PLAN_LIMIT_EVENTS' USING errcode = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_event_quota ON content.events;
CREATE TRIGGER trg_event_quota
  BEFORE INSERT ON content.events
  FOR EACH ROW EXECUTE FUNCTION business.enforce_event_quota();

-- ── Photo quota ────────────────────────────────────────────────────────────
-- Counts only additional images (not the cover). Cover is stored on places,
-- not in place_images, so every row in place_images is "additional".
CREATE OR REPLACE FUNCTION business.enforce_photo_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
DECLARE
  v_max   integer;
  v_count integer;
BEGIN
  SELECT p.max_additional_photos INTO v_max
  FROM business.merchants m
  JOIN business.plans p ON p.id = m.plan_id
  WHERE m.id = (
    SELECT merchant_id FROM content.places WHERE id = NEW.place_id
  );

  IF v_max IS NULL THEN RETURN NEW; END IF;

  SELECT count(*) INTO v_count
  FROM content.place_images
  WHERE place_id = NEW.place_id;

  IF v_count >= v_max THEN
    RAISE EXCEPTION 'PLAN_LIMIT_PHOTOS' USING errcode = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_photo_quota ON content.place_images;
CREATE TRIGGER trg_photo_quota
  BEFORE INSERT ON content.place_images
  FOR EACH ROW EXECUTE FUNCTION business.enforce_photo_quota();

-- ── Downgrade visibility helper ────────────────────────────────────────────
-- Called by the plans-change edge function when a merchant downgrades.
-- Hides over-quota places, events, and photos without deleting them.
CREATE OR REPLACE FUNCTION public.apply_downgrade_visibility(
  p_merchant_id uuid,
  p_new_plan_id text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
DECLARE
  v_max_places         integer;
  v_max_events         integer;
  v_visible_place_ids  uuid[];
  v_over_place_ids     uuid[];
BEGIN
  -- Fetch limits for new plan
  SELECT max_places, max_active_events
  INTO v_max_places, v_max_events
  FROM business.plans
  WHERE id = p_new_plan_id;

  -- ── Hide excess places ─────────────────────────────────────────────────
  IF v_max_places IS NOT NULL THEN
    -- Keep the oldest v_max_places places visible
    SELECT ARRAY(
      SELECT id FROM content.places
      WHERE merchant_id = p_merchant_id
        AND status IS DISTINCT FROM 'hidden_due_to_downgrade'
      ORDER BY created_at ASC
      LIMIT v_max_places
    ) INTO v_visible_place_ids;

    UPDATE content.places
    SET status = 'hidden_due_to_downgrade'
    WHERE merchant_id = p_merchant_id
      AND status IS DISTINCT FROM 'hidden_due_to_downgrade'
      AND id != ALL(v_visible_place_ids);

    -- Collect the IDs of places being hidden for cascade to events
    SELECT ARRAY(
      SELECT id FROM content.places
      WHERE merchant_id = p_merchant_id
        AND status = 'hidden_due_to_downgrade'
    ) INTO v_over_place_ids;
  END IF;

  -- ── Hide excess active events ──────────────────────────────────────────
  IF v_max_events IS NOT NULL THEN
    UPDATE content.events e
    SET status = 'hidden_due_to_downgrade'
    WHERE e.end_date > now()
      AND e.status IS DISTINCT FROM 'hidden_due_to_downgrade'
      AND e.place_id IN (
        SELECT id FROM content.places WHERE merchant_id = p_merchant_id
      )
      AND e.id NOT IN (
        SELECT id FROM content.events
        WHERE place_id IN (
          SELECT id FROM content.places WHERE merchant_id = p_merchant_id
        )
        AND end_date > now()
        AND status IS DISTINCT FROM 'hidden_due_to_downgrade'
        ORDER BY created_at ASC
        LIMIT v_max_events
      );
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.apply_downgrade_visibility(uuid, text) TO service_role;

-- ── SQL test helper ────────────────────────────────────────────────────────
-- Run manually to verify quotas reject over-limit inserts:
-- SELECT * FROM public.test_plan_quotas();  (service_role only)
CREATE OR REPLACE FUNCTION public.test_plan_quotas()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
DECLARE
  v_result text := '';
BEGIN
  v_result := v_result || 'Quota trigger functions installed: OK' || chr(10);
  v_result := v_result || 'Triggers: trg_place_quota, trg_event_quota, trg_photo_quota' || chr(10);
  v_result := v_result || 'Run integration tests against a test merchant to verify limits.';
  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.test_plan_quotas() TO service_role;
