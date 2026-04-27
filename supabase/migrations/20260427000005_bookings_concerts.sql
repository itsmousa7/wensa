-- ============================================================
-- Migration: Booking schema — Concert support tables
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- event_tiers: per-event ticket tiers (name, price, capacity)
-- venue_seat_maps: per-venue canvas metadata (one map per venue v1)
-- venue_seats: individual seat positions with a tier_key label
-- event_seat_holds: 60-second seat holds during checkout
--
-- Tier note: seats carry a tier_key string (e.g. "VIP"). Each
-- event_tiers row carries the same tier_key so the seat map
-- (per-venue, reused) can be priced differently per event.
-- ============================================================

-- ── bookings.event_tiers ──────────────────────────────────────────────────────
CREATE TABLE bookings.event_tiers (
  id          uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    uuid    NOT NULL REFERENCES content.events(id) ON DELETE CASCADE,
  tier_key    text    NOT NULL,          -- matches venue_seats.tier_key
  name_ar     text    NOT NULL,
  name_en     text    NOT NULL,
  price_iqd   integer NOT NULL CHECK (price_iqd >= 0),
  capacity    integer NOT NULL CHECK (capacity > 0),
  sort_order  smallint NOT NULL DEFAULT 0,
  UNIQUE (event_id, tier_key)
);

CREATE INDEX event_tiers_event_idx ON bookings.event_tiers (event_id);

-- ── bookings.venue_seat_maps ──────────────────────────────────────────────────
-- One seat map per venue (place) for v1. meta holds canvas size,
-- background image URL, and any renderer hints.
CREATE TABLE bookings.venue_seat_maps (
  id        uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id  uuid  NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  name      text  NOT NULL,
  meta      jsonb NOT NULL DEFAULT '{}',
  UNIQUE (venue_id)        -- one map per venue in v1
);

-- ── bookings.venue_seats ──────────────────────────────────────────────────────
-- Individual seat positions on a seat map. tier_key links to event_tiers
-- at query time (not a FK — tiers are per-event, seats are per-venue).
CREATE TABLE bookings.venue_seats (
  id           uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  seat_map_id  uuid    NOT NULL REFERENCES bookings.venue_seat_maps(id) ON DELETE CASCADE,
  tier_key     text    NOT NULL,
  row_label    text    NOT NULL,
  seat_label   text    NOT NULL,
  x            integer NOT NULL,
  y            integer NOT NULL,
  UNIQUE (seat_map_id, row_label, seat_label)
);

CREATE INDEX venue_seats_map_idx ON bookings.venue_seats (seat_map_id);

-- ── bookings.event_seat_holds ─────────────────────────────────────────────────
-- Temporary holds during checkout (TTL = 60 seconds from creation).
-- group_id ties multiple seat holds to a single payment transaction.
-- The partial unique index ensures only one active hold per seat per event.
CREATE TABLE bookings.event_seat_holds (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    uuid        NOT NULL REFERENCES content.events(id) ON DELETE CASCADE,
  seat_id     uuid        NOT NULL REFERENCES bookings.venue_seats(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id    uuid        NOT NULL,
  expires_at  timestamptz NOT NULL
);

-- One hold per seat per event at a time.
-- now() cannot be used in an index predicate (not immutable).
-- Uniqueness is enforced by the RPC deleting expired holds before inserting,
-- and the cron job sweeping expired holds every 30 seconds.
CREATE UNIQUE INDEX event_seat_holds_seat_uniq
  ON bookings.event_seat_holds (event_id, seat_id);

CREATE INDEX event_seat_holds_group_idx
  ON bookings.event_seat_holds (group_id);

CREATE INDEX event_seat_holds_expires_idx
  ON bookings.event_seat_holds (expires_at);
