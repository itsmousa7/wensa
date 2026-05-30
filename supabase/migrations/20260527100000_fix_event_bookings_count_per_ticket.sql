-- Fix: bookings_count should count total tickets sold (rows), not unique users
CREATE OR REPLACE FUNCTION content.refresh_event_bookings_count()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  v_event_id uuid;
BEGIN
  v_event_id := COALESCE(NEW.event_id, OLD.event_id);
  IF v_event_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  UPDATE content.events
  SET bookings_count = (
    SELECT COUNT(*)
    FROM bookings.bookings
    WHERE event_id = v_event_id
      AND status IN ('confirmed', 'completed')
  )
  WHERE id = v_event_id;

  RETURN COALESCE(NEW, OLD);
END;
$function$;

-- Backfill all existing events so current counts reflect the fix
UPDATE content.events e
SET bookings_count = (
  SELECT COUNT(*)
  FROM bookings.bookings b
  WHERE b.event_id = e.id
    AND b.status IN ('confirmed', 'completed')
);
