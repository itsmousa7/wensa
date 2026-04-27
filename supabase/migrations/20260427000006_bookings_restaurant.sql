-- ============================================================
-- Migration: Booking schema — Restaurant support tables
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
-- ============================================================

-- ── bookings.restaurant_config ────────────────────────────────────────────────
-- One row per restaurant place. seats_per_slot is the hard capacity limit
-- (sum of party_size values in a 30-min window must not exceed this).
CREATE TABLE bookings.restaurant_config (
  place_id        uuid     PRIMARY KEY REFERENCES content.places(id) ON DELETE CASCADE,
  slot_minutes    smallint NOT NULL DEFAULT 30 CHECK (slot_minutes = 30),
  seats_per_slot  integer  NOT NULL CHECK (seats_per_slot > 0)
);

-- ── bookings.restaurant_seating_options ───────────────────────────────────────
-- Optional seating preferences (indoor, outdoor, terrace, etc.) managed by
-- the merchant. Only shown to users if at least one option is active.
CREATE TABLE bookings.restaurant_seating_options (
  id        uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id  uuid    NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  label_ar  text    NOT NULL,
  label_en  text    NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);

CREATE INDEX restaurant_seating_options_place_idx
  ON bookings.restaurant_seating_options (place_id);
