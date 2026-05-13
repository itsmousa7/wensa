# Bookings History Tab Bar Redesign

**Date:** 2026-05-12  
**File:** `lib/features/bookings_history/presentation/pages/bookings_history_page.dart`

## Goal

Redesign the horizontal category filter bar in `BookingsHistoryPage` to use user-facing semantic category names (matching actual Supabase booking categories) and a modern, polished bold-underline indicator style consistent with the app's Material 3 design language.

## Tab Labels

| Index | New Label | Old Label | BookingCategory filter |
|-------|-----------|-----------|------------------------|
| 0 | All | All | none |
| 1 | Sports | Hourly | `BookingCategory.hourly` |
| 2 | Farm | Shift | `BookingCategory.shift` |
| 3 | Concert | Venue / Seat | `BookingCategory.venueSeat` |
| 4 | Restaurant | Reservation | `BookingCategory.reservation` |
| 5 | Memberships | Memberships | memberships list |

## TabBar Visual Properties

- **indicator:** `UnderlineTabIndicator` with `borderSide: BorderSide(width: 3, color: cs.primary)` and `borderRadius: BorderRadius.circular(3)` — thick, rounded-end underline
- **indicatorSize:** `TabBarIndicatorSize.label` — indicator clips to label text width only
- **labelColor:** `cs.primary` (app teal)
- **unselectedLabelColor:** `cs.onSurface.withValues(alpha: 0.40)`
- **labelStyle:** `bodyMedium` + `FontWeight.w700` + `letterSpacing: 0.1`
- **unselectedLabelStyle:** `bodyMedium` + `FontWeight.w500` + `letterSpacing: 0.1`
- **dividerColor:** `Colors.transparent` (removes default bottom border)
- **labelPadding:** `EdgeInsets.symmetric(horizontal: 14)`
- **tabAlignment:** `TabAlignment.start`
- **isScrollable:** `true`

## Constraints

- `TabController` length stays 6 — no structural change to `TabBarView` children
- No new files — change is entirely within `bookings_history_page.dart`
- Both light and dark themes are handled via `cs.primary` and `cs.onSurface` (theme-adaptive)
