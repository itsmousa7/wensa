# Concert seat-selection validation rules

Date: 2026-05-24
Scope: Concert booking flow (`ConcertSection`) + General Admission quantity picker
       + bundled seat-map viewer (`assets/viewer/index.html`).

## Goal

Two buyer-side rules to prevent low-quality selections that hurt resale of
adjacent inventory and to enforce a per-booking ticket cap:

1. **Max 4 tickets per booking** — applies to both seated selection (concert
   sections with assigned seats) and General Admission quantity pickers.
2. **No orphan free seats** — the user's selection must not leave a free seat
   in the same row with no free neighbor on either side. Enforced at "Review"
   tap; orphans are highlighted on the map and the user fixes them manually.

## Non-goals

- Padel / farm / membership / restaurant sections (no seat layout).
- Server-side enforcement. The seat-hold + create-booking layer is already
  authoritative for "is the seat still available"; these rules are pure
  buyer-side UX and do not change the contract with `bookingRepository`.
- Auto-fix behavior (tap-the-error-to-add-orphans). User chose manual fix.

## User experience

### Max-4 cap

- **Seated selection:** Tapping a 5th free seat is ignored. A snackbar
  appears: AR `يمكنك اختيار ٤ مقاعد كحد أقصى لكل حجز.` / EN
  `You can select up to 4 seats per booking.`
- **General Admission:** Quantity picker's max drops from 10 → `min(4,
  remaining)`. The `+` button disables at 4.

### Orphan-seat rule

- Free taps add/remove seats normally — no validation mid-selection.
- On Review tap, recompute orphans. If any exist:
  - Review sheet does **not** open.
  - The red error banner from the spec image appears at the bottom of the
    map (RTL + LTR variants below). The banner has an X dismiss button.
  - Orphan seats render with a red fill + pulsing outer ring (existing
    selected/free rendering for other seats is unchanged).
  - User resolves by tapping an orphan (adds it to selection, subject to
    the 4-cap) or deselecting an adjacent selected seat.
  - Once orphans clear, the banner disappears and the next Review tap
    opens the sheet normally.

#### Banner copy

- AR title: `اختيار المقاعد غير صالح. يرجى المحاولة مرة أخرى`
- AR body:  `لا يمكنك ترك مقعد منفرد بين المقاعد المحددة، يرجى اختيار المقاعد بحيث لا يبقى مقعد منفرد`
- EN title: `Invalid seat selection. Please try again.`
- EN body:  `Your selection leaves an isolated seat with no free neighbor in its row. Please adjust so no seat is left orphaned.`

## Orphan rule — precise definition

For a given **section + row**:

1. Gather all seats in that section with that `row` label.
2. Sort by `seat` label, parsed as integer where possible (`int.tryParse`),
   else lexicographically as a stable fallback.
3. For every seat S in the sorted row:
   - Skip S unless `S.status == free` AND `S.seatId ∉ selectedSeatIds`.
   - Look at S's left neighbor L and right neighbor R in the sorted row.
   - A neighbor is a **blocker** if:
     - it doesn't exist (S is at the row edge), OR
     - its `status != free` (held/sold/locked/etc.), OR
     - its `seatId ∈ selectedSeatIds`.
   - S is **orphan** iff both L and R are blockers **AND** at least one of
     L, R is a blocker because it's in `selectedSeatIds`.
4. Repeat for every (section, row) pair found in `seats`. The caller
   passes the full `availableSeatsProvider(eventId)` list, so every row
   in every section of the event is checked. This is cheap (O(n log n)
   for the sort, n = total seats) and avoids missing orphans in rows the
   user touched only indirectly.

The "at least one blocker must be from the selection" clause prevents
flagging orphans that already existed before the user did anything —
buyers cannot fix pre-existing orphans, so the UI should not block them.

### Edge cases

- **Row with one free seat total** (everything else booked): if user
  doesn't select it, no orphan (selection didn't cause it). If user
  selects it, no orphan (it's selected, not free).
- **Aisles modeled as gaps in seat numbering** (e.g., seats 1,2,3, 7,8,9):
  treated as adjacent in sort order. If seat 3 has selected on its left
  (seat 2) and seat 7 on its right (the next sorted neighbor), seat 3's
  right-neighbor-blocker is seat 7. This is intentionally lenient — we
  don't have aisle metadata in `Seat` today, and the dashboard does not
  emit gap markers. If aisle awareness becomes important later, we'll add
  an `aisle_after_seat` flag to `VenueSection` and revisit.
- **Non-numeric seat labels** (e.g., `A`, `B`): lexicographic sort is the
  fallback. Documented limitation; current venues use numeric labels.

## Architecture

### Layer 1 — pure validator (Flutter)

New file: `lib/features/booking/domain/seat_validation.dart`

```dart
/// Returns the seats that would be left orphaned by the current selection.
/// Orphans are free seats with no free neighbor in their row, where the
/// selection itself is responsible for at least one of the blocking sides.
///
/// `seats` must contain every seat in the affected section(s), not just
/// free ones — booked/held seats matter for the blocker check.
List<Seat> findOrphanSeats({
  required List<Seat> seats,
  required Set<String> selectedSeatIds,
});
```

Implementation is one function, pure, no Riverpod. Unit-testable in
isolation. No state, no side effects.

Test file: `test/booking/seat_validation_test.dart`. Coverage:

- Empty selection → empty result.
- Single-row, selection sandwiches a free seat → one orphan.
- Selection at row edge, last free seat adjacent → one orphan (row edge
  is a blocker, selection is the other blocker).
- Pre-existing orphan (booked seats sandwich a free seat, user picks an
  unrelated seat) → empty result. Crucial — see "at least one blocker
  from selection" rule.
- Multiple rows touched, mixed orphans → correct list.
- Gap-in-seat-numbering row (aisle case) → treated as adjacent (current
  documented behavior, not a "bug").
- Non-numeric `seat` labels → falls back to lexicographic ordering.

### Layer 2 — selection notifier (`concert_section.dart`)

`_ConcertState` already tracks `selectedSeatIds`, `activeSectionId`,
`focusedSeatId`, `holdUntil`. No new fields needed — orphans are derived
from `(seats, selectedSeatIds)`, computed in the view.

`_ConcertSelectionNotifier.toggleSeat(Seat)` changes:

- Existing remove-branch unchanged.
- Add-branch: if `selected.length >= 4` AND seat is not already selected,
  return early **without mutating state** and return `false`.
- Otherwise mutate state and return `true`.

Caller in `_ConcertBookingView.build`'s `onSeatTap`: if `toggleSeat`
returns `false`, fire the AR/EN snackbar described above.

(`toggleSeat`'s old return type was `void`; changing to `bool` is
internal — only one caller.)

### Layer 3 — viewer bridge (Flutter ↔ JS)

`SeatMapWebViewState` (Flutter side) gets a new method mirroring the
existing `setSelectedSeats`:

```dart
Future<void> setWarningSeats(List<String> seatIds) async {
  await _controller.runJavaScript(
    'window.wensaSetWarningSeats?.(${jsonEncode(seatIds)})',
  );
}
```

`_ConcertBookingView` recomputes orphans whenever `selection` or `seats`
changes, then pushes the warning set via a new sibling helper
`_pushWarningSeatsToViewer()` (kept separate from
`_pushSelectionToViewer()` because the two updates have different
triggers — selection updates on every tap, warnings update whenever the
derived orphan set changes).

### Layer 4 — viewer (admin dashboard, rebuild required)

`wansa-admin-dashboard/src/viewer/Viewer.tsx`:

- Add `warningSeatIds: Set<string>` state.
- Add `window.wensaSetWarningSeats = (ids) => setWarningSeatIds(new Set(ids ?? []))`
  alongside the existing `wensaSetSelectedSeats` registration.
- Pass `warning={warningSeatIds.has(seat.seat_id)}` into `SeatDot`.

`SeatDot` gets a `warning` prop. When `true`:

- Fill becomes `#ef4444` (red-500).
- Stroke becomes white, width 3.
- Outer pulse ring (`<animate>` element on `circle`'s `r` or `opacity`,
  ~1.2s duration, infinite) — matches the visual language of the
  existing "selected" outer ring.
- `warning` takes precedence over `selected` in rendering (an orphan
  cannot be a selected seat by definition, but we render defensively).

After editing, run `npm run build:viewer` from the admin dashboard;
`scripts/copy-viewer-to-flutter.mjs` writes the new bundle to
`wensa/assets/viewer/index.html`.

### Layer 5 — Review gate

`_SelectionBar.onReview` callback changes:

Currently calls `_showReviewSheet`. Wrap that:

```dart
final orphans = findOrphanSeats(
  seats: seats,
  selectedSeatIds: selection.selectedSeatIds,
);
if (orphans.isNotEmpty) {
  // Banner already visible via the orphan-watcher widget; just don't open the sheet.
  return;
}
_showReviewSheet(...);
```

Banner widget: new `_OrphanErrorBanner` in `concert_section.dart`,
bottom-anchored, shown whenever `orphans.isNotEmpty`. It coexists with
`_SelectionBar` — banner stacks above the selection bar. The X button
sets a transient "dismissed for this orphan set" flag so the banner can
hide without forcing the user to fix immediately, but it re-appears the
next time Review is tapped.

Implementation hint: a single `Selector`-style derivation in the build
method:

```dart
final orphanIds = useMemo(() => findOrphanSeats(...).map((s) => s.seatId).toSet());
```

(Flutter equivalent: cache in a local var per build, no hook needed —
the existing rebuild on selection/seats change is enough.)

### Layer 6 — General Admission cap

`_GASheetState`:

```dart
final maxQty = remaining > 4 ? 4 : remaining;
```

(Was `remaining > 10 ? 10 : remaining`.) No other changes.

## Files touched

**New:**
- `lib/features/booking/domain/seat_validation.dart`
- `test/booking/seat_validation_test.dart`

**Modified (Flutter):**
- `lib/features/booking/presentation/sections/concert_section.dart`
  (notifier toggle return + orphan banner + push warnings)
- `lib/features/booking/presentation/widgets/seat_map_web_view.dart`
  (new `setWarningSeats` method)

**Modified (admin dashboard):**
- `wansa-admin-dashboard/src/viewer/Viewer.tsx`
  (warning seat state + `wensaSetWarningSeats` bridge + `warning` prop on
  `SeatDot`)

**Regenerated:**
- `wensa/assets/viewer/index.html` (via `npm run build:viewer`)

## Build sequence

1. Implement & unit-test `seat_validation.dart`.
2. Modify viewer source (`Viewer.tsx`) for warning seat rendering.
3. Run `npm run build:viewer` in the admin dashboard; verify the new
   `index.html` lands in `wensa/assets/viewer/`.
4. Add `setWarningSeats` to `SeatMapWebView`.
5. Wire the orphan banner + max-4 toast into `ConcertSection`.
6. Apply the GA cap (`maxQty = min(4, remaining)`).
7. Manual QA on a concert event with mixed booked / free seats:
   - Cap fires at the 5th tap with toast.
   - Sandwich selection on Review → banner + red pulse + sheet blocked.
   - Resolve by tapping orphan → banner clears, Review opens.
   - Resolve by deselecting adjacent → banner clears, Review opens.
   - Pre-existing orphan never triggers banner.
   - GA picker tops out at 4.

## Risks

- **Seat ordering relies on `int.tryParse(seat.seat)`.** If a venue uses
  alpha-numeric labels (`A12`, `B3`) the lexicographic fallback may
  reorder them surprisingly. We accept this — current venues are pure
  numeric. Documented limitation.
- **Aisle awareness is missing.** A row with a logical aisle between
  seats 3 and 7 will be treated as if 3 and 7 are adjacent. If
  operations report this as a real problem, add `aisle_after_seat` to
  `VenueSection` and update the validator. Out of scope for this spec.
- **Viewer rebuild required.** Anyone modifying these rules must
  remember to run `npm run build:viewer` in the admin dashboard. The
  `copy-viewer-to-flutter.mjs` script keeps the asset in sync, but
  developers working only in Flutter won't hit it unless they cross over.
  Mitigation: mention this in the PR description.
