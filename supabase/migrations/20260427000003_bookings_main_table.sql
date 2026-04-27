-- ============================================================
-- Migration: Booking schema — unified bookings table
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- Single discriminated table for all booking categories.
-- GIST exclusion constraints prevent overbooking at the DB level.
-- ============================================================

-- ── bookings.bookings ─────────────────────────────────────────────────────────
CREATE TABLE bookings.bookings (
  id              uuid                        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid                        NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  merchant_id     uuid                        NOT NULL REFERENCES business.merchants(id) ON DELETE RESTRICT,
  place_id        uuid                        REFERENCES content.places(id) ON DELETE RESTRICT,
  event_id        uuid                        REFERENCES content.events(id) ON DELETE RESTRICT,
  category        bookings.booking_category   NOT NULL,
  status          bookings.booking_status     NOT NULL DEFAULT 'pending',
  starts_at       timestamptz                 NOT NULL,
  ends_at         timestamptz                 NOT NULL,
  amount_iqd      integer                     NOT NULL CHECK (amount_iqd >= 0),
  payment_id      text,
  payment_status  text                        NOT NULL DEFAULT 'pending'
                    CHECK (payment_status IN ('pending', 'paid', 'failed')),
  qr_token        uuid                        NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  hold_until      timestamptz,
  category_data   jsonb                       NOT NULL DEFAULT '{}',
  group_id        uuid,
  created_at      timestamptz                 NOT NULL DEFAULT now(),
  updated_at      timestamptz                 NOT NULL DEFAULT now(),

  CONSTRAINT bookings_ends_after_starts CHECK (ends_at > starts_at),
  CONSTRAINT bookings_concert_has_event CHECK (
    category <> 'concert' OR event_id IS NOT NULL
  ),
  CONSTRAINT bookings_non_concert_has_place CHECK (
    category = 'concert' OR place_id IS NOT NULL
  )
);

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE INDEX bookings_user_created_idx
  ON bookings.bookings (user_id, created_at DESC);

CREATE INDEX bookings_merchant_status_starts_idx
  ON bookings.bookings (merchant_id, status, starts_at);

CREATE INDEX bookings_place_starts_idx
  ON bookings.bookings (place_id, starts_at)
  WHERE place_id IS NOT NULL;

CREATE INDEX bookings_event_idx
  ON bookings.bookings (event_id)
  WHERE category = 'concert';

CREATE INDEX bookings_group_id_idx
  ON bookings.bookings (group_id)
  WHERE group_id IS NOT NULL;

CREATE INDEX bookings_hold_until_idx
  ON bookings.bookings (hold_until)
  WHERE status = 'pending' AND payment_status = 'pending';

-- ── GIST overbooking exclusion — Padel / Football ─────────────────────────────
-- Prevents two bookings for the same court overlapping in time.
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- idempotent safety

CREATE UNIQUE INDEX bookings_concert_seat_uniq
  ON bookings.bookings (event_id, (category_data->>'seat_id'))
  WHERE status IN ('pending', 'confirmed', 'used');

ALTER TABLE bookings.bookings
  ADD CONSTRAINT bookings_no_court_overlap
  EXCLUDE USING gist (
    (category_data->>'court_id')    WITH =,
    tstzrange(starts_at, ends_at, '[)') WITH &&
  )
  WHERE (status IN ('pending', 'confirmed') AND category IN ('padel', 'football'));

-- ── GIST overbooking exclusion — Farm ─────────────────────────────────────────
-- Prevents two farm bookings for the same place with overlapping time ranges.
-- Full-day's time range naturally overlaps with day and night shift ranges.
ALTER TABLE bookings.bookings
  ADD CONSTRAINT bookings_no_farm_overlap
  EXCLUDE USING gist (
    (place_id::text)                    WITH =,
    tstzrange(starts_at, ends_at, '[)') WITH &&
  )
  WHERE (status IN ('pending', 'confirmed') AND category = 'farm');

-- ── updated_at trigger ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bookings.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_bookings_updated_at
  BEFORE UPDATE ON bookings.bookings
  FOR EACH ROW EXECUTE FUNCTION bookings.set_updated_at();
