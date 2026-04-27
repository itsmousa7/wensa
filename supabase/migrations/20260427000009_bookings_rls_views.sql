-- ============================================================
-- Migration: Booking schema — RLS policies + public views
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- RLS:
--   Customer    → own rows only (select/insert); update via RPCs only
--   Merchant    → rows where merchant_id matches their membership
--   Admin       → full access
--
-- Public SECURITY INVOKER views follow the existing project convention
-- so Flutter can call .from('bookings') without schema prefix.
-- ============================================================

-- ── Enable RLS ────────────────────────────────────────────────────────────────
ALTER TABLE bookings.bookings                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.memberships              ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.courts                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.place_hours              ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.place_hours_overrides    ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.place_pricing            ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.farm_shifts              ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.farm_settings            ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.event_tiers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.venue_seat_maps          ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.venue_seats              ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.event_seat_holds         ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.restaurant_config        ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.restaurant_seating_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.membership_plans         ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings.membership_freezes       ENABLE ROW LEVEL SECURITY;

-- ── Helper: is the caller a merchant staff member for a given merchant? ────────
CREATE OR REPLACE FUNCTION bookings.is_merchant_staff_of(p_merchant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = business, auth, public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM business.merchant_staff
    WHERE user_id = auth.uid() AND merchant_id = p_merchant_id
  );
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- bookings.bookings RLS
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY bookings_customer_select ON bookings.bookings
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY bookings_merchant_select ON bookings.bookings
  FOR SELECT TO authenticated
  USING (bookings.is_merchant_staff_of(merchant_id));

CREATE POLICY bookings_customer_insert ON bookings.bookings
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY bookings_admin_all ON bookings.bookings
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- ════════════════════════════════════════════════════════════════════════════
-- bookings.memberships RLS
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY memberships_customer_select ON bookings.memberships
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY memberships_merchant_select ON bookings.memberships
  FOR SELECT TO authenticated
  USING (bookings.is_merchant_staff_of(merchant_id));

CREATE POLICY memberships_customer_insert ON bookings.memberships
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY memberships_admin_all ON bookings.memberships
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- ════════════════════════════════════════════════════════════════════════════
-- Read-only public data: courts, hours, pricing, tiers, seats, shifts, etc.
-- Authenticated users can read; only merchant staff / admin can write.
-- ════════════════════════════════════════════════════════════════════════════

-- courts
CREATE POLICY courts_read ON bookings.courts
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY courts_merchant_write ON bookings.courts
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- place_hours
CREATE POLICY place_hours_read ON bookings.place_hours
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY place_hours_merchant_write ON bookings.place_hours
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- place_hours_overrides
CREATE POLICY place_hours_overrides_read ON bookings.place_hours_overrides
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY place_hours_overrides_merchant_write ON bookings.place_hours_overrides
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- place_pricing
CREATE POLICY place_pricing_read ON bookings.place_pricing
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY place_pricing_merchant_write ON bookings.place_pricing
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- farm_shifts
CREATE POLICY farm_shifts_read ON bookings.farm_shifts
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY farm_shifts_merchant_write ON bookings.farm_shifts
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- farm_settings
CREATE POLICY farm_settings_read ON bookings.farm_settings
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY farm_settings_merchant_write ON bookings.farm_settings
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- event_tiers
CREATE POLICY event_tiers_read ON bookings.event_tiers
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY event_tiers_admin_write ON bookings.event_tiers
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- venue_seat_maps
CREATE POLICY venue_seat_maps_read ON bookings.venue_seat_maps
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY venue_seat_maps_admin_write ON bookings.venue_seat_maps
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- venue_seats
CREATE POLICY venue_seats_read ON bookings.venue_seats
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY venue_seats_admin_write ON bookings.venue_seats
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- event_seat_holds: each user sees only their own holds
CREATE POLICY event_seat_holds_owner ON bookings.event_seat_holds
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY event_seat_holds_insert ON bookings.event_seat_holds
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- restaurant_config
CREATE POLICY restaurant_config_read ON bookings.restaurant_config
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY restaurant_config_merchant_write ON bookings.restaurant_config
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- restaurant_seating_options
CREATE POLICY restaurant_seating_options_read ON bookings.restaurant_seating_options
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY restaurant_seating_options_merchant_write ON bookings.restaurant_seating_options
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- membership_plans
CREATE POLICY membership_plans_read ON bookings.membership_plans
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY membership_plans_merchant_write ON bookings.membership_plans
  FOR ALL TO authenticated
  USING (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  )
  WITH CHECK (
    public.is_admin() OR
    bookings.is_merchant_staff_of(bookings._place_merchant(place_id))
  );

-- membership_freezes: owner only
CREATE POLICY membership_freezes_owner ON bookings.membership_freezes
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM bookings.memberships m
      WHERE m.id = membership_id AND (m.user_id = auth.uid() OR public.is_admin())
    )
  );
CREATE POLICY membership_freezes_admin_all ON bookings.membership_freezes
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- ════════════════════════════════════════════════════════════════════════════
-- Public SECURITY INVOKER views (Flutter .from('...') compatibility)
-- ════════════════════════════════════════════════════════════════════════════
CREATE VIEW public.bookings
  WITH (security_invoker = true) AS SELECT * FROM bookings.bookings;

CREATE VIEW public.memberships_view
  WITH (security_invoker = true) AS SELECT * FROM bookings.memberships;

CREATE VIEW public.courts
  WITH (security_invoker = true) AS SELECT * FROM bookings.courts;

CREATE VIEW public.place_hours
  WITH (security_invoker = true) AS SELECT * FROM bookings.place_hours;

CREATE VIEW public.place_hours_overrides
  WITH (security_invoker = true) AS SELECT * FROM bookings.place_hours_overrides;

CREATE VIEW public.place_pricing
  WITH (security_invoker = true) AS SELECT * FROM bookings.place_pricing;

CREATE VIEW public.farm_shifts
  WITH (security_invoker = true) AS SELECT * FROM bookings.farm_shifts;

CREATE VIEW public.farm_settings
  WITH (security_invoker = true) AS SELECT * FROM bookings.farm_settings;

CREATE VIEW public.event_tiers
  WITH (security_invoker = true) AS SELECT * FROM bookings.event_tiers;

CREATE VIEW public.venue_seat_maps
  WITH (security_invoker = true) AS SELECT * FROM bookings.venue_seat_maps;

CREATE VIEW public.venue_seats
  WITH (security_invoker = true) AS SELECT * FROM bookings.venue_seats;

CREATE VIEW public.restaurant_config
  WITH (security_invoker = true) AS SELECT * FROM bookings.restaurant_config;

CREATE VIEW public.restaurant_seating_options
  WITH (security_invoker = true) AS SELECT * FROM bookings.restaurant_seating_options;

CREATE VIEW public.membership_plans
  WITH (security_invoker = true) AS SELECT * FROM bookings.membership_plans;
