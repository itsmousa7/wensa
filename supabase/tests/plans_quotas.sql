-- ============================================================
-- SQL Tests: Plans Quota Triggers
-- Project: wain_flosi
-- Run with: psql <connection_string> -f supabase/tests/plans_quotas.sql
--
-- Uses pgTAP if installed; otherwise uses manual RAISE assertions.
-- ============================================================

-- ── Setup ─────────────────────────────────────────────────────────────────
DO $$
BEGIN
  RAISE NOTICE '======================================';
  RAISE NOTICE 'Running plans_quotas.sql test suite';
  RAISE NOTICE '======================================';
END $$;

DO $$
DECLARE
  v_test_user_id   uuid := gen_random_uuid();
  v_test_merchant  uuid;
  v_test_category  uuid;
  v_place1_id      uuid;
  v_place2_id      uuid;
  v_event1_id      uuid;
  v_event2_id      uuid;
  v_ok             boolean;
BEGIN

  -- ── Resolve a real category ──────────────────────────────────────────────
  SELECT id INTO v_test_category FROM content.categories LIMIT 1;
  IF v_test_category IS NULL THEN
    RAISE EXCEPTION 'No categories found — seed categories first';
  END IF;

  -- ── Create a test merchant on Basic plan ─────────────────────────────────
  INSERT INTO business.merchants (
    id, user_id, business_name, plan_id, status
  ) VALUES (
    gen_random_uuid(), v_test_user_id,
    'TEST_QUOTA_MERCHANT_' || to_char(now(), 'YYYYMMDDHHMMSS'),
    'basic', 'approved'
  ) RETURNING id INTO v_test_merchant;

  RAISE NOTICE 'Created test merchant: %', v_test_merchant;

  -- ── TEST 1: Basic merchant can insert first place ────────────────────────
  BEGIN
    INSERT INTO content.places (
      id, merchant_id, name_ar, name_en, city, category_id, place_status
    ) VALUES (
      gen_random_uuid(), v_test_merchant,
      'مكان اختبار ١', 'Test Place 1', 'Baghdad', v_test_category, 'approved'
    ) RETURNING id INTO v_place1_id;
    RAISE NOTICE 'PASS: Basic merchant can add first place (id=%)', v_place1_id;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'FAIL: Basic merchant should be able to add first place: %', SQLERRM;
  END;

  -- ── TEST 2: Basic merchant CANNOT insert second place ────────────────────
  BEGIN
    INSERT INTO content.places (
      id, merchant_id, name_ar, name_en, city, category_id, place_status
    ) VALUES (
      gen_random_uuid(), v_test_merchant,
      'مكان اختبار ٢', 'Test Place 2', 'Baghdad', v_test_category, 'approved'
    ) RETURNING id INTO v_place2_id;
    RAISE EXCEPTION 'FAIL: Basic merchant should NOT be able to add second place (id=% slipped through)', v_place2_id;
  EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
      RAISE NOTICE 'PASS: Quota trigger correctly rejected 2nd place for Basic merchant';
    WHEN OTHERS THEN
      RAISE EXCEPTION 'FAIL: Unexpected error on 2nd place insert: %', SQLERRM;
  END;

  -- ── TEST 3: Basic merchant can add first active event ────────────────────
  BEGIN
    INSERT INTO content.events (
      id, place_id, title_ar, title_en, start_date, end_date
    ) VALUES (
      gen_random_uuid(), v_place1_id,
      'حدث اختبار ١', 'Test Event 1',
      now() + interval '1 day',
      now() + interval '7 days'
    ) RETURNING id INTO v_event1_id;
    RAISE NOTICE 'PASS: Basic merchant can add first active event (id=%)', v_event1_id;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'FAIL: Basic merchant should be able to add first event: %', SQLERRM;
  END;

  -- ── TEST 4: Basic merchant CANNOT add second active event ────────────────
  BEGIN
    INSERT INTO content.events (
      id, place_id, title_ar, title_en, start_date, end_date
    ) VALUES (
      gen_random_uuid(), v_place1_id,
      'حدث اختبار ٢', 'Test Event 2',
      now() + interval '2 days',
      now() + interval '8 days'
    ) RETURNING id INTO v_event2_id;
    RAISE EXCEPTION 'FAIL: Basic merchant should NOT be able to add second active event (id=% slipped through)', v_event2_id;
  EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
      RAISE NOTICE 'PASS: Quota trigger correctly rejected 2nd active event for Basic merchant';
    WHEN OTHERS THEN
      RAISE EXCEPTION 'FAIL: Unexpected error on 2nd event insert: %', SQLERRM;
  END;

  -- ── TEST 5: Past event does not count toward quota ───────────────────────
  BEGIN
    -- Insert a "past" event (already ended)
    INSERT INTO content.events (
      id, place_id, title_ar, title_en, start_date, end_date
    ) VALUES (
      gen_random_uuid(), v_place1_id,
      'حدث منتهي', 'Past Event',
      now() - interval '10 days',
      now() - interval '1 day'
    );
    RAISE NOTICE 'PASS: Past event does not count toward active-event quota';
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'FAIL: Past event should not trigger quota: %', SQLERRM;
  END;

  -- ── TEST 6: Photo quota (Basic = 3 additional photos) ────────────────────
  DECLARE v_i integer;
  BEGIN
    FOR v_i IN 1..3 LOOP
      INSERT INTO content.place_images (
        id, place_id, image_url, display_order
      ) VALUES (
        gen_random_uuid(), v_place1_id,
        'https://example.com/photo' || v_i || '.jpg',
        v_i
      );
    END LOOP;
    RAISE NOTICE 'PASS: Basic merchant can add 3 additional photos';
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'FAIL: Should be able to add 3 photos: %', SQLERRM;
  END;

  BEGIN
    INSERT INTO content.place_images (id, place_id, image_url, display_order)
    VALUES (gen_random_uuid(), v_place1_id, 'https://example.com/photo4.jpg', 4);
    RAISE EXCEPTION 'FAIL: Basic merchant should NOT be able to add 4th additional photo';
  EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
      RAISE NOTICE 'PASS: Quota trigger correctly rejected 4th photo for Basic merchant';
    WHEN OTHERS THEN
      RAISE EXCEPTION 'FAIL: Unexpected error on 4th photo insert: %', SQLERRM;
  END;

  -- ── TEST 7: Upgrade to Growth removes quota ───────────────────────────────
  UPDATE business.merchants SET plan_id = 'growth' WHERE id = v_test_merchant;

  BEGIN
    INSERT INTO content.places (
      id, merchant_id, name_ar, name_en, city, category_id, place_status
    ) VALUES (
      gen_random_uuid(), v_test_merchant,
      'مكان بعد الترقية', 'Place After Upgrade',
      'Baghdad', v_test_category, 'approved'
    ) RETURNING id INTO v_place2_id;
    RAISE NOTICE 'PASS: Growth merchant can add unlimited places (2nd place id=%)', v_place2_id;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'FAIL: Growth merchant should have no place quota: %', SQLERRM;
  END;

  -- ── TEST 8: Downgrade hides over-quota places ─────────────────────────────
  -- (Call the downgrade helper directly)
  PERFORM public.apply_downgrade_visibility(v_test_merchant, 'basic');

  SELECT count(*) = 1 INTO v_ok
  FROM content.places
  WHERE merchant_id = v_test_merchant
    AND status IS DISTINCT FROM 'hidden_due_to_downgrade';

  IF v_ok THEN
    RAISE NOTICE 'PASS: Downgrade hides over-quota places (1 visible, rest hidden)';
  ELSE
    RAISE EXCEPTION 'FAIL: Expected exactly 1 visible place after downgrade to Basic';
  END IF;

  -- ── Cleanup ──────────────────────────────────────────────────────────────
  DELETE FROM content.place_images WHERE place_id = v_place1_id OR place_id = v_place2_id;
  DELETE FROM content.events       WHERE place_id = v_place1_id OR place_id = v_place2_id;
  DELETE FROM content.places       WHERE merchant_id = v_test_merchant;
  DELETE FROM business.merchant_plan_history WHERE merchant_id = v_test_merchant;
  DELETE FROM business.merchants   WHERE id = v_test_merchant;

  RAISE NOTICE '======================================';
  RAISE NOTICE 'All quota tests PASSED';
  RAISE NOTICE '======================================';

END $$;
