# Booking Feature — Implementation Summary & Remaining Work

## What Was Built

Full customer-facing booking system for the Wensa Flutter app, covering 5 venue/event categories, a bookings history screen, QR tickets, FCM push notifications, and bilingual (AR/EN) UI.

---

## Files Added (37 Dart files + migration)

### Domain layer
| File | Purpose |
|------|---------|
| `lib/features/booking/domain/models/booking_enums.dart` | 5 enums: `BookingCategory`, `BookingStatus`, `FarmShiftType`, `MembershipStatus`, `SeatStatus` with `fromString` extensions |
| `lib/features/booking/domain/models/booking.dart` | Freezed `Booking` model |
| `lib/features/booking/domain/models/court.dart` | Padel/football court |
| `lib/features/booking/domain/models/slot.dart` | Time slot |
| `lib/features/booking/domain/models/farm_shift.dart` | Farm day/night/full shift |
| `lib/features/booking/domain/models/event_tier.dart` | Concert pricing tier |
| `lib/features/booking/domain/models/seat.dart` | Concert seat with x/y coordinates |
| `lib/features/booking/domain/models/seat_hold.dart` | Seat hold response |
| `lib/features/booking/domain/models/membership.dart` | Active membership record |
| `lib/features/booking/domain/models/membership_plan.dart` | Purchasable membership plan |
| `lib/features/booking/domain/models/restaurant_seating_option.dart` | Restaurant seating preference |
| `lib/features/booking/domain/repositories/booking_repository.dart` | 13-method Supabase repository; schema-qualified RPCs via `.schema('bookings').rpc(...)` |

### Presentation — providers
| File | Purpose |
|------|---------|
| `lib/features/booking/presentation/providers/availability_provider.dart` | Courts, slots, farm shifts, tiers, seats, seating options, membership plans |
| `lib/features/booking/presentation/providers/booking_submit_provider.dart` | Freezed state machine; calls `create-booking` edge function; opens Wayl payment URL |
| `lib/features/booking/presentation/providers/hold_provider.dart` | 1-second countdown timer; disposes cleanly on widget exit |
| `lib/features/booking/presentation/providers/membership_submit_provider.dart` | Create / freeze / resume membership |

### Presentation — sections (booking flows)
| File | Category |
|------|---------|
| `lib/features/booking/presentation/sections/padel_section.dart` | Padel & football |
| `lib/features/booking/presentation/sections/farm_section.dart` | Farm |
| `lib/features/booking/presentation/sections/restaurant_section.dart` | Restaurant (pending-confirmation flow, no payment URL) |
| `lib/features/booking/presentation/sections/membership_section.dart` | Gym memberships |
| `lib/features/booking/presentation/sections/concert_section.dart` | Concerts (interactive seat map, 60-second hold timer) |

### Presentation — widgets
| File | Purpose |
|------|---------|
| `lib/features/booking/presentation/booking_flow_page.dart` | Entry page; routes to the correct section via `category` query param |
| `lib/features/booking/presentation/widgets/slot_grid.dart` | Available / selected / taken slot chips |
| `lib/features/booking/presentation/widgets/shift_card.dart` | Farm shift card (day / night / full) |
| `lib/features/booking/presentation/widgets/seat_map.dart` | 1200×800 interactive seat map (`InteractiveViewer` + `Stack`) |
| `lib/features/booking/presentation/widgets/tier_legend.dart` | Scrollable tier chips |
| `lib/features/booking/presentation/widgets/hold_countdown_banner.dart` | Amber banner; shows "expired" at 0 |
| `lib/features/booking/presentation/widgets/membership_plan_card.dart` | Plan card |
| `lib/features/booking/presentation/widgets/bilingual_label.dart` | AR/EN switcher using `Localizations.localeOf` |

### Bookings history
| File | Purpose |
|------|---------|
| `lib/features/bookings_history/domain/repositories/tickets_repository.dart` | Thin wrapper over `BookingRepository` |
| `lib/features/bookings_history/presentation/providers/tickets_provider.dart` | `userBookingsProvider`, `userMembershipsProvider`, `bookingDetailProvider` |
| `lib/features/bookings_history/presentation/pages/bookings_history_page.dart` | 6-tab list (All / Padel-Football / Farm / Concerts / Restaurant / Memberships) |
| `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart` | Full ticket detail card + QR code |
| `lib/features/bookings_history/presentation/widgets/ticket_card.dart` | List card for one booking or membership |
| `lib/features/bookings_history/presentation/widgets/ticket_status_badge.dart` | Coloured status chip |
| `lib/features/bookings_history/presentation/widgets/qr_block.dart` | `QrImageView` for `MERCHANT_PORTAL_URL/scan/{qr_token}` |

### Notifications
| File | Purpose |
|------|---------|
| `lib/features/notifications/fcm_service.dart` | Singleton; requests permission, saves FCM token to Supabase, handles foreground messages and tap-to-navigate |

### Infrastructure
| File | Purpose |
|------|---------|
| `supabase/migrations/20260427000011_add_fcm_token.sql` | Adds `fcm_token text` column + index to `profiles.app_users` |

### Modified files
- `lib/core/router/router_names.dart` — added `bookingFlow`, `eventBookingFlow`, `bookingsHistory`, `ticketDetail`
- `lib/core/router/router_provider.dart` — added 4 routes + redirect guards + FCM pending-route consumption
- `lib/main.dart` — guarded Firebase init + `FcmService.instance.initialize(...)`
- `pubspec.yaml` — added `qr_flutter`, `intl`, `firebase_core`, `firebase_messaging`
- `.env` — added `MERCHANT_PORTAL_URL=http://localhost:5173`

---

## Key Design Decisions

| Decision | Reason |
|----------|--------|
| Category routed via `?category=` query param | Place category IDs are UUIDs; avoids a DB round-trip just to get the category name |
| Concert hold timer reset on every seat toggle | Client generates `now + 60s`; simpler than server coordination |
| Hold only released on explicit exit or timer expiry | Per user requirement — not on app background |
| Restaurant shows pending screen (no QR) | No payment URL returned; booking requires merchant confirmation |
| Membership ID prefixed `m_` in router | Distinguishes memberships from bookings on the `/bookings/:id` route |
| Schema-qualified RPCs: `.schema('bookings').rpc(...)` | PostgREST does not support dotted-schema notation like `bookings.fn_name` |

---

## Remaining To-Do Before Ship

### 1. Firebase native setup (required for FCM)
- [ ] Run `flutterfire configure` in the project root to generate `lib/firebase_options.dart` and the native config files (`google-services.json`, `GoogleService-Info.plist`).
- [ ] In `lib/main.dart`, update the Firebase init call to pass the generated options:
  ```dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ```
- [ ] For Android: ensure `google-services.json` is placed in `android/app/`.
- [ ] For iOS: ensure `GoogleService-Info.plist` is added to the Xcode project (not just copied to the folder).

### 2. Wire `?category=` when navigating to the booking flow
Currently `BookingFlowPage` accepts a `category` query param but no existing screen passes it. Update place / event detail pages:

- [ ] In `lib/features/places/presentation/pages/place_details_page.dart`, when the "Book Now" button is tapped, navigate with:
  ```dart
  context.push('/place/$placeId/book?category=${place.category}');
  ```
  (`place.category` should be the lowercase string that matches the enum: `padel`, `football`, `farm`, `restaurant`, `concert`, `gym` / `membership`)
- [ ] In `lib/features/events/presentation/pages/event_details_page.dart`, navigate with:
  ```dart
  context.push('/event/$eventId/book');
  ```
  (no category needed — the `eventId` parameter already routes to the Concert section)

### 3. Show place / event name in ticket detail
The `TicketDetailPage` currently shows the raw booking ID as the title because the name isn't in the `Booking` model.

- [ ] Option A — Add name to the Booking model: update `BookingRepository.bookingDetail(id)` to join the place/event name from the DB and include it in the returned row, then display `booking.placeName` in `TicketDetailPage`.
- [ ] Option B — Fetch separately: in `TicketDetailPage`, call `placeDetailsProvider(booking.placeId)` (if `placeId` is available) and display the resolved name.
- [ ] Remove the `// TODO: replace with BilingualLabel once place/event name is fetched` comment in `ticket_detail_page.dart:144` once this is done.

### 4. Apply the Supabase migration
- [ ] Run `supabase/migrations/20260427000011_add_fcm_token.sql` against your Supabase project (local and/or production) to create the `fcm_token` column on `profiles.app_users`.

### 5. (Optional) Bookings history route in the bottom nav
- [ ] The bookings history page (`/bookings`) is accessible via deep link / push but has no bottom-nav tab. Decide whether to add a "Tickets" tab to `NavShell` or keep it accessible only from the profile screen.

---

## Commit History (this feature)

```
83c3083  merge: bring in booking feature from worktree
629976c  feat(router): add booking route name constants
6e55bf3  feat(booking): add BilingualLabel, wire into widgets, RTL audit
8c9b258  feat(notifications): implement FCM token capture and push notification handler
e5f5f87  feat(booking): add Concert section with interactive seat map
1dfab27  feat(booking): add Membership section
134481a  feat(booking): add Restaurant section
8fba28d  feat(booking): add Farm section
e350134  feat(booking): BookingFlowPage scaffold + Padel section
4a8de70  feat(booking): add booking routes to router
8eb87b1  feat(bookings_history): read-only history page, ticket detail, QR
2a5f063  fix(booking): schema-qualify RPCs, remove redundant list casts
736dae5  feat(booking): add BookingRepository with Supabase/RPC bindings
b596415  fix(booking): safe num casts, false defaults, drop dead @JsonValue
d473cdc  feat(booking): add domain models
49957a2  feat(booking): setup env, fcm_token migration, add qr_flutter
```
