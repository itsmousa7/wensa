-- ============================================================
-- Migration: Cascade merchant verification (Pro plan) to places
-- Date: 2026-05-26
--
-- The existing business.sync_merchant_verified trigger only keeps
-- merchants.is_verified in sync with plan_id. Places (and events,
-- handled in the prior migration) need to mirror that flag so
-- feed cards and detail pages can render the verify badge.
-- ============================================================

-- 1. Back-fill existing rows.
UPDATE content.places p
SET is_verified = COALESCE(m.is_verified, false)
FROM business.merchants m
WHERE m.id = p.merchant_id
  AND p.is_verified IS DISTINCT FROM COALESCE(m.is_verified, false);

-- 2. Trigger: keep places.is_verified in sync on insert / merchant change.
CREATE OR REPLACE FUNCTION content.sync_place_verified()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = content, business, public
AS $$
DECLARE
  v_verified boolean;
BEGIN
  IF NEW.merchant_id IS NULL THEN
    NEW.is_verified := false;
  ELSE
    SELECT COALESCE(is_verified, false) INTO v_verified
    FROM business.merchants WHERE id = NEW.merchant_id;
    NEW.is_verified := COALESCE(v_verified, false);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_place_verified ON content.places;
CREATE TRIGGER trg_sync_place_verified
  BEFORE INSERT OR UPDATE OF merchant_id
  ON content.places
  FOR EACH ROW
  EXECUTE FUNCTION content.sync_place_verified();

-- 3. Extend the merchant cascade (created in 20260526120000) to
--    also touch places when merchants.is_verified flips.
CREATE OR REPLACE FUNCTION business.cascade_merchant_verified_to_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = business, content, public
AS $$
BEGIN
  IF NEW.is_verified IS DISTINCT FROM OLD.is_verified THEN
    UPDATE content.places p
    SET is_verified = NEW.is_verified
    WHERE p.merchant_id = NEW.id;

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
