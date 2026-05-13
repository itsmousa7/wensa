-- ============================================================
-- Migration: Seed default farm shifts for all farm places
-- Date: 2026-05-11
-- ============================================================
--
-- Inserts day / night / full-day shift definitions for every
-- place whose booking_category is 'shift' or 'farm'.
-- ON CONFLICT DO NOTHING is safe to re-run.

INSERT INTO bookings.farm_shifts (place_id, shift_type, starts_time, ends_time, price_iqd)
SELECT
  p.id,
  s.shift_type::bookings.farm_shift_type,
  s.starts_time::time,
  s.ends_time::time,
  s.price_iqd
FROM content.places p
CROSS JOIN (VALUES
  ('day',   '08:00', '18:00', 100000),
  ('night', '18:00', '00:00',  75000),
  ('full',  '08:00', '00:00', 150000)
) AS s(shift_type, starts_time, ends_time, price_iqd)
WHERE p.booking_category IN ('shift', 'farm')
ON CONFLICT (place_id, shift_type) DO NOTHING;
