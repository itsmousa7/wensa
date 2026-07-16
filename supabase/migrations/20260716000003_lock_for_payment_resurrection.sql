-- ============================================================
-- 1. Fix a dead double-booking constraint (unrelated pre-existing bug,
--    surfaced while building slot-resurrection below).
--
--    20260504000001_set_padel_booking_category.sql renamed the 'sports'
--    court category (formerly 'padel'/'football') but never updated
--    bookings_no_court_overlap's WHERE predicate to match — since then the
--    constraint has matched zero rows, so court/sports bookings have had NO
--    DB-level protection against two different users double-booking the
--    same court/time slot. Verified no currently-overlapping rows exist
--    before applying this (checked live 2026-07-16).
-- ============================================================
ALTER TABLE bookings.bookings DROP CONSTRAINT bookings_no_court_overlap;

ALTER TABLE bookings.bookings
  ADD CONSTRAINT bookings_no_court_overlap
  EXCLUDE USING gist (
    (category_data->>'court_id')        WITH =,
    tstzrange(starts_at, ends_at, '[)') WITH &&
  )
  WHERE (status IN ('pending', 'confirmed') AND category = 'sports');

-- ============================================================
-- 2. bookings.lock_for_payment — add slot resurrection.
--
--    Previous version (20260716000002) only extended a hold that was still
--    live. If the 30s cron already flipped it to 'expired', payment was
--    blocked outright even when the underlying slot/seat/table was still
--    genuinely free — forcing the user to manually restart the booking.
--
--    This version adds a slow path: when the fast (extend) path fails,
--    attempt to resurrect the SAME row for the SAME slot by replicating the
--    same availability check its create_*_booking RPC used, so a truly-free
--    slot silently becomes payable again without the user noticing. If
--    someone else has since taken it, resurrection fails safely (DB
--    constraint / capacity recheck) and the caller still gets a clean
--    "no longer available" response.
-- ============================================================
CREATE OR REPLACE FUNCTION bookings.lock_for_payment(p_kind text, p_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bookings, content, auth, public
AS $$
DECLARE
  v_uid           uuid := auth.uid();
  v_row_count     integer;
  v_group_size    integer;
  v_group_locked  integer;
  v_row           bookings.bookings%ROWTYPE;
  v_config        bookings.restaurant_config%ROWTYPE;
  v_section       bookings.venue_sections%ROWTYPE;
  v_occupied      integer;
  v_quantity      integer;
  v_seat_row      RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized' USING ERRCODE = 'P0001';
  END IF;

  IF p_kind = 'booking' THEN
    -- Fast path: hold is still live, just extend it.
    UPDATE bookings.bookings
    SET hold_until = now() + interval '5 minutes'
    WHERE id = p_id AND user_id = v_uid AND status = 'pending' AND hold_until > now();
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count > 0 THEN
      RETURN true;
    END IF;

    -- Slow path: hold already expired (cron swept it). Resurrect the same
    -- row for the same slot only if it's genuinely still free.
    SELECT * INTO v_row
    FROM bookings.bookings
    WHERE id = p_id AND user_id = v_uid AND status = 'expired' AND payment_status <> 'paid'
    FOR UPDATE;

    IF NOT FOUND THEN
      RETURN false;
    END IF;

    IF v_row.category IN ('sports', 'farm') THEN
      -- Protected by a live GIST exclusion constraint (bookings_no_court_overlap /
      -- bookings_no_farm_overlap): the UPDATE itself atomically fails if
      -- another pending/confirmed booking now overlaps this slot.
      BEGIN
        UPDATE bookings.bookings
        SET status = 'pending', hold_until = now() + interval '5 minutes'
        WHERE id = p_id;
        RETURN true;
      EXCEPTION WHEN exclusion_violation THEN
        RETURN false;
      END;

    ELSIF v_row.category = 'restaurant' THEN
      -- Mirrors create_restaurant_booking's own capacity check.
      SELECT * INTO v_config FROM bookings.restaurant_config WHERE place_id = v_row.place_id;
      IF NOT FOUND THEN
        RETURN false;
      END IF;

      SELECT COALESCE(SUM((category_data->>'party_size')::integer), 0) INTO v_occupied
      FROM bookings.bookings
      WHERE place_id = v_row.place_id
        AND category = 'restaurant'
        AND status IN ('pending', 'confirmed')
        AND id <> v_row.id
        AND tstzrange(starts_at, ends_at, '[)') && tstzrange(v_row.starts_at, v_row.ends_at, '[)');

      IF v_occupied + COALESCE((v_row.category_data->>'party_size')::integer, 0) > v_config.seats_per_slot THEN
        RETURN false;
      END IF;

      UPDATE bookings.bookings
      SET status = 'pending', hold_until = now() + interval '5 minutes'
      WHERE id = p_id;
      RETURN true;

    ELSIF v_row.category = 'concert' AND (v_row.category_data->>'admission') = 'general' THEN
      -- General admission: mirrors create_ga_booking's capacity check,
      -- including its FOR UPDATE lock on the section row.
      SELECT * INTO v_section
      FROM bookings.venue_sections
      WHERE id = (v_row.category_data->>'section_id')::uuid
      FOR UPDATE;

      IF NOT FOUND THEN
        RETURN false;
      END IF;

      SELECT COALESCE(SUM(COALESCE((category_data->>'quantity')::int, 1)), 0) INTO v_occupied
      FROM bookings.bookings
      WHERE event_id = v_row.event_id
        AND (category_data->>'section_id') = (v_row.category_data->>'section_id')
        AND status IN ('pending', 'confirmed', 'used')
        AND id <> v_row.id;

      v_quantity := COALESCE((v_row.category_data->>'quantity')::int, 1);

      IF v_occupied + v_quantity > v_section.capacity THEN
        RETURN false;
      END IF;

      UPDATE bookings.bookings
      SET status = 'pending', hold_until = now() + interval '5 minutes'
      WHERE id = p_id;
      RETURN true;

    ELSE
      -- Unrecognised category shape — fail closed rather than guess.
      RETURN false;
    END IF;

  ELSIF p_kind = 'concert_group' THEN
    SELECT count(*) INTO v_group_size
    FROM bookings.bookings WHERE group_id = p_id AND user_id = v_uid;

    IF v_group_size = 0 THEN
      RETURN false;
    END IF;

    -- Fast path: every seat's hold in the group is still live.
    SELECT count(*) INTO v_group_locked
    FROM bookings.bookings
    WHERE group_id = p_id AND user_id = v_uid AND status = 'pending' AND hold_until > now();

    IF v_group_locked = v_group_size THEN
      UPDATE bookings.bookings
      SET hold_until = now() + interval '5 minutes'
      WHERE group_id = p_id AND user_id = v_uid AND status = 'pending';

      UPDATE bookings.event_seat_holds
      SET expires_at = now() + interval '5 minutes'
      WHERE group_id = p_id AND user_id = v_uid;

      RETURN true;
    END IF;

    -- Slow path: only resurrect if every row is a clean, still-owned expiry
    -- (nothing already confirmed/cancelled — that's not a clean retry).
    PERFORM 1 FROM bookings.bookings
    WHERE group_id = p_id AND user_id = v_uid AND status NOT IN ('expired', 'pending');
    IF FOUND THEN
      RETURN false;
    END IF;

    -- bookings_concert_seat_uniq (unique index on event_id+seat_id WHERE
    -- status IN ('pending','confirmed','used')) atomically rejects this if
    -- any seat in the group was claimed by someone else in the meantime.
    BEGIN
      UPDATE bookings.bookings
      SET status = 'pending', hold_until = now() + interval '5 minutes'
      WHERE group_id = p_id AND user_id = v_uid AND status = 'expired';
    EXCEPTION WHEN unique_violation THEN
      RETURN false;
    END;

    -- Best-effort: restore the seat_holds rows too (cosmetic "held" status
    -- for other browsers; not the source of truth — bookings.bookings is).
    -- Only overwrites a stale/expired or already-ours hold, never a live
    -- hold belonging to someone else.
    FOR v_seat_row IN
      SELECT event_id, (category_data->>'seat_id')::uuid AS seat_id
      FROM bookings.bookings
      WHERE group_id = p_id AND user_id = v_uid
    LOOP
      INSERT INTO bookings.event_seat_holds (event_id, seat_id, user_id, group_id, expires_at)
      VALUES (v_seat_row.event_id, v_seat_row.seat_id, v_uid, p_id, now() + interval '5 minutes')
      ON CONFLICT (event_id, seat_id) DO UPDATE
        SET group_id   = EXCLUDED.group_id,
            user_id    = EXCLUDED.user_id,
            expires_at = EXCLUDED.expires_at
        WHERE event_seat_holds.user_id = v_uid OR event_seat_holds.expires_at < now();
    END LOOP;

    RETURN true;

  ELSIF p_kind = 'membership' THEN
    -- No hold column on memberships; the pending window is a flat 15
    -- minutes from creation, which already comfortably outlasts a payment —
    -- nothing to resurrect, only re-validate.
    RETURN EXISTS (
      SELECT 1 FROM bookings.memberships
      WHERE id             = p_id
        AND user_id        = v_uid
        AND status         = 'pending'
        AND payment_status <> 'paid'
        AND created_at     > now() - interval '15 minutes'
    );

  ELSE
    RAISE EXCEPTION 'Invalid kind: %', p_kind USING ERRCODE = 'P0002';
  END IF;
END;
$$;
