-- ============================================================
-- Migration: Booking schema — Padel/Football support tables
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- Courts, opening hours (weekly + overrides), and pricing.
-- These are referenced in the main bookings table's GIST exclusion
-- so they must exist before migration 3.
-- ============================================================

-- ── bookings.courts ───────────────────────────────────────────────────────────
CREATE TABLE bookings.courts (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id    uuid        NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  name_ar     text        NOT NULL,
  name_en     text        NOT NULL,
  sort_order  smallint    NOT NULL DEFAULT 0,
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX courts_place_id_idx ON bookings.courts (place_id);

-- ── bookings.place_hours ──────────────────────────────────────────────────────
-- Weekly schedule per place (and optionally per court).
-- weekday: 0 = Sunday … 6 = Saturday (matches JS convention).
CREATE TABLE bookings.place_hours (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id    uuid        NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  court_id    uuid        REFERENCES bookings.courts(id) ON DELETE CASCADE,
  weekday     smallint    NOT NULL CHECK (weekday BETWEEN 0 AND 6),
  opens_at    time        NOT NULL,
  closes_at   time        NOT NULL,
  is_closed   boolean     NOT NULL DEFAULT false,
  UNIQUE (place_id, court_id, weekday)
);

CREATE INDEX place_hours_place_idx ON bookings.place_hours (place_id);

-- ── bookings.place_hours_overrides ────────────────────────────────────────────
-- Date-specific overrides (holidays, special events, etc.).
CREATE TABLE bookings.place_hours_overrides (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id    uuid        NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  court_id    uuid        REFERENCES bookings.courts(id) ON DELETE CASCADE,
  date        date        NOT NULL,
  opens_at    time,
  closes_at   time,
  is_closed   boolean     NOT NULL DEFAULT false,
  UNIQUE (place_id, court_id, date)
);

CREATE INDEX place_hours_overrides_place_date_idx
  ON bookings.place_hours_overrides (place_id, date);

-- ── bookings.place_pricing ────────────────────────────────────────────────────
-- Hourly rate per place (and optionally per court).
-- court_id IS NULL means the rate applies to all courts at the place.
CREATE TABLE bookings.place_pricing (
  id               uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id         uuid    NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  court_id         uuid    REFERENCES bookings.courts(id) ON DELETE CASCADE,
  hourly_rate_iqd  integer NOT NULL CHECK (hourly_rate_iqd > 0),
  UNIQUE (place_id, court_id)
);
