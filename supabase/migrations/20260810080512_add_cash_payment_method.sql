ALTER TABLE bookings.bookings
  ADD COLUMN payment_method text NOT NULL DEFAULT 'wayl'
    CHECK (payment_method IN ('wayl', 'cash'));

ALTER TABLE bookings.memberships
  ADD COLUMN payment_method text NOT NULL DEFAULT 'wayl'
    CHECK (payment_method IN ('wayl', 'cash'));

ALTER TABLE business.merchants
  ADD COLUMN cash_enabled boolean NOT NULL DEFAULT true;

CREATE OR REPLACE VIEW content.places_mobile AS
 SELECT p.id,
    p.merchant_id,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'category_id'::text)::uuid
            ELSE p.category_id
        END AS category_id,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'name_ar'::text
            ELSE p.name_ar
        END AS name_ar,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'name_en'::text
            ELSE p.name_en
        END AS name_en,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'description_ar'::text
            ELSE p.description_ar
        END AS description_ar,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'description_en'::text
            ELSE p.description_en
        END AS description_en,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'city'::text
            ELSE p.city
        END AS city,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'area'::text
            ELSE p.area
        END AS area,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'address_text'::text
            ELSE p.address_text
        END AS address_text,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'latitude'::text)::double precision
            ELSE p.latitude
        END AS latitude,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'longitude'::text)::double precision
            ELSE p.longitude
        END AS longitude,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'cover_image_url'::text
            ELSE p.cover_image_url
        END AS cover_image_url,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'is_new'::text)::boolean
            ELSE p.is_new
        END AS is_new,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'is_trending'::text)::boolean
            ELSE p.is_trending
        END AS is_trending,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'is_verified'::text)::boolean
            ELSE p.is_verified
        END AS is_verified,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'is_featured'::text)::boolean
            ELSE p.is_featured
        END AS is_featured,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot -> 'opening_hours'::text
            ELSE p.opening_hours
        END AS opening_hours,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'phone'::text
            ELSE p.phone
        END AS phone,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'instagram_url'::text
            ELSE p.instagram_url
        END AS instagram_url,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'website_url'::text
            ELSE p.website_url
        END AS website_url,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot -> 'additional_images'::text
            ELSE p.additional_images
        END AS additional_images,
    p.view_count,
    p.saves_count,
    p.reviews_count,
    p.shares_count,
    p.checkins_count,
    p.hotness_score,
    p.created_at,
    p.updated_at,
    'approved'::text AS place_status,
    m.logo_url,
    p.booking_category,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'city_ar'::text
            ELSE p.city_ar
        END AS city_ar,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'area_ar'::text
            ELSE p.area_ar
        END AS area_ar,
    m.cash_enabled
   FROM content.places p
     LEFT JOIN business.merchants m ON m.id = p.merchant_id
  WHERE p.place_status = 'approved'::text OR p.place_status = 'pending_review'::text AND p.approved_snapshot IS NOT NULL;

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
    COALESCE(m.is_verified, false) AS is_verified,
    e.bookings_count,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'city_ar'::text
            ELSE e.city_ar
        END AS city_ar,
    m.cash_enabled
   FROM content.events e
     LEFT JOIN business.merchants m ON m.id = e.merchant_id
  WHERE e.event_status = 'approved'::text OR e.event_status = 'pending_review'::text AND e.approved_snapshot IS NOT NULL;
