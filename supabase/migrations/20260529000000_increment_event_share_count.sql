-- supabase/migrations/20260529000000_increment_event_share_count.sql
--
-- Adds an RPC to atomically increment events.shares_count, mirroring the
-- existing public.increment_share_count(uuid) for places.

CREATE OR REPLACE FUNCTION public.increment_event_share_count(p_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = content, public
AS $$
  UPDATE content.events SET shares_count = shares_count + 1 WHERE id = p_id;
$$;

GRANT EXECUTE ON FUNCTION public.increment_event_share_count(uuid) TO authenticated;

-- Ensure the existing places function is callable by the app, too.
GRANT EXECUTE ON FUNCTION public.increment_share_count(uuid) TO authenticated;
