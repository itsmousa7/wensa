-- ============================================================
-- Migration: Booking schema — schema, enums, extensions
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- Creates the bookings schema plus all enum types and the two
-- required Postgres extensions (btree_gist, pg_cron).
-- ============================================================

-- ── Extensions ────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ── Schema ────────────────────────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS bookings;

-- ── Grants ────────────────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA bookings TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA bookings
  GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA bookings
  GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA bookings
  GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;

-- ── Enums ─────────────────────────────────────────────────────────────────────
CREATE TYPE bookings.booking_category AS ENUM (
  'padel',
  'football',
  'farm',
  'concert',
  'restaurant'
);

CREATE TYPE bookings.booking_status AS ENUM (
  'pending',
  'confirmed',
  'completed',
  'cancelled',
  'expired',
  'no_show',
  'used'
);

CREATE TYPE bookings.membership_status AS ENUM (
  'active',
  'frozen',
  'expired',
  'cancelled',
  'used'
);

CREATE TYPE bookings.membership_type AS ENUM (
  'gym'
  -- extensible: add new types as new categories onboard
);

CREATE TYPE bookings.farm_shift_type AS ENUM (
  'day',
  'night',
  'full'
);
