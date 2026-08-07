-- ============================================================
-- Migration: Farm shift weekday-recurring price overrides
-- Date: 2026-08-07
-- ============================================================
--
-- Replaces the per-calendar-date override (farm_shift_price_overrides,
-- added 2026-08-06) with a per-weekday recurring rule — merchants think
-- in terms of "Thursdays and Fridays cost more," not specific dates. The
-- date-keyed table holds no real merchant data (only test rows, already
-- cleaned up) and its dashboard UI never reached a merchant, so it's
-- dropped outright rather than migrated.
--
-- weekday follows bookings.place_hours.weekday's own convention:
-- 0 = Sunday … 6 = Saturday (matches Postgres EXTRACT(DOW) and JS
-- Date.getDay()) — see supabase/migrations/20260427000002_bookings_courts_hours_pricing.sql.

DROP TABLE IF EXISTS bookings.farm_shift_price_overrides;

CREATE TABLE bookings.farm_shift_weekday_overrides (
  id         uuid                      PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id   uuid                      NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  shift_type bookings.farm_shift_type  NOT NULL,
  weekday    smallint                  NOT NULL CHECK (weekday BETWEEN 0 AND 6),
  price_iqd  integer                   NOT NULL CHECK (price_iqd > 0),
  created_at timestamptz               NOT NULL DEFAULT now(),
  UNIQUE (place_id, shift_type, weekday)
);

CREATE INDEX farm_shift_weekday_overrides_place_idx
  ON bookings.farm_shift_weekday_overrides (place_id);

ALTER TABLE bookings.farm_shift_weekday_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY farm_shift_weekday_overrides_read ON bookings.farm_shift_weekday_overrides
  FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY farm_shift_weekday_overrides_merchant_write ON bookings.farm_shift_weekday_overrides
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );
