-- ============================================================
-- Migration: Booking schema — Membership tables
-- Date: 2026-04-27
-- Project: wain_flosi (qvozjwlkzordudkhamcu)
--
-- Separate from bookings.bookings for scalability (memberships
-- have different lifecycle, freeze/resume, and QR behaviour).
-- ============================================================

-- ── bookings.membership_plans ─────────────────────────────────────────────────
-- Per-place configurable plans (gym defaults: 1mo/3mo/12mo but each gym
-- can create its own list with arbitrary durations and prices).
CREATE TABLE bookings.membership_plans (
  id               uuid                      PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id         uuid                      NOT NULL REFERENCES content.places(id) ON DELETE CASCADE,
  membership_type  bookings.membership_type  NOT NULL DEFAULT 'gym',
  name_ar          text                      NOT NULL,
  name_en          text                      NOT NULL,
  duration_days    integer                   NOT NULL CHECK (duration_days > 0),
  price_iqd        integer                   NOT NULL CHECK (price_iqd > 0),
  allow_freeze     boolean                   NOT NULL DEFAULT false,
  is_active        boolean                   NOT NULL DEFAULT true,
  created_at       timestamptz               NOT NULL DEFAULT now()
);

CREATE INDEX membership_plans_place_idx
  ON bookings.membership_plans (place_id, is_active);

-- ── bookings.memberships ──────────────────────────────────────────────────────
-- Active / historical memberships.
-- Partial unique ensures a user cannot have two active/frozen memberships
-- at the same gym simultaneously.
CREATE TABLE bookings.memberships (
  id               uuid                      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid                      NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  place_id         uuid                      NOT NULL REFERENCES content.places(id) ON DELETE RESTRICT,
  merchant_id      uuid                      NOT NULL REFERENCES business.merchants(id) ON DELETE RESTRICT,
  membership_type  bookings.membership_type  NOT NULL DEFAULT 'gym',
  plan_id          uuid                      NOT NULL REFERENCES bookings.membership_plans(id),
  starts_at        date                      NOT NULL,
  ends_at          date                      NOT NULL,
  status           bookings.membership_status NOT NULL DEFAULT 'active',
  amount_iqd       integer                   NOT NULL CHECK (amount_iqd > 0),
  payment_id       text,
  payment_status   text                      NOT NULL DEFAULT 'pending'
                     CHECK (payment_status IN ('pending', 'paid', 'failed')),
  qr_token         uuid                      NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  created_at       timestamptz               NOT NULL DEFAULT now(),
  updated_at       timestamptz               NOT NULL DEFAULT now(),

  CONSTRAINT memberships_ends_after_starts CHECK (ends_at > starts_at)
);

-- Only one active or frozen membership per user per gym
CREATE UNIQUE INDEX memberships_active_uniq
  ON bookings.memberships (user_id, place_id)
  WHERE status IN ('active', 'frozen');

CREATE INDEX memberships_user_idx
  ON bookings.memberships (user_id, created_at DESC);

CREATE INDEX memberships_merchant_idx
  ON bookings.memberships (merchant_id, status);

CREATE TRIGGER trg_memberships_updated_at
  BEFORE UPDATE ON bookings.memberships
  FOR EACH ROW EXECUTE FUNCTION bookings.set_updated_at();

-- ── bookings.membership_freezes ───────────────────────────────────────────────
-- Records individual freeze periods. Resuming a freeze must extend the
-- parent membership's ends_at by the number of frozen days.
CREATE TABLE bookings.membership_freezes (
  id             uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  membership_id  uuid  NOT NULL REFERENCES bookings.memberships(id) ON DELETE CASCADE,
  starts_at      date  NOT NULL,
  ends_at        date,                        -- null = still frozen
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX membership_freezes_membership_idx
  ON bookings.membership_freezes (membership_id);
