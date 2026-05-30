# Share: Places, Events & Tickets — Design

**Date:** 2026-05-29
**Status:** Approved (pending spec review)

## Goal

Let users share content from three detail pages, via the native OS share sheet
(WhatsApp, Messages, Instagram, etc.):

1. **Place details** — share a polished branded image card of the place + a text
   caption with a (placeholder) deep link, so friends can see it and later open
   it in the app.
2. **Event details** — same as place, adapted to event fields.
3. **Ticket details** — share an image of the ticket (issuer/venue name + all
   current ticket details + the live QR code), branded.

All UI must match the app's existing design language (colors, typography, RTL),
be polished, and work in both Arabic and English.

## Decisions (confirmed with user)

- **Place/Event share = image card + caption with link.** The link is a
  placeholder (`https://wensa.app/...`) until a real domain + deep-linking is set
  up later. Centralized in one constant so it's a one-line change later.
- **Ticket image includes the live scannable QR** (user accepted the implication
  that anyone with the image can scan it).
- **Branding** on all shared images: app icon + "WENSA" wordmark header.
- **Analytics:** increment `shares_count` on a successful share. Places already
  has `public.increment_share_count(uuid)`; events needs a new equivalent RPC.

## Dependencies to add

| Package         | Purpose                                                |
|-----------------|--------------------------------------------------------|
| `share_plus`    | Native share sheet (text and image/file sharing).      |
| `path_provider` | Temp directory to write the rendered PNG before share. |
| `screenshot`    | Render a widget tree to PNG bytes off-screen.          |

`http` (already a dependency) is reused to pre-fetch the place/event cover image.

## Architecture

### Rendering strategy

Shared images are produced by rendering a **dedicated, fixed-width share-card
widget off-screen** and rasterizing it at 3× pixel ratio — NOT by screenshotting
the live screen. This gives a clean, branded, scroll/theme-independent result.

- **Ticket card:** the QR (`qr_flutter`) paints synchronously; no preloading.
  A short capture `delay` (~120ms) lets the tear-line post-frame layout settle.
- **Place/Event card:** the cover is a **network** image, which does not paint
  reliably in an off-screen capture. So the cover bytes are **pre-fetched** via
  `http` and rendered with `Image.memory`. If the fetch fails, a colored
  fallback header (brand gradient + name) is used instead.

Each captured widget is wrapped in `MaterialApp`/`Theme` + `Directionality` +
`MediaQuery` so fonts, colors, and RTL render correctly in the detached tree.
The active app theme (light/dark) is passed through so the image matches what the
user sees.

### Components

**New — shared infra (`lib/core/share/`):**

- `share_service.dart` — the single entry point for all sharing:
  - `Future<Uint8List> renderToPng(BuildContext ctx, Widget card, {Size size, double pixelRatio = 3, Duration delay})`
  - `Future<ShareResult> shareImage(Uint8List png, {required String caption, String fileName})`
    — writes PNG to a temp file (`path_provider`) and calls `share_plus`.
  - `Future<ShareResult> shareText(String text)`
- `branded_header.dart` — `BrandedHeader` widget: `assets/icons/app_icon.png` +
  "WENSA" wordmark, styled with app typography. Reused by all share cards.
- `share_link.dart` — `kShareBaseUrl = 'https://wensa.app'` constant +
  `placeShareUrl(id)` / `eventShareUrl(id)` helpers. **Single place to change the
  domain later.**

**New — share cards:**

- `lib/features/places/presentation/widgets/place_share_card.dart` —
  `PlaceShareCard`: branded header, rounded cover (`Image.memory` or fallback),
  place name (locale-aware), subtitle = city/area, "Discover on Wensa" footer.
  - Note: `PlaceModel` has **no average-rating field**, so the card shows
    city/area, not a star rating.
- `lib/features/events/presentation/widgets/event_share_card.dart` —
  `EventShareCard`: same layout; subtitle = formatted event date.

**Refactor — reusable ticket card:**

- Extract the existing ticket visual from `ticket_detail_page.dart`
  (`_TicketBody`, `_TicketClipper`, `_TearLine`/`_DashPainter`, `_InfoGrid`,
  `_InfoCell`, `_CodePill`, `_CopyButton`, layout constants) into
  `lib/features/bookings_history/presentation/widgets/ticket_card.dart` as a
  public `TicketCard` widget.
  - `TicketDetailPage` uses `TicketCard` on screen (unchanged appearance).
  - A `ShareableTicketCard` wraps `TicketCard` + `BrandedHeader` at fixed width
    for the off-screen capture. The on-screen and shared visuals stay identical.

**Asset:**

- Copy `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
  → `assets/icons/app_icon.png`. The `assets/icons/` folder is already bundled in
  `pubspec.yaml`, so no manifest change is needed.

### Button wiring

- **Place & Event pages:** add a share `PlaceAppBarButton` in the SliverAppBar
  `actions`, placed before the heart. SF Symbol `square.and.arrow.up` /
  `CupertinoIcons.share`, matching the existing collapsed/expanded styling.
- **Ticket page:** add a matching share `IconButton` in the (currently empty)
  `AppBar` `actions`.
- Tap handler: show a transient busy state (disable button + spinner or a
  blocking progress overlay), render → share, then clear busy state. Failures
  show a localized `SnackBar`.

### Data flow (share action)

```
tap share
  → set busy
  → [place/event] pre-fetch cover bytes (http)        [ticket] skip
  → renderToPng(<ShareCard>)
  → shareImage(png, caption + link)                    via share_plus
  → on ShareResult != dismissed: fire-and-forget increment shares_count
  → clear busy (finally)
```

Caption examples (locale-aware):
- Place EN: `Check out {name} on Wensa!\n{placeShareUrl}`
- Place AR: `شِف {name} على ونسة!\n{placeShareUrl}`

### Analytics (`shares_count`)

- **Place:** reuse existing `public.increment_share_count(p_id uuid)`
  (updates `content.places`). Add `PlaceDetailsRepository.recordShare(placeId)`
  calling `_client.rpc('increment_share_count', params: {'p_id': placeId})`.
- **Event:** add new RPC in a migration
  `supabase/migrations/<ts>_increment_event_share_count.sql`:
  ```sql
  CREATE OR REPLACE FUNCTION public.increment_event_share_count(p_id uuid)
  RETURNS void LANGUAGE sql SECURITY DEFINER
  SET search_path = content, public AS $$
    UPDATE content.events SET shares_count = shares_count + 1 WHERE id = p_id;
  $$;
  GRANT EXECUTE ON FUNCTION public.increment_event_share_count(uuid) TO authenticated;
  -- also (re)grant places fn to be safe:
  GRANT EXECUTE ON FUNCTION public.increment_share_count(uuid) TO authenticated;
  ```
  Add `EventsRepository.recordShare(eventId)` calling the new RPC.
- Both are called fire-and-forget (`.ignore()`), only when the share was not
  dismissed (`ShareResult.status` is `success` or `unavailable`; Android often
  reports `unavailable` even on success).
- The migration file is created in the repo; **the user applies it** via their
  normal Supabase flow (not run automatically against the DB).

## Localization

All visible strings (card labels, captions, busy/error messages) follow the
existing `isArabic` / `Localizations.localeOf` pattern already used in these
pages. Cards render under the correct `Directionality`.

## Error handling

- Cover pre-fetch failure → fallback header, share still proceeds.
- Render/share failure → caught, localized `SnackBar`, busy state cleared in
  `finally`.
- `shares_count` RPC failure → ignored (analytics is best-effort).

## Out of scope

- Real deep linking (universal links / app links, associated domains,
  `assetlinks.json`, web fallback). Tracked separately; the link constant is
  ready for it.
- Per-user share de-duplication (every share counts, by design).

## Testing / verification

- `flutter analyze` clean; build runner for any new providers.
- Manual: share a place, an event, and a ticket in both EN and AR; confirm the
  image renders with branding, correct content, and (ticket) a scannable QR;
  confirm the caption + link; confirm `shares_count` increments.
