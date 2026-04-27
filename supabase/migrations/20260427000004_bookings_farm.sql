-- ============================================================
-- Migration: Booking schema — Farm support tables
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
-- ============================================================

-- ── bookings.farm_shifts ──────────────────────────────────────────────────────
-- Defines the day / night / full shift windows and pricing per farm (place).
-- The starts_time / ends_time define the actual time range for the shift on a
-- given date. Full day booking uses a range that encompasses both day + night,
-- which allows the GIST exclusion to correctly block overlapping shifts.
CREATE TABLE bookings.farm_shifts (
  id          uuid                      PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id    uuid                      NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  shift_type  bookings.farm_shift_type  NOT NULL,
  starts_time time                      NOT NULL,
  ends_time   time                      NOT NULL,
  price_iqd   integer                   NOT NULL CHECK (price_iqd > 0),
  UNIQUE (place_id, shift_type)
);

CREATE INDEX farm_shifts_place_idx ON bookings.farm_shifts (place_id);

-- ── bookings.farm_settings ────────────────────────────────────────────────────
-- Per-farm optional settings. Row created by merchant when enabling bookings.
CREATE TABLE bookings.farm_settings (
  place_id          uuid    PRIMARY KEY REFERENCES content.places(id) ON DELETE CASCADE,
  multi_day_allowed boolean NOT NULL DEFAULT false
);
