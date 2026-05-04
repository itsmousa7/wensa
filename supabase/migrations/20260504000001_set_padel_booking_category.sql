-- Replace granular sport categories (padel, football) with unified 'sports'.
-- Drop old constraint and replace with updated allowed values.
ALTER TABLE content.places DROP CONSTRAINT places_booking_category_check;

ALTER TABLE content.places
ADD CONSTRAINT places_booking_category_check
CHECK (booking_category = ANY (ARRAY[
  'sports'::text,
  'farm'::text,
  'restaurant'::text,
  'gym'::text,
  'membership'::text
]));

-- Migrate any existing padel/football rows to 'sports'
UPDATE content.places
SET booking_category = 'sports'
WHERE booking_category IN ('padel', 'football');

-- Set the Padel place
UPDATE content.places
SET booking_category = 'sports'
WHERE id = '1a6bafdf-5312-4cb4-ba79-29413cac9508';
