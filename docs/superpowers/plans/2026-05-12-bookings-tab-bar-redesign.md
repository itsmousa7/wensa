# Bookings Tab Bar Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic `TabBar` labels and default indicator in `BookingsHistoryPage` with semantic category names (Sports, Farm, Concert, Restaurant) and a polished thick-rounded underline indicator.

**Architecture:** Single-file change in `bookings_history_page.dart`. The `_tabs` static const is promoted to a package-level `kBookingHistoryTabs` constant so it can be unit-tested without rendering the full widget. The `TabBar` receives updated label styles, a custom `UnderlineTabIndicator` with `width: 3` and `borderRadius: 3`, and `dividerColor: transparent`.

**Tech Stack:** Flutter, Riverpod, Material 3

---

### Task 1: Write failing test for tab labels

**Files:**
- Modify: `lib/features/bookings_history/presentation/pages/bookings_history_page.dart`
- Create: `test/features/bookings_history/presentation/pages/bookings_history_page_tabs_test.dart`

- [ ] **Step 1: Add `kBookingHistoryTabs` constant to the page file**

In `lib/features/bookings_history/presentation/pages/bookings_history_page.dart`, directly below the import block and before the class declaration, add:

```dart
/// Semantic tab labels for the bookings history filter bar.
/// Order must match the [TabController] index assignments in [_BookingsHistoryPageState].
const kBookingHistoryTabs = [
  'All',
  'Sports',
  'Farm',
  'Concert',
  'Restaurant',
  'Memberships',
];
```

Do NOT change any other code yet. The class still references the old `_tabs` list.

- [ ] **Step 2: Create the failing test file**

Create `test/features/bookings_history/presentation/pages/bookings_history_page_tabs_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/bookings_history/presentation/pages/bookings_history_page.dart';

void main() {
  test('kBookingHistoryTabs has 6 entries with semantic category names', () {
    expect(kBookingHistoryTabs.length, 6);
    expect(kBookingHistoryTabs[0], 'All');
    expect(kBookingHistoryTabs[1], 'Sports');
    expect(kBookingHistoryTabs[2], 'Farm');
    expect(kBookingHistoryTabs[3], 'Concert');
    expect(kBookingHistoryTabs[4], 'Restaurant');
    expect(kBookingHistoryTabs[5], 'Memberships');
  });
}
```

- [ ] **Step 3: Run the test — verify it FAILS**

```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
flutter test test/features/bookings_history/presentation/pages/bookings_history_page_tabs_test.dart
```

Expected: test fails because `kBookingHistoryTabs` doesn't exist yet (step 1 added it but with the new values — actually after step 1 the test should already pass on the labels but the constant exists). 

> Note: After Step 1 the constant already has the new values, so this test will actually pass immediately. That's fine — TDD here is used to lock in the expected values before we wire them in. Run the test to confirm it passes before proceeding, then continue to Task 2.

---

### Task 2: Wire `kBookingHistoryTabs` into the widget and update `TabBar` styling

**Files:**
- Modify: `lib/features/bookings_history/presentation/pages/bookings_history_page.dart`

- [ ] **Step 1: Replace the `_tabs` static const with `kBookingHistoryTabs`**

In `_BookingsHistoryPageState`, find and remove:

```dart
  static const _tabs = [
    'All',
    'Hourly',
    'Shift',
    'Venue / Seat',
    'Reservation',
    'Memberships',
  ];
```

Update `initState` to use `kBookingHistoryTabs.length`:

```dart
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kBookingHistoryTabs.length, vsync: this);
  }
```

- [ ] **Step 2: Replace the `TabBar` widget with the redesigned version**

Find the existing `TabBar(...)` inside the `AppBar`'s `bottom:` property:

```dart
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          indicatorColor: cs.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
```

Replace with:

```dart
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.40),
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3, color: cs.primary),
            borderRadius: BorderRadius.circular(3),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: kBookingHistoryTabs.map((t) => Tab(text: t)).toList(),
        ),
```

- [ ] **Step 3: Verify the file compiles with no errors**

```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
flutter analyze lib/features/bookings_history/presentation/pages/bookings_history_page.dart
```

Expected: `No issues found!`

---

### Task 3: Run all tests and commit

**Files:** none (verification only)

- [ ] **Step 1: Run the tab label test**

```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
flutter test test/features/bookings_history/presentation/pages/bookings_history_page_tabs_test.dart -v
```

Expected:
```
✓ kBookingHistoryTabs has 6 entries with semantic category names
All tests passed!
```

- [ ] **Step 2: Run the full test suite to check for regressions**

```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
flutter test
```

Expected: all existing tests pass (shift_card_test, farm_shift_test, widget_test).

- [ ] **Step 3: Commit**

```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
git add lib/features/bookings_history/presentation/pages/bookings_history_page.dart \
        test/features/bookings_history/presentation/pages/bookings_history_page_tabs_test.dart
git commit -m "feat(ui): redesign bookings tab bar — semantic labels + thick rounded indicator"
```
