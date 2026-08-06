-- ============================================================
-- Migration: Farm shift per-date price overrides
-- Date: 2026-08-06
-- ============================================================
--
-- Lets a merchant set a one-off price for a specific (place, shift_type,
-- date) — a holiday, a weekend, an event — without changing the shift's
-- everyday standing price in bookings.farm_shifts. Mirrors the existing
-- per-date-exception pattern already used for opening hours
-- (bookings.place_hours_overrides winning over bookings.place_hours).

CREATE TABLE bookings.farm_shift_price_overrides (
  id         uuid                      PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id   uuid                      NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  shift_type bookings.farm_shift_type  NOT NULL,
  date       date                      NOT NULL,
  price_iqd  integer                   NOT NULL CHECK (price_iqd > 0),
  created_at timestamptz               NOT NULL DEFAULT now(),
  UNIQUE (place_id, shift_type, date)
);

CREATE INDEX farm_shift_price_overrides_place_date_idx
  ON bookings.farm_shift_price_overrides (place_id, date);

ALTER TABLE bookings.farm_shift_price_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY farm_shift_price_overrides_read ON bookings.farm_shift_price_overrides
  FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY farm_shift_price_overrides_merchant_write ON bookings.farm_shift_price_overrides
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );
