-- ============================================================
-- Migration: Expose is_verified on content.events_mobile
-- Date: 2026-05-26
--
-- events_mobile is a view with an explicit column list, so the
-- new content.events.is_verified column does not flow through
-- automatically. Recreate the view so mobile queries can read
-- the verified flag (sourced from the joined merchant row).
-- ============================================================

CREATE OR REPLACE VIEW content.events_mobile AS
 SELECT e.id,
    e.place_id,
    e.merchant_id,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'title_ar'::text
            ELSE e.title_ar
        END AS title_ar,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'title_en'::text
            ELSE e.title_en
        END AS title_en,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'description_ar'::text
            ELSE e.description_ar
        END AS description_ar,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'description_en'::text
            ELSE e.description_en
        END AS description_en,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'cover_image_url'::text
            ELSE e.cover_image_url
        END AS cover_image_url,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'start_date'::text)::timestamp with time zone
            ELSE e.start_date
        END AS start_date,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'end_date'::text)::timestamp with time zone
            ELSE e.end_date
        END AS end_date,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'ticket_price'::text)::numeric
            ELSE e.ticket_price
        END AS ticket_price,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'ticket_url'::text
            ELSE e.ticket_url
        END AS ticket_url,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'city'::text
            ELSE e.city
        END AS city,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'is_featured'::text)::boolean
            ELSE e.is_featured
        END AS is_featured,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'latitude'::text)::double precision
            ELSE e.latitude
        END AS latitude,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'longitude'::text)::double precision
            ELSE e.longitude
        END AS longitude,
    e.view_count,
    e.saves_count,
    e.reviews_count,
    e.shares_count,
    e.checkins_count,
    e.hotness_score,
    e.created_at,
    e.updated_at,
    'approved'::text AS event_status,
    m.logo_url,
    COALESCE(m.is_verified, false) AS is_verified
   FROM content.events e
     LEFT JOIN business.merchants m ON m.id = e.merchant_id
  WHERE e.event_status = 'approved'::text OR e.event_status = 'pending_review'::text AND e.approved_snapshot IS NOT NULL;
