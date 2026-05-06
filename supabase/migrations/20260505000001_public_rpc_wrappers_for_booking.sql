-- Public wrappers so PostgREST can route RPC calls to bookings-schema functions
-- without requiring the bookings schema to be explicitly exposed in the API settings.

CREATE OR REPLACE FUNCTION public.create_padel_booking(
  p_place_id  uuid,
  p_court_id  uuid,
  p_starts_at timestamptz,
  p_hours     integer
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.create_padel_booking(p_place_id, p_court_id, p_starts_at, p_hours);
$$;

CREATE OR REPLACE FUNCTION public.create_farm_booking(
  p_place_id   uuid,
  p_date       date,
  p_shift_type bookings.farm_shift_type
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.create_farm_booking(p_place_id, p_date, p_shift_type);
$$;

CREATE OR REPLACE FUNCTION public.create_concert_booking(
  p_event_id  uuid,
  p_seat_ids  uuid[]
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.create_concert_booking(p_event_id, p_seat_ids);
$$;

CREATE OR REPLACE FUNCTION public.create_restaurant_booking(
  p_place_id          uuid,
  p_starts_at         timestamptz,
  p_party_size        integer,
  p_seating_option_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT bookings.create_restaurant_booking(p_place_id, p_starts_at, p_party_size, p_seating_option_id);
$$;
