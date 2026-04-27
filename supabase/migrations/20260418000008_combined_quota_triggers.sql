-- ============================================================
-- Migration: Replace separate quotas with combined places+events quota
-- Date: 2026-04-18
-- Project: wain_flosi
--
-- Combined count = visible places + active events (end_date > now()).
-- Basic: max 2 combined. Growth: max 10. Pro: unlimited.
-- Separate place/event triggers are replaced by one shared helper.
-- ============================================================

-- ── Shared helper: count combined items for a merchant ─────────────────────
CREATE OR REPLACE FUNCTION business.get_combined_item_count(p_merchant_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = business, content, public
AS $$
  SELECT
    -- Visible places
    (SELECT count(*)
     FROM content.places
     WHERE merchant_id = p_merchant_id
       AND status IS DISTINCT FROM 'hidden_due_to_downgrade')::integer
    +
    -- Active events across all merchant's places
    (SELECT count(*)
     FROM content.events e
     JOIN content.places p ON p.id = e.place_id
     WHERE p.merchant_id = p_merchant_id
       AND e.end_date > now()
       AND e.status IS DISTINCT FROM 'hidden_due_to_downgrade')::integer;
$$;

-- ── Drop old separate triggers ─────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_place_quota ON content.places;
DROP TRIGGER IF EXISTS trg_event_quota ON content.events;
-- Keep trg_photo_quota unchanged — photo quota is still separate (3 for Basic).

-- ── New combined place-insert trigger ─────────────────────────────────────
CREATE OR REPLACE FUNCTION business.enforce_combined_quota_on_place()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
DECLARE
  v_max   integer;
  v_count integer;
BEGIN
  SELECT p.max_combined_items INTO v_max
  FROM business.merchants m
  JOIN business.plans p ON p.id = m.plan_id
  WHERE m.id = NEW.merchant_id;

  IF v_max IS NULL THEN RETURN NEW; END IF; -- unlimited

  v_count := business.get_combined_item_count(NEW.merchant_id);

  IF v_count >= v_max THEN
    RAISE EXCEPTION 'PLAN_LIMIT_PLACES' USING errcode = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_place_quota
  BEFORE INSERT ON content.places
  FOR EACH ROW EXECUTE FUNCTION business.enforce_combined_quota_on_place();

-- ── New combined event-insert trigger ──────────────────────────────────────
CREATE OR REPLACE FUNCTION business.enforce_combined_quota_on_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
DECLARE
  v_merchant_id uuid;
  v_max         integer;
  v_count       integer;
BEGIN
  -- Only count future/active events toward quota
  IF NEW.end_date IS NOT NULL AND NEW.end_date <= now() THEN
    RETURN NEW; -- past event, skip quota check
  END IF;

  SELECT p.merchant_id INTO v_merchant_id
  FROM content.places p
  WHERE p.id = NEW.place_id;

  IF v_merchant_id IS NULL THEN RETURN NEW; END IF;

  SELECT pl.max_combined_items INTO v_max
  FROM business.merchants m
  JOIN business.plans pl ON pl.id = m.plan_id
  WHERE m.id = v_merchant_id;

  IF v_max IS NULL THEN RETURN NEW; END IF; -- unlimited

  v_count := business.get_combined_item_count(v_merchant_id);

  IF v_count >= v_max THEN
    RAISE EXCEPTION 'PLAN_LIMIT_EVENTS' USING errcode = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_event_quota
  BEFORE INSERT ON content.events
  FOR EACH ROW EXECUTE FUNCTION business.enforce_combined_quota_on_event();

-- ── Update downgrade visibility to use combined quota ──────────────────────
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
  v_max_combined integer;
  v_current      integer;
  v_to_hide      integer;
  v_visible_ids  uuid[];
BEGIN
  SELECT max_combined_items INTO v_max_combined
  FROM business.plans
  WHERE id = p_new_plan_id;

  -- Pro (null) or no combined limit — nothing to hide
  IF v_max_combined IS NULL THEN RETURN; END IF;

  v_current := business.get_combined_item_count(p_merchant_id);
  v_to_hide := v_current - v_max_combined;

  IF v_to_hide <= 0 THEN RETURN; END IF;

  -- Keep the oldest v_max_combined places visible; hide the rest
  SELECT ARRAY(
    SELECT id FROM content.places
    WHERE merchant_id = p_merchant_id
      AND status IS DISTINCT FROM 'hidden_due_to_downgrade'
    ORDER BY created_at ASC
    LIMIT v_max_combined
  ) INTO v_visible_ids;

  UPDATE content.places
  SET status = 'hidden_due_to_downgrade'
  WHERE merchant_id = p_merchant_id
    AND status IS DISTINCT FROM 'hidden_due_to_downgrade'
    AND id != ALL(v_visible_ids);

  -- Also hide active events on now-hidden places
  UPDATE content.events e
  SET status = 'hidden_due_to_downgrade'
  WHERE e.end_date > now()
    AND e.status IS DISTINCT FROM 'hidden_due_to_downgrade'
    AND e.place_id IN (
      SELECT id FROM content.places
      WHERE merchant_id = p_merchant_id
        AND status = 'hidden_due_to_downgrade'
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.apply_downgrade_visibility(uuid, text) TO service_role;
GRANT EXECUTE ON FUNCTION business.get_combined_item_count(uuid) TO service_role, authenticated;
