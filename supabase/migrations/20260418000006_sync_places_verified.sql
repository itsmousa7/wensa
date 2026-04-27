-- ============================================================
-- Migration: Sync content.places.is_verified from merchant plan
-- Date: 2026-04-18
-- Project: wain_flosi
--
-- When a merchant's plan changes, cascade is_verified to all
-- their places so feed queries (which already select is_verified
-- from places/places_mobile) pick it up automatically.
-- ============================================================

CREATE OR REPLACE FUNCTION business.cascade_verified_to_places()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
BEGIN
  -- Only act when is_verified actually changed
  IF NEW.is_verified IS DISTINCT FROM OLD.is_verified THEN
    UPDATE content.places
    SET is_verified = NEW.is_verified
    WHERE merchant_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cascade_verified_to_places ON business.merchants;
CREATE TRIGGER trg_cascade_verified_to_places
  AFTER UPDATE OF is_verified
  ON business.merchants
  FOR EACH ROW
  EXECUTE FUNCTION business.cascade_verified_to_places();

-- Back-fill: sync current is_verified state to all places now
UPDATE content.places p
SET is_verified = m.is_verified
FROM business.merchants m
WHERE m.id = p.merchant_id
  AND p.is_verified IS DISTINCT FROM m.is_verified;
