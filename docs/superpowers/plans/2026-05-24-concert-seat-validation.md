# Concert Seat Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two buyer-side validation rules to the concert booking flow — max 4 tickets per booking, and no orphan free seats — with red pulsing seat highlighting and a bottom-anchored error banner.

**Architecture:** Pure-Dart orphan detector + Riverpod notifier change for the cap + new JS bridge channel (`wensaSetWarningSeats`) for the red highlight. Viewer source (React/Vite, lives in the admin dashboard sibling project) is extended with a `warning` state per seat and rebuilt; its single-file HTML output is auto-copied into `wensa/assets/viewer/index.html`.

**Tech Stack:** Flutter 3.x, Dart, Riverpod (Notifier API, code-gen `.g.dart`), `webview_flutter`, freezed for models, `flutter_test` for unit tests; admin dashboard viewer is React 19 + TypeScript + Vite with `vite-plugin-singlefile`.

**Spec:** `docs/superpowers/specs/2026-05-24-concert-seat-validation-design.md`

---

## File Structure

**New (Flutter):**
- `lib/features/booking/domain/seat_validation.dart` — pure `findOrphanSeats` function.
- `test/features/booking/domain/seat_validation_test.dart` — unit tests.

**Modified (Flutter):**
- `lib/features/booking/presentation/widgets/seat_map_web_view.dart` — add `setWarningSeats`.
- `lib/features/booking/presentation/sections/concert_section.dart` — toggleSeat returns `bool`, max-4 toast, orphan banner, push warnings to viewer, GA cap.

**Modified (admin dashboard sibling project):**
- `wansa-admin-dashboard/src/viewer/Viewer.tsx` — `warningSeatIds` state, `wensaSetWarningSeats` bridge, `warning` prop on `SeatDot`.

**Regenerated:**
- `wensa/assets/viewer/index.html` — output of `npm run build:viewer` in the admin dashboard.

---

## Task 1: Orphan detector — pure function with TDD

**Files:**
- Create: `lib/features/booking/domain/seat_validation.dart`
- Test:   `test/features/booking/domain/seat_validation_test.dart`

- [ ] **Step 1: Write the failing test file**

Create `test/features/booking/domain/seat_validation_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';
import 'package:future_riverpod/features/booking/domain/seat_validation.dart';

Seat _seat({
  required String id,
  required String row,
  required String seat,
  String section = 'sec-1',
  SeatStatus status = SeatStatus.free,
}) =>
    Seat(seatId: id, sectionId: section, row: row, seat: seat, status: status);

void main() {
  group('findOrphanSeats', () {
    test('empty selection produces no orphans', () {
      final seats = [
        _seat(id: '1', row: 'A', seat: '1'),
        _seat(id: '2', row: 'A', seat: '2'),
        _seat(id: '3', row: 'A', seat: '3'),
      ];
      expect(findOrphanSeats(seats: seats, selectedSeatIds: {}), isEmpty);
    });

    test('selection sandwiching a free seat creates one orphan', () {
      // Row A: seats 1, 2, 3. User selects 1 and 3. Seat 2 is orphaned.
      final seats = [
        _seat(id: '1', row: 'A', seat: '1'),
        _seat(id: '2', row: 'A', seat: '2'),
        _seat(id: '3', row: 'A', seat: '3'),
      ];
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'1', '3'});
      expect(orphans.map((s) => s.seatId).toList(), ['2']);
    });

    test('selection adjacent to row edge with one free seat orphans it', () {
      // Row A: seats 1, 2. User selects 2. Seat 1 is at row edge with selection
      // on its right, so both sides are blockers (edge + selection).
      final seats = [
        _seat(id: '1', row: 'A', seat: '1'),
        _seat(id: '2', row: 'A', seat: '2'),
      ];
      final orphans = findOrphanSeats(seats: seats, selectedSeatIds: {'2'});
      expect(orphans.map((s) => s.seatId).toList(), ['1']);
    });

    test('pre-existing orphan (booked sandwich) is not reported', () {
      // Row A: seats 1 (taken), 2 (free), 3 (taken). User selects an unrelated
      // seat in row B. Seat 2 is orphan by pre-existing booking, but the
      // selection did not cause it — so it is NOT reported.
      final seats = [
        _seat(id: '1', row: 'A', seat: '1', status: SeatStatus.taken),
        _seat(id: '2', row: 'A', seat: '2'),
        _seat(id: '3', row: 'A', seat: '3', status: SeatStatus.taken),
        _seat(id: '10', row: 'B', seat: '1'),
        _seat(id: '11', row: 'B', seat: '2'),
        _seat(id: '12', row: 'B', seat: '3'),
      ];
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'10'});
      expect(orphans, isEmpty);
    });

    test('held seats count as blockers like taken seats', () {
      // Row A: 1 (held), 2 (free), 3 (selected). The held seat + the selection
      // sandwich seat 2 — at least one blocker is from selection, so seat 2
      // IS an orphan.
      final seats = [
        _seat(id: '1', row: 'A', seat: '1', status: SeatStatus.held),
        _seat(id: '2', row: 'A', seat: '2'),
        _seat(id: '3', row: 'A', seat: '3'),
      ];
      final orphans = findOrphanSeats(seats: seats, selectedSeatIds: {'3'});
      expect(orphans.map((s) => s.seatId).toList(), ['2']);
    });

    test('seats sort numerically not lexicographically', () {
      // Row A seat labels: '1', '2', '10'. Lexicographic would order
      // '1','10','2' and miss that 2 is the last seat. Numeric sort puts them
      // in order 1, 2, 10. User selects 1 and 10 — seat 2 is in the middle
      // sorted-wise but adjacent to selected seat 1 only; its right neighbor
      // is seat 10 which IS selected. So seat 2 is an orphan.
      final seats = [
        _seat(id: 'a', row: 'A', seat: '1'),
        _seat(id: 'b', row: 'A', seat: '2'),
        _seat(id: 'c', row: 'A', seat: '10'),
      ];
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'a', 'c'});
      expect(orphans.map((s) => s.seatId).toList(), ['b']);
    });

    test('rows are independent — selecting in one row does not affect another',
        () {
      final seats = [
        _seat(id: 'a1', row: 'A', seat: '1'),
        _seat(id: 'a2', row: 'A', seat: '2'),
        _seat(id: 'a3', row: 'A', seat: '3'),
        _seat(id: 'b1', row: 'B', seat: '1'),
        _seat(id: 'b2', row: 'B', seat: '2'),
        _seat(id: 'b3', row: 'B', seat: '3'),
      ];
      // Select row A seats 1 and 3 (orphans seat A-2). Row B untouched.
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'a1', 'a3'});
      expect(orphans.map((s) => s.seatId).toList(), ['a2']);
    });

    test('sections are independent', () {
      // Same row label "A" in two sections — must not merge.
      final seats = [
        _seat(id: 'sx1', section: 'sec-X', row: 'A', seat: '1'),
        _seat(id: 'sx2', section: 'sec-X', row: 'A', seat: '2'),
        _seat(id: 'sy1', section: 'sec-Y', row: 'A', seat: '1'),
        _seat(id: 'sy2', section: 'sec-Y', row: 'A', seat: '2'),
      ];
      // Select sx2. In sec-X row A, seat 1 has edge-left and selection-right
      // → orphan. Sec-Y is untouched.
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'sx2'});
      expect(orphans.map((s) => s.seatId).toList(), ['sx1']);
    });

    test('selected seats themselves are never orphans', () {
      final seats = [
        _seat(id: '1', row: 'A', seat: '1'),
        _seat(id: '2', row: 'A', seat: '2'),
      ];
      // Both selected: nothing free to be orphan.
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'1', '2'});
      expect(orphans, isEmpty);
    });

    test('non-numeric seat labels fall back to lexicographic sort', () {
      // Row A: A1, A2, A3 (alphanumeric labels). int.tryParse fails, falls
      // back to compareTo. User selects A1 and A3 → A2 orphan.
      final seats = [
        _seat(id: 'x', row: 'A', seat: 'A1'),
        _seat(id: 'y', row: 'A', seat: 'A2'),
        _seat(id: 'z', row: 'A', seat: 'A3'),
      ];
      final orphans =
          findOrphanSeats(seats: seats, selectedSeatIds: {'x', 'z'});
      expect(orphans.map((s) => s.seatId).toList(), ['y']);
    });
  });
}
```

- [ ] **Step 2: Run the test, confirm it fails**

Run: `flutter test test/features/booking/domain/seat_validation_test.dart`

Expected: failure — `seat_validation.dart` does not exist, import resolution fails.

- [ ] **Step 3: Implement the detector**

Create `lib/features/booking/domain/seat_validation.dart`:

```dart
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';

/// Returns the seats that the current selection would leave orphaned.
///
/// A seat is orphan iff it is free, not selected, and both its immediate
/// row-neighbors are blockers (booked / held / selected / off the row edge),
/// AND at least one of those blockers is in `selectedSeatIds`. The selection
/// must be a cause — pre-existing orphans from prior bookings are never
/// reported because the buyer cannot fix them.
///
/// `seats` should be the full set of seats for the event (every section,
/// every status). The cost is O(n log n) per (section, row) for the sort.
List<Seat> findOrphanSeats({
  required List<Seat> seats,
  required Set<String> selectedSeatIds,
}) {
  // Group by (sectionId, row).
  final byRow = <String, List<Seat>>{};
  for (final s in seats) {
    final key = '${s.sectionId}::${s.row}';
    (byRow[key] ??= <Seat>[]).add(s);
  }

  final orphans = <Seat>[];

  for (final row in byRow.values) {
    row.sort(_compareSeats);

    for (var i = 0; i < row.length; i++) {
      final seat = row[i];
      if (seat.status != SeatStatus.free) continue;
      if (selectedSeatIds.contains(seat.seatId)) continue;

      final left = i > 0 ? row[i - 1] : null;
      final right = i < row.length - 1 ? row[i + 1] : null;

      final leftBlocker = _isBlocker(left, selectedSeatIds);
      final rightBlocker = _isBlocker(right, selectedSeatIds);
      if (!leftBlocker || !rightBlocker) continue;

      final leftFromSelection =
          left != null && selectedSeatIds.contains(left.seatId);
      final rightFromSelection =
          right != null && selectedSeatIds.contains(right.seatId);
      if (!leftFromSelection && !rightFromSelection) continue;

      orphans.add(seat);
    }
  }

  return orphans;
}

bool _isBlocker(Seat? neighbor, Set<String> selectedSeatIds) {
  if (neighbor == null) return true; // row edge
  if (neighbor.status != SeatStatus.free) return true;
  if (selectedSeatIds.contains(neighbor.seatId)) return true;
  return false;
}

int _compareSeats(Seat a, Seat b) {
  final ai = int.tryParse(a.seat);
  final bi = int.tryParse(b.seat);
  if (ai != null && bi != null) return ai.compareTo(bi);
  return a.seat.compareTo(b.seat);
}
```

- [ ] **Step 4: Run the test, confirm it passes**

Run: `flutter test test/features/booking/domain/seat_validation_test.dart`

Expected: all 10 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/domain/seat_validation.dart \
        test/features/booking/domain/seat_validation_test.dart
git commit -m "feat(booking): add findOrphanSeats validator for seat selection"
```

---

## Task 2: WebView bridge — `setWarningSeats`

**Files:**
- Modify: `lib/features/booking/presentation/widgets/seat_map_web_view.dart:133-139`

- [ ] **Step 1: Add the method**

After the existing `setSelectedSeats` method (ends at line 139), add:

```dart
  /// Push the seats that should render with the red "orphan / warning"
  /// highlight (pulsing ring). Called after every change to either the
  /// selection or the available seats list.
  Future<void> setWarningSeats(List<String> seatIds) async {
    final c = _controller;
    if (c == null || !_ready) return;
    final payload = jsonEncode(seatIds);
    await c.runJavaScript(
        'window.wensaSetWarningSeats && window.wensaSetWarningSeats($payload);');
  }
```

- [ ] **Step 2: Verify Flutter compiles**

Run: `flutter analyze lib/features/booking/presentation/widgets/seat_map_web_view.dart`

Expected: no errors, no new warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/features/booking/presentation/widgets/seat_map_web_view.dart
git commit -m "feat(booking): add setWarningSeats bridge to seat map web view"
```

---

## Task 3: Viewer source — warning seat rendering (admin dashboard)

**Files:**
- Modify: `../wansa-admin-dashboard/src/viewer/Viewer.tsx`

Working directory for this task: `/Users/mousaalhamad/Desktop/wensa_app/wansa-admin-dashboard`.

- [ ] **Step 1: Add `warningSeatIds` state and bridge binding**

In `Viewer.tsx`, find the `selectedSeatIds` state declaration (around line 36):

```tsx
const [selectedSeatIds, setSelectedSeatIds] = useState<Set<string>>(new Set());
```

Add immediately after:

```tsx
const [warningSeatIds, setWarningSeatIds] = useState<Set<string>>(new Set());
```

Find the effect that registers window bridges (around line 99-109):

```tsx
useEffect(() => {
    const w = window as unknown as {
        wensaReload?: () => void;
        wensaOpenSection?: (id: string | null) => void;
        wensaSetSelectedSeats?: (ids: string[]) => void;
    };
    w.wensaReload = () => { void reload(); };
    w.wensaOpenSection = (id) => setActiveSectionId(id);
    w.wensaSetSelectedSeats = (ids) => setSelectedSeatIds(new Set(ids ?? []));
    sendToFlutter({ type: "ready" });
}, [reload]);
```

Extend the type and add the new binding:

```tsx
useEffect(() => {
    const w = window as unknown as {
        wensaReload?: () => void;
        wensaOpenSection?: (id: string | null) => void;
        wensaSetSelectedSeats?: (ids: string[]) => void;
        wensaSetWarningSeats?: (ids: string[]) => void;
    };
    w.wensaReload = () => { void reload(); };
    w.wensaOpenSection = (id) => setActiveSectionId(id);
    w.wensaSetSelectedSeats = (ids) => setSelectedSeatIds(new Set(ids ?? []));
    w.wensaSetWarningSeats = (ids) => setWarningSeatIds(new Set(ids ?? []));
    sendToFlutter({ type: "ready" });
}, [reload]);
```

- [ ] **Step 2: Pass `warning` into `SeatDot`**

Find the seats render block (around line 531-547):

```tsx
{seats.map(seat => {
    const section = layout.sections.find(s => s.id === seat.section_id);
    if (!section) return null;
    const isInActive = activeSection?.id === seat.section_id;
    const isDimmed = activeSection !== null && !isInActive;
    return (
        <SeatDot
            key={seat.seat_id}
            seat={seat}
            sectionColor={section.fill_color}
            selected={selectedSeatIds.has(seat.seat_id)}
            interactive={isInActive}
            dimmed={isDimmed}
            overview={activeSection === null}
        />
    );
})}
```

Replace with:

```tsx
{seats.map(seat => {
    const section = layout.sections.find(s => s.id === seat.section_id);
    if (!section) return null;
    const isInActive = activeSection?.id === seat.section_id;
    const isDimmed = activeSection !== null && !isInActive;
    return (
        <SeatDot
            key={seat.seat_id}
            seat={seat}
            sectionColor={section.fill_color}
            selected={selectedSeatIds.has(seat.seat_id)}
            warning={warningSeatIds.has(seat.seat_id)}
            interactive={isInActive}
            dimmed={isDimmed}
            overview={activeSection === null}
        />
    );
})}
```

- [ ] **Step 3: Update `SeatDot` to handle the `warning` prop**

Find `SeatDot` (around line 597-651). Replace the entire component with:

```tsx
function SeatDot({ seat, sectionColor, selected, warning, interactive, dimmed, overview }: {
    seat: AvailableSeat;
    sectionColor: string;
    selected: boolean;
    warning: boolean;
    interactive: boolean;
    dimmed: boolean;
    overview: boolean;
}): JSX.Element {
    const isFree = seat.status === "free";
    const isHeld = seat.status === "held";
    const isTappable = isFree || selected;
    // warning takes precedence over selected: an orphan is by definition a
    // free, NON-selected seat, so they shouldn't overlap — but render
    // defensively in case the Flutter side ever pushes overlapping ids.
    const fill = warning
        ? "#ef4444"
        : selected ? "#0ea5e9"
            : isFree ? sectionColor
                : isHeld ? "#fbbf24" : "#cbd5e1";
    const stroke = warning
        ? "#fff"
        : selected ? "#fff"
            : isFree ? "#fff"
                : isHeld ? "#fff" : "#94a3b8";

    const inActiveSection = interactive || selected || warning;
    const radius = inActiveSection
        ? (selected || warning ? SEAT_RADIUS + 3 : isTappable ? SEAT_RADIUS : SEAT_RADIUS - 4)
        : SEAT_RADIUS_OVERVIEW;
    const strokeWidth = inActiveSection
        ? (selected || warning ? 3 : isTappable ? 2 : 0)
        : 1;
    const opacity = dimmed
        ? 0.25
        : overview
            ? 0.9
            : isTappable || warning
                ? 1
                : 0.35;

    return (
        <g opacity={opacity}>
            <circle
                cx={seat.x} cy={seat.y}
                r={radius}
                fill={fill}
                stroke={stroke}
                strokeWidth={strokeWidth}
            />
            {selected && !warning && (
                <circle
                    cx={seat.x} cy={seat.y}
                    r={SEAT_RADIUS + 7}
                    fill="none"
                    stroke="#0ea5e9"
                    strokeWidth={1.5}
                    opacity={0.5}
                />
            )}
            {warning && (
                <circle
                    cx={seat.x} cy={seat.y}
                    r={SEAT_RADIUS + 7}
                    fill="none"
                    stroke="#ef4444"
                    strokeWidth={2}
                    opacity={0.6}
                >
                    <animate
                        attributeName="r"
                        values={`${SEAT_RADIUS + 5};${SEAT_RADIUS + 12};${SEAT_RADIUS + 5}`}
                        dur="1.2s"
                        repeatCount="indefinite"
                    />
                    <animate
                        attributeName="opacity"
                        values="0.8;0.1;0.8"
                        dur="1.2s"
                        repeatCount="indefinite"
                    />
                </circle>
            )}
        </g>
    );
}
```

- [ ] **Step 4: TypeScript check**

Run from `wansa-admin-dashboard/`:
```bash
npx tsc -b
```

Expected: no type errors.

- [ ] **Step 5: Build the viewer and copy to Flutter assets**

Run from `wansa-admin-dashboard/`:
```bash
npm run build:viewer
```

Expected: vite reports the single-file bundle written, then `copy-viewer-to-flutter.mjs` reports the destination path inside the wensa Flutter project.

- [ ] **Step 6: Verify the bundle was copied**

Run from `wensa/`:
```bash
git status assets/viewer/index.html
```

Expected: file is modified (the new bundle is in place).

- [ ] **Step 7: Commit (one commit spanning both repos)**

In the admin dashboard:
```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wansa-admin-dashboard
git add src/viewer/Viewer.tsx
git commit -m "feat(viewer): render warning (orphan) seats with red pulse"
```

In the Flutter project:
```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
git add assets/viewer/index.html
git commit -m "chore(viewer): rebuild bundle with warning seat rendering"
```

---

## Task 4: Notifier — return bool from `toggleSeat` for max-4 cap

**Files:**
- Modify: `lib/features/booking/presentation/sections/concert_section.dart:83-103`

- [ ] **Step 1: Change `toggleSeat` to return `bool` and enforce cap**

Replace the existing `toggleSeat` method (lines 83-103) with:

```dart
  /// Returns `true` if the seat was added or removed, `false` if the tap was
  /// rejected (currently: tried to add a 5th seat when already at the 4-seat
  /// cap). Callers can use the return value to surface a snackbar.
  bool toggleSeat(Seat seat) {
    final selected = Set<String>.from(state.selectedSeatIds);
    String? focused = state.focusedSeatId;
    if (selected.contains(seat.seatId)) {
      selected.remove(seat.seatId);
      if (focused == seat.seatId) focused = selected.isEmpty ? null : selected.last;
    } else {
      if (selected.length >= 4) return false;
      selected.add(seat.seatId);
      focused = seat.seatId;
    }
    state = (
      selectedSeatIds: selected,
      activeSectionId: state.activeSectionId,
      focusedSeatId: focused,
      holdUntil: selected.isEmpty
          ? null
          : DateTime.now()
              .add(const Duration(seconds: 60))
              .toIso8601String(),
    );
    return true;
  }
```

- [ ] **Step 2: Update caller in `_ConcertBookingView.onSeatTap`**

Find the `onSeatTap` block (around line 324-334):

```dart
onSeatTap: (event) {
  final seat = seats
      .where((s) => s.seatId == event.seatId)
      .firstOrNull;
  if (seat == null) return;
  if (seat.status != SeatStatus.free) return;
  ref
      .read(_concertSelectionProvider.notifier)
      .toggleSeat(seat);
  _pushSelectionToViewer();
},
```

Replace with:

```dart
onSeatTap: (event) {
  final seat = seats
      .where((s) => s.seatId == event.seatId)
      .firstOrNull;
  if (seat == null) return;
  if (seat.status != SeatStatus.free) return;
  final added = ref
      .read(_concertSelectionProvider.notifier)
      .toggleSeat(seat);
  if (!added) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'يمكنك اختيار ٤ مقاعد كحد أقصى لكل حجز.'
              : 'You can select up to 4 seats per booking.',
        ),
      ),
    );
    return;
  }
  _pushSelectionToViewer();
},
```

- [ ] **Step 3: Verify Flutter still compiles**

Run: `flutter analyze lib/features/booking/presentation/sections/concert_section.dart`

Expected: no errors. (`toggleSeat`'s return value newly being used in one caller is fine; no other call sites exist — confirm with `grep -rn "toggleSeat" lib/`.)

- [ ] **Step 4: Commit**

```bash
git add lib/features/booking/presentation/sections/concert_section.dart
git commit -m "feat(booking): cap concert seat selection at 4 seats per booking"
```

---

## Task 5: Push warning seats to viewer + orphan banner

**Files:**
- Modify: `lib/features/booking/presentation/sections/concert_section.dart`

- [ ] **Step 1: Add `findOrphanSeats` import**

In `concert_section.dart`'s imports block (top of file, after the existing booking imports), add:

```dart
import 'package:future_riverpod/features/booking/domain/seat_validation.dart';
```

- [ ] **Step 2: Add the warning-push helper**

After the existing `_pushSelectionToViewer()` method (around line 230-233):

```dart
void _pushSelectionToViewer() {
  final ids = ref.read(_concertSelectionProvider).selectedSeatIds.toList();
  _viewerKey.currentState?.setSelectedSeats(ids);
}
```

Add immediately after it:

```dart
void _pushWarningSeatsToViewer(List<String> ids) {
  _viewerKey.currentState?.setWarningSeats(ids);
}
```

- [ ] **Step 3: Add `_orphanErrorVisible` field to the State class**

The banner is shown ONLY after the user taps Review with orphans present.
The pulse highlight is always-on while orphans exist (visual feedback during
selection), but the bottom banner is a discrete user-triggered surface.

In `_ConcertBookingViewState` (currently has only `_viewerKey`), add a field:

```dart
class _ConcertBookingViewState extends ConsumerState<_ConcertBookingView> {
  final GlobalKey<SeatMapWebViewState> _viewerKey =
      GlobalKey<SeatMapWebViewState>();
  bool _orphanErrorVisible = false;
```

- [ ] **Step 4: Compute orphans in `build`, push pulse to viewer, hide banner when clean**

Find the section of `_ConcertBookingViewState.build` where `selectedSeats` is computed (around line 266-269):

```dart
final selectedSeats = seats
    .where((s) => selection.selectedSeatIds.contains(s.seatId))
    .toList();
```

Add right after it:

```dart
final orphanSeats = findOrphanSeats(
  seats: seats,
  selectedSeatIds: selection.selectedSeatIds,
);
final orphanIds = orphanSeats.map((s) => s.seatId).toList();
// Auto-hide the banner once orphans are resolved so the next Review tap
// starts from a clean slate.
if (orphanSeats.isEmpty && _orphanErrorVisible) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) setState(() => _orphanErrorVisible = false);
  });
}
// Push pulse highlights to the viewer on every rebuild. The bridge is a
// no-op until the page has finished loading, so it's safe to call eagerly.
// Posted in a post-frame callback to avoid running JS during build.
WidgetsBinding.instance.addPostFrameCallback((_) {
  _pushWarningSeatsToViewer(orphanIds);
});
```

- [ ] **Step 5: Add the banner widget and stack it above the selection bar**

Find the `Stack` children block (around line 289-367). Locate this section:

```dart
// Selection summary + Review CTA (bottom)
if (selectedSeats.isNotEmpty)
  Positioned(
    left: 0, right: 0, bottom: 0,
    child: _SelectionBar(
      selectedSeats: selectedSeats,
      tierByKey: tierByKey,
      onReview: () => _showReviewSheet(
        context,
        ref,
        selectedSeats: selectedSeats,
        tierByKey: tierByKey,
      ),
      onClear: () {
        ref.read(_concertSelectionProvider.notifier).reset();
        _pushSelectionToViewer();
      },
    ),
  ),
```

Replace with:

```dart
// Orphan-seat error banner — only shown after the user pressed Review
// while orphans exist. The pulse on the orphan seats themselves is
// always on (driven by `orphanIds`) so users get live feedback even
// before they hit Review.
if (_orphanErrorVisible && orphanSeats.isNotEmpty)
  Positioned(
    left: 0, right: 0,
    bottom: selectedSeats.isNotEmpty ? 88 : 0,
    child: _OrphanErrorBanner(
      onDismiss: () => setState(() => _orphanErrorVisible = false),
    ),
  ),

// Selection summary + Review CTA (bottom)
if (selectedSeats.isNotEmpty)
  Positioned(
    left: 0, right: 0, bottom: 0,
    child: _SelectionBar(
      selectedSeats: selectedSeats,
      tierByKey: tierByKey,
      onReview: () {
        if (orphanSeats.isNotEmpty) {
          // Surface the banner and keep the review sheet closed until
          // the user resolves the orphan situation.
          setState(() => _orphanErrorVisible = true);
          return;
        }
        _showReviewSheet(
          context,
          ref,
          selectedSeats: selectedSeats,
          tierByKey: tierByKey,
        );
      },
      onClear: () {
        ref.read(_concertSelectionProvider.notifier).reset();
        _pushSelectionToViewer();
      },
    ),
  ),
```

- [ ] **Step 6: Implement the `_OrphanErrorBanner` widget**

At the bottom of `concert_section.dart` (after the closing `}` of `_GASheetState`), add:

```dart
// ---------------------------------------------------------------------------
// Orphan-seat error banner
// ---------------------------------------------------------------------------

class _OrphanErrorBanner extends StatelessWidget {
  const _OrphanErrorBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFB91C1C),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAr
                          ? 'اختيار المقاعد غير صالح. يرجى المحاولة مرة أخرى'
                          : 'Invalid seat selection. Please try again.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'لا يمكنك ترك مقعد منفرد بين المقاعد المحددة، يرجى اختيار المقاعد بحيث لا يبقى مقعد منفرد'
                          : 'Your selection leaves an isolated seat with no free neighbor in its row. Please adjust so no seat is left orphaned.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                tooltip: isAr ? 'إغلاق' : 'Dismiss',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Verify analyze passes**

Run: `flutter analyze lib/features/booking/presentation/sections/concert_section.dart`

Expected: no errors. (If `withValues` is unavailable in your Flutter version, fall back to `withOpacity` — they're functionally equivalent for this banner.)

- [ ] **Step 8: Commit**

```bash
git add lib/features/booking/presentation/sections/concert_section.dart
git commit -m "feat(booking): block review on orphan seats + show error banner"
```

---

## Task 6: GA quantity cap — drop from 10 to 4

**Files:**
- Modify: `lib/features/booking/presentation/sections/concert_section.dart:684`

- [ ] **Step 1: Change the cap expression**

Find this line in `_GASheetState.build` (around line 684):

```dart
final maxQty = remaining > 10 ? 10 : remaining;
```

Replace with:

```dart
final maxQty = remaining > 4 ? 4 : remaining;
```

- [ ] **Step 2: Verify analyze passes**

Run: `flutter analyze lib/features/booking/presentation/sections/concert_section.dart`

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/booking/presentation/sections/concert_section.dart
git commit -m "feat(booking): cap General Admission quantity picker at 4"
```

---

## Task 7: Manual QA on device

This task is purely verification — no code changes. Document any deviations and fix before declaring complete.

- [ ] **Step 1: Boot the app on a real concert event with mixed booked + free seats**

Pick an event that has at least one section with seats and at least one held/taken seat so orphan cases are reachable.

- [ ] **Step 2: Verify cap fires on 5th tap**

- Select 4 seats. Confirm `_SelectionBar` shows "4 seats selected".
- Tap a 5th free seat. Expected: nothing added to selection; snackbar shows the AR/EN cap message; seat does not turn blue in the viewer.

- [ ] **Step 3: Verify orphan pulse + banner on Review**

- Pick a row of at least 3 free seats. Select the leftmost and rightmost (leaving exactly one free seat between them).
- Confirm the middle seat pulses red in the viewer immediately (pulse is live, no Review tap needed).
- Confirm the banner is NOT yet visible.
- Tap "Review". Expected: review sheet does NOT open; the red banner now appears above the selection bar with title + body text + X button.

- [ ] **Step 4: Verify banner dismiss**

- With the banner visible, tap the X. Banner disappears. The pulse continues (orphan still exists). Tapping Review again should re-show the banner.

- [ ] **Step 5: Verify resolution path A — tap the orphan**

- With banner visible (or dismissed), tap the pulsing orphan seat. It joins the selection (assuming total stays ≤ 4). Banner clears, orphan stops pulsing. Tap "Review" — sheet opens.

- [ ] **Step 6: Verify resolution path B — deselect an adjacent seat**

- Re-create the orphan situation. Instead of selecting the orphan, deselect one of the surrounding selected seats. Confirm pulse clears, banner auto-hides if it was up, "Review" works.

- [ ] **Step 7: Verify pre-existing orphan does NOT block**

- Find a row where the layout already has booked seats sandwiching one free seat (without any user selection). Select an unrelated seat. Tap "Review". Expected: sheet opens normally; the pre-existing orphan does not pulse and does not block.

- [ ] **Step 8: Verify GA cap**

- Open a General Admission section sheet. Tap "+" repeatedly. Quantity should top out at 4 (or `remaining` if remaining < 4), `+` button greys out.

- [ ] **Step 9: Verify language switch**

- Repeat the cap-toast and banner-trigger steps with both AR and EN locales. Confirm copy renders right-to-left correctly in AR and the icon/title/body order looks correct.

- [ ] **Step 10: If anything fails, file fix as a sub-task and resolve before declaring done**

---

## Final Checklist

- [ ] All unit tests pass: `flutter test test/features/booking/domain/seat_validation_test.dart`
- [ ] `flutter analyze` clean for both touched files
- [ ] Manual QA scenarios in Task 7 all pass
- [ ] Two repos committed: `wensa` (Flutter changes + new bundle) and `wansa-admin-dashboard` (viewer source)
- [ ] PR description mentions the viewer rebuild requirement for future maintainers

---

## Notes for Future Maintainers

- The viewer is a compiled single-file React bundle. Source lives in
  `wansa-admin-dashboard/src/viewer/`. Any rendering change requires
  `npm run build:viewer` in that repo, which auto-copies the new
  `index.html` to `wensa/assets/viewer/`. Commit both repos together.
- Aisle awareness is intentionally not handled: a row with seats 1,2,3,7,8,9
  treats seat 3 and seat 7 as adjacent. If the venue data ever grows aisle
  metadata (`aisle_after_seat`), update `_compareSeats` and the blocker
  logic in `seat_validation.dart` to treat aisles as row edges.
- The 4-seat cap is duplicated in two places: the notifier's `toggleSeat`
  (seated selection) and `_GASheetState.maxQty` (GA). If the cap ever
  needs to change, update both.
