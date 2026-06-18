-- Guest (anon) read access for public browse content.
--
-- Apple App Store rejection 5.1.1(v): content on the homepage and place/event
-- detail pages must be viewable without an account. The home feed views
-- (events_mobile, places_mobile, trending_feed, promoted_banners_full) already
-- read for anon because they are owned by postgres (SECURITY DEFINER views).
-- These four base tables, however, only had an `authenticated`-scoped *_read
-- SELECT policy, so a guest saw an empty category bar and broken place details.
--
-- The existing *_read policies use `USING (true)` (all rows are public content),
-- so we simply mirror them for the anon role. Existing authenticated/admin
-- policies are left untouched.

create policy categories_read_anon on content.categories
  for select to anon using (true);

create policy place_images_read_anon on content.place_images
  for select to anon using (true);

create policy place_tags_read_anon on content.place_tags
  for select to anon using (true);

create policy tags_read_anon on content.tags
  for select to anon using (true);
