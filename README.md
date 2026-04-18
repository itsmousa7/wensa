# Wensa

A Flutter app for discovering places and events, featuring a curated feed, favorites, search, and an in-feed ad system.

---

## Features

### Authentication
- Email/password sign-up and sign-in
- Google Sign-In
- Email verification (OTP)
- Forgot password & reset flow
- Change name and change password from profile

### Home Feed
- **Hot Events** — top events ranked by hotness score
- **Browse by Category** — filter the feed by category
- **Trending This Week** — mixed places + events sorted by hotness
- **Featured** — curated featured places and events
- **New Openings** — recently opened places
- **All Events** — paginated list of upcoming approved events
- **All Places** — full paginated places feed
- Pull-to-refresh across all sections
- Network error state with retry

### Promoted Banners
- **Top carousel** — auto-scrolling banner carousel with animated dots indicator (cycles every 4 seconds)
- **Inline ad slots** — up to 5 banners distributed between feed sections (after category bar, trending, featured, new openings, and all events)
- Smart distribution: 1 banner = appears once only, no duplication across the screen
- Banners link to a place or event detail page

### Place Details
- Full-screen image carousel
- Place info, location, and area
- Add/remove from favorites (double-tap)
- Fullscreen image viewer

### Event Details
- Event image carousel
- Event info section (date, city, status)
- Favorites support

### Favorites
- Saved places feed with pull-to-refresh
- Inline promoted banner
- Empty state with guidance

### Search
- Dedicated search page

### Profile
- Theme settings: Light, Dark, or System
- Change display name
- Change password
- Sign out (with confirmation dialog)

### Localization
- Full Arabic and English support
- RTL layout for Arabic
- Per-locale display names for places and events

### Theming
- Light mode
- Dark mode
- System (follows device setting)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter |
| State management | Riverpod (riverpod_annotation + code generation) |
| Backend | Supabase (auth + database) |
| Navigation | go_router |
| Data models | Freezed |
| Image loading | cached_network_image |
| Loading skeletons | skeletonizer |
| Animations | Flutter built-in (AnimatedContainer) |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # Theme, colors, typography, locale
│   ├── router/          # go_router config and guards
│   └── widgets/         # Shared widgets (error pages, etc.)
└── features/
    ├── auth/            # Sign in, sign up, OTP, password flows
    ├── bottom_bar/      # Bottom navigation shell
    ├── events/          # Event details page and providers
    ├── favorites/       # Favorites feed page
    ├── home/            # Home feed, models, repositories, providers
    ├── places/          # Place details page and providers
    ├── profile/         # Profile page, theme settings
    └── search/          # Search page
```

---

## Getting Started

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run code generation**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

> Requires a Supabase project with the `content` and `business` schemas configured.
