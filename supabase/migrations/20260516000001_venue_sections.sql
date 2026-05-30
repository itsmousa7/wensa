-- ============================================================
-- Migration: Venue sections — spatial seat-map layout
-- Date: 2026-05-16
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- Adds a spatial layer on top of the existing concert seat map:
--   venue_seat_maps gains canvas dimensions + optional background image
--   venue_sections  holds drawn section blocks (stage / label / seating)
--   venue_seats      gains section_id linking a seat to its section
--
-- A section is the drill-in unit in the mobile app. Sections carry
-- geometry (rect for v1) and a default tier_key; pricing stays
-- per-event via event_tiers joined on tier_key.
-- ============================================================

-- ── Extend venue_seat_maps with canvas metadata ───────────────────────────────
ALTER TABLE bookings.venue_seat_maps
  ADD COLUMN canvas_width         integer NOT NULL DEFAULT 1200,
  ADD COLUMN canvas_height        integer NOT NULL DEFAULT 800,
  ADD COLUMN background_image_url text;

-- ── bookings.venue_sections ───────────────────────────────────────────────────
-- Drawn section blocks. shape is a rectangle in canvas units:
-- {"type":"rect","x":int,"y":int,"w":int,"h":int}. kind controls render:
--   'seating' → contains seats, tappable, drill-in
--   'stage'   → the stage block, non-tappable
--   'label'   → a decorative labeled block (e.g. "VIP"), non-tappable
CREATE TABLE bookings.venue_sections (
  id           uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  seat_map_id  uuid     NOT NULL REFERENCES bookings.venue_seat_maps(id) ON DELETE CASCADE,
  section_key  text     NOT NULL,
  name_ar      text     NOT NULL,
  name_en      text     NOT NULL,
  kind         text     NOT NULL DEFAULT 'seating'
                          CHECK (kind IN ('seating', 'stage', 'label')),
  shape        jsonb    NOT NULL,
  fill_color   text     NOT NULL DEFAULT '#6C63FF',
  tier_key     text,
  label_x      integer,
  label_y      integer,
  sort_order   smallint NOT NULL DEFAULT 0,
  UNIQUE (seat_map_id, section_key)
);

CREATE INDEX venue_sections_map_idx ON bookings.venue_sections (seat_map_id);

-- ── Extend venue_seats with section link ──────────────────────────────────────
ALTER TABLE bookings.venue_seats
  ADD COLUMN section_id uuid REFERENCES bookings.venue_sections(id) ON DELETE SET NULL;

CREATE INDEX venue_seats_section_idx ON bookings.venue_seats (section_id);

-- Seat labels are unique per section (not per whole map) so each section
-- can carry its own A1, B2, ... grid.
ALTER TABLE bookings.venue_seats
  DROP CONSTRAINT IF EXISTS venue_seats_seat_map_id_row_label_seat_label_key;

ALTER TABLE bookings.venue_seats
  ADD CONSTRAINT venue_seats_section_seat_uniq
  UNIQUE (seat_map_id, section_id, row_label, seat_label);

-- ════════════════════════════════════════════════════════════════════════════
-- RLS — mirrors venue_seats: public read, admin-only write
-- ════════════════════════════════════════════════════════════════════════════
ALTER TABLE bookings.venue_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY venue_sections_read ON bookings.venue_sections
  FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY venue_sections_admin_write ON bookings.venue_sections
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ── Public SECURITY INVOKER view (Flutter .from('venue_sections')) ────────────
CREATE VIEW public.venue_sections
  WITH (security_invoker = true) AS SELECT * FROM bookings.venue_sections;

-- ════════════════════════════════════════════════════════════════════════════
-- RPC: available_seats — recreate with section_id added
-- ════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS bookings.available_seats(uuid);

CREATE FUNCTION bookings.available_seats(p_event_id uuid)
RETURNS TABLE (
  seat_id    uuid,
  section_id uuid,
  row_label  text,
  seat_label text,
  tier_key   text,
  x          integer,
  y          integer,
  price_iqd  integer,
  status     text       -- 'free' | 'held' | 'taken'
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, content, public
AS $$
  SELECT
    vs.id                          AS seat_id,
    vs.section_id,
    vs.row_label,
    vs.seat_label,
    vs.tier_key,
    vs.x,
    vs.y,
    et.price_iqd,
    CASE
      WHEN b.id IS NOT NULL              THEN 'taken'
      WHEN h.id IS NOT NULL              THEN 'held'
      ELSE                                    'free'
    END                            AS status
  FROM bookings.venue_seats vs
  JOIN bookings.venue_seat_maps   vsm ON vsm.id = vs.seat_map_id
  JOIN content.events             e   ON e.place_id = vsm.venue_id
  LEFT JOIN bookings.event_tiers  et  ON et.event_id = p_event_id
                                      AND et.tier_key = vs.tier_key
  LEFT JOIN bookings.bookings     b   ON b.event_id = p_event_id
                                      AND (b.category_data->>'seat_id') = vs.id::text
                                      AND b.status IN ('pending', 'confirmed', 'used')
  LEFT JOIN bookings.event_seat_holds h
                                      ON h.event_id = p_event_id
                                      AND h.seat_id = vs.id
                                      AND h.expires_at > now()
  WHERE e.id = p_event_id;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- RPC: event_venue_layout — seat map + sections (with price & free counts)
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION bookings.event_venue_layout(p_event_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, content, public
AS $$
  SELECT jsonb_build_object(
    'seat_map_id',          vsm.id,
    'canvas_width',         vsm.canvas_width,
    'canvas_height',        vsm.canvas_height,
    'background_image_url', vsm.background_image_url,
    'sections', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id',          s.id,
          'section_key', s.section_key,
          'name_ar',     s.name_ar,
          'name_en',     s.name_en,
          'kind',        s.kind,
          'shape',       s.shape,
          'fill_color',  s.fill_color,
          'tier_key',    s.tier_key,
          'label_x',     s.label_x,
          'label_y',     s.label_y,
          'sort_order',  s.sort_order,
          'price_iqd',   et.price_iqd,
          'total_count', cnt.total_count,
          'free_count',  cnt.free_count
        ) ORDER BY s.sort_order
      )
      FROM bookings.venue_sections s
      LEFT JOIN bookings.event_tiers et
             ON et.event_id = p_event_id AND et.tier_key = s.tier_key
      LEFT JOIN LATERAL (
        SELECT
          count(*)                                        AS total_count,
          count(*) FILTER (WHERE b.id IS NULL
                             AND h.id IS NULL)             AS free_count
        FROM bookings.venue_seats vs
        LEFT JOIN bookings.bookings b
               ON b.event_id = p_event_id
              AND (b.category_data->>'seat_id') = vs.id::text
              AND b.status IN ('pending', 'confirmed', 'used')
        LEFT JOIN bookings.event_seat_holds h
               ON h.event_id = p_event_id
              AND h.seat_id = vs.id
              AND h.expires_at > now()
        WHERE vs.section_id = s.id
      ) cnt ON true
      WHERE s.seat_map_id = vsm.id
    ), '[]'::jsonb)
  )
  FROM content.events e
  JOIN bookings.venue_seat_maps vsm ON vsm.venue_id = e.place_id
  WHERE e.id = p_event_id;
$$;

GRANT EXECUTE ON FUNCTION bookings.available_seats(uuid)     TO anon, authenticated;
GRANT EXECUTE ON FUNCTION bookings.event_venue_layout(uuid)  TO anon, authenticated;
