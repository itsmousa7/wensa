-- ============================================================
-- Migration: Event-bound seat maps + General Admission sections
-- Date: 2026-05-20
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- Three changes:
--
-- 1. event_venue_layout / available_seats RPCs originally joined the
--    seat map via venue_seat_maps.venue_id = events.place_id. Concert
--    events (e.g. Kadhim Al Sahir) have a NULL place_id and the map is
--    bound to event_id directly. Both RPCs now resolve the seat map by
--    event_id first, falling back to place_id.
--
-- 2. New section kind 'general_admission' — an unreserved zone where the
--    buyer purchases a ticket without picking a seat. Each GA section
--    carries a capacity; bookings are validated against
--    (capacity - sold_count) before insert.
--
-- 3. The webhook (booking-wayl-webhook) is patched separately to read
--    merchant_id directly from the event so event-only concerts
--    (no place) can complete payment.
-- ============================================================

-- ── Section kind: add 'general_admission' ─────────────────────────────────────
ALTER TABLE bookings.venue_sections
  DROP CONSTRAINT IF EXISTS venue_sections_kind_check;

ALTER TABLE bookings.venue_sections
  ADD CONSTRAINT venue_sections_kind_check
  CHECK (kind IN ('seating', 'stage', 'label', 'general_admission'));

-- ── Capacity column (only required for GA) ────────────────────────────────────
ALTER TABLE bookings.venue_sections
  ADD COLUMN IF NOT EXISTS capacity integer;

-- ── Normalize Kadhim Al Sahir data ────────────────────────────────────────────
-- The Platinum L section was saved with tier_key='platinum' while
-- Platinum R used 'Platinum' — same tier, case-mismatched key splits
-- pricing. Normalize to 'Platinum' across sections + seats.
UPDATE bookings.venue_sections SET tier_key = 'Platinum' WHERE tier_key = 'platinum';
UPDATE bookings.venue_seats    SET tier_key = 'Platinum' WHERE tier_key = 'platinum';

-- Silver was saved as kind='stage' but the user intends it as an
-- unreserved general-admission zone. Configure capacity=500 (admin can
-- adjust via the seat-map editor).
UPDATE bookings.venue_sections
  SET kind = 'general_admission',
      tier_key = 'Silver',
      capacity = 500
  WHERE seat_map_id = '5de44390-4144-413e-b133-287236956a8e'
    AND section_key = 'silver';

-- Enforce capacity on GA sections going forward.
ALTER TABLE bookings.venue_sections
  ADD CONSTRAINT venue_sections_ga_needs_capacity
  CHECK (kind <> 'general_admission' OR (capacity IS NOT NULL AND capacity > 0));

-- ════════════════════════════════════════════════════════════════════════════
-- RPC: bookings.available_seats — accept event-bound seat maps
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
  status     text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, content, public
AS $$
  WITH map AS (
    SELECT vsm.id FROM bookings.venue_seat_maps vsm
    WHERE vsm.event_id = p_event_id
    UNION ALL
    SELECT vsm.id FROM bookings.venue_seat_maps vsm
    JOIN content.events e ON e.place_id = vsm.venue_id
    WHERE e.id = p_event_id
      AND NOT EXISTS (
        SELECT 1 FROM bookings.venue_seat_maps WHERE event_id = p_event_id
      )
    LIMIT 1
  )
  SELECT
    vs.id        AS seat_id,
    vs.section_id,
    vs.row_label,
    vs.seat_label,
    vs.tier_key,
    vs.x,
    vs.y,
    et.price_iqd,
    CASE
      WHEN b.id IS NOT NULL THEN 'taken'
      WHEN h.id IS NOT NULL THEN 'held'
      ELSE                       'free'
    END AS status
  FROM bookings.venue_seats vs
  JOIN map m ON m.id = vs.seat_map_id
  LEFT JOIN bookings.event_tiers et
         ON et.event_id = p_event_id AND et.tier_key = vs.tier_key
  LEFT JOIN bookings.bookings b
         ON b.event_id = p_event_id
        AND (b.category_data->>'seat_id') = vs.id::text
        AND b.status IN ('pending', 'confirmed', 'used')
  LEFT JOIN bookings.event_seat_holds h
         ON h.event_id = p_event_id
        AND h.seat_id = vs.id
        AND h.expires_at > now();
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- RPC: bookings.event_venue_layout — event-bound maps + GA capacity/sold
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION bookings.event_venue_layout(p_event_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, content, public
AS $$
  WITH map AS (
    SELECT vsm.* FROM bookings.venue_seat_maps vsm
    WHERE vsm.event_id = p_event_id
    UNION ALL
    SELECT vsm.* FROM bookings.venue_seat_maps vsm
    JOIN content.events e ON e.place_id = vsm.venue_id
    WHERE e.id = p_event_id
      AND NOT EXISTS (
        SELECT 1 FROM bookings.venue_seat_maps WHERE event_id = p_event_id
      )
    LIMIT 1
  )
  SELECT jsonb_build_object(
    'seat_map_id',          m.id,
    'canvas_width',         m.canvas_width,
    'canvas_height',        m.canvas_height,
    'background_image_url', m.background_image_url,
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
          'capacity',    s.capacity,
          'price_iqd',   et.price_iqd,
          'total_count', cnt.total_count,
          'free_count',  cnt.free_count,
          'sold_count',  cnt.sold_count
        ) ORDER BY s.sort_order
      )
      FROM bookings.venue_sections s
      LEFT JOIN bookings.event_tiers et
             ON et.event_id = p_event_id AND et.tier_key = s.tier_key
      LEFT JOIN LATERAL (
        SELECT
          CASE
            WHEN s.kind = 'general_admission' THEN COALESCE(s.capacity, 0)
            ELSE (SELECT count(*)::int FROM bookings.venue_seats WHERE section_id = s.id)
          END AS total_count,
          CASE
            WHEN s.kind = 'general_admission' THEN
              COALESCE(s.capacity, 0) - COALESCE((
                SELECT sum(COALESCE((b.category_data->>'quantity')::int, 1))::int
                FROM bookings.bookings b
                WHERE b.event_id = p_event_id
                  AND (b.category_data->>'section_id') = s.id::text
                  AND b.status IN ('pending', 'confirmed', 'used')
              ), 0)
            ELSE (
              SELECT count(*)::int FROM bookings.venue_seats vs2
              LEFT JOIN bookings.bookings b
                     ON b.event_id = p_event_id
                    AND (b.category_data->>'seat_id') = vs2.id::text
                    AND b.status IN ('pending', 'confirmed', 'used')
              LEFT JOIN bookings.event_seat_holds h
                     ON h.event_id = p_event_id
                    AND h.seat_id  = vs2.id
                    AND h.expires_at > now()
              WHERE vs2.section_id = s.id
                AND b.id IS NULL
                AND h.id IS NULL
            )
          END AS free_count,
          CASE
            WHEN s.kind = 'general_admission' THEN
              COALESCE((
                SELECT sum(COALESCE((b.category_data->>'quantity')::int, 1))::int
                FROM bookings.bookings b
                WHERE b.event_id = p_event_id
                  AND (b.category_data->>'section_id') = s.id::text
                  AND b.status IN ('pending', 'confirmed', 'used')
              ), 0)
            ELSE 0
          END AS sold_count
      ) cnt ON true
      WHERE s.seat_map_id = m.id
    ), '[]'::jsonb)
  )
  FROM map m;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- RPC: bookings.create_ga_booking — buy N GA tickets for a section
-- ────────────────────────────────────────────────────────────────────────────
-- Validates running sold_count + p_quantity <= capacity. Inserts a single
-- pending bookings row with a 60-second hold_until; the webhook flips it
-- to confirmed on payment success. category_data carries section_id +
-- quantity so future capacity checks can sum.
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION bookings.create_ga_booking(
  p_event_id   uuid,
  p_section_id uuid,
  p_quantity   integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, business, auth, public
AS $$
DECLARE
  v_user_id      uuid := auth.uid();
  v_section      bookings.venue_sections%ROWTYPE;
  v_tier_price   integer;
  v_sold         integer;
  v_event        content.events%ROWTYPE;
  v_merchant_id  uuid;
  v_total_iqd    integer;
  v_hold_until   timestamptz := now() + interval '60 seconds';
  v_booking_id   uuid;
  v_qr_token     uuid := gen_random_uuid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be > 0' USING ERRCODE = 'P0001';
  END IF;

  -- Lock the section row so concurrent GA buys serialise on the same row.
  SELECT * INTO v_section
  FROM bookings.venue_sections
  WHERE id = p_section_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Section not found: %', p_section_id USING ERRCODE = 'P0002';
  END IF;

  IF v_section.kind <> 'general_admission' THEN
    RAISE EXCEPTION 'Section is not general admission' USING ERRCODE = 'P0001';
  END IF;

  IF v_section.tier_key IS NULL OR v_section.tier_key = '' THEN
    RAISE EXCEPTION 'Section has no tier_key' USING ERRCODE = 'P0003';
  END IF;

  IF v_section.capacity IS NULL OR v_section.capacity <= 0 THEN
    RAISE EXCEPTION 'Section has no capacity' USING ERRCODE = 'P0003';
  END IF;

  SELECT price_iqd INTO v_tier_price
  FROM bookings.event_tiers
  WHERE event_id = p_event_id AND tier_key = v_section.tier_key;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No tier configured for tier_key: %', v_section.tier_key
      USING ERRCODE = 'P0004';
  END IF;

  -- Sum existing tickets (pending+confirmed+used) for this section.
  SELECT COALESCE(SUM(COALESCE((category_data->>'quantity')::int, 1)), 0)
    INTO v_sold
  FROM bookings.bookings
  WHERE event_id = p_event_id
    AND (category_data->>'section_id') = p_section_id::text
    AND status IN ('pending', 'confirmed', 'used');

  IF v_sold + p_quantity > v_section.capacity THEN
    RAISE EXCEPTION 'Only % tickets remaining', GREATEST(v_section.capacity - v_sold, 0)
      USING ERRCODE = 'P0005';
  END IF;

  -- Resolve merchant from the event row (event-bound maps have no place).
  SELECT * INTO v_event FROM content.events WHERE id = p_event_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found: %', p_event_id USING ERRCODE = 'P0002';
  END IF;

  v_merchant_id := v_event.merchant_id;
  IF v_merchant_id IS NULL AND v_event.place_id IS NOT NULL THEN
    SELECT merchant_id INTO v_merchant_id
    FROM content.places WHERE id = v_event.place_id;
  END IF;
  IF v_merchant_id IS NULL THEN
    RAISE EXCEPTION 'Event has no merchant' USING ERRCODE = 'P0003';
  END IF;

  v_total_iqd := v_tier_price * p_quantity;

  INSERT INTO bookings.bookings (
    user_id, merchant_id, event_id, category, status,
    starts_at, ends_at, amount_iqd, payment_status,
    qr_token, hold_until, category_data
  ) VALUES (
    v_user_id, v_merchant_id, p_event_id, 'concert', 'pending',
    v_event.start_date, v_event.end_date, v_total_iqd, 'pending',
    v_qr_token, v_hold_until,
    jsonb_build_object(
      'section_id', p_section_id,
      'tier_key',   v_section.tier_key,
      'quantity',   p_quantity,
      'admission',  'general'
    )
  )
  RETURNING id INTO v_booking_id;

  RETURN jsonb_build_object(
    'id',          v_booking_id,
    'total_iqd',   v_total_iqd,
    'quantity',    p_quantity,
    'hold_until',  v_hold_until
  );
END;
$$;

GRANT EXECUTE ON FUNCTION bookings.available_seats(uuid)        TO anon, authenticated;
GRANT EXECUTE ON FUNCTION bookings.event_venue_layout(uuid)     TO anon, authenticated;
GRANT EXECUTE ON FUNCTION bookings.create_ga_booking(uuid, uuid, integer) TO authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- Seed event_tiers for Kadhim Al Sahir (price_iqd=0 — admin sets via UI)
-- ════════════════════════════════════════════════════════════════════════════
INSERT INTO bookings.event_tiers (event_id, tier_key, name_ar, name_en, price_iqd, capacity, sort_order)
VALUES
  ('bbb2be6b-957e-4e77-8b85-f0983d8ad627', 'Silver',     'سيلفر',     'Silver',     0, 500,  1),
  ('bbb2be6b-957e-4e77-8b85-f0983d8ad627', 'Best Seats', 'أفضل المقاعد', 'Best Seats', 0, 286,  2),
  ('bbb2be6b-957e-4e77-8b85-f0983d8ad627', 'Gold',       'ذهبي',      'Gold',       0, 74,   3),
  ('bbb2be6b-957e-4e77-8b85-f0983d8ad627', 'VIP',        'كبار الشخصيات', 'VIP',     0, 540,  4),
  ('bbb2be6b-957e-4e77-8b85-f0983d8ad627', 'Platinum',   'بلاتينيوم', 'Platinum',   0, 432,  5)
ON CONFLICT DO NOTHING;
