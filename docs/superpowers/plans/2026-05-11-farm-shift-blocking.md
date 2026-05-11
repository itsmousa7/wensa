# Farm Shift Blocking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After a farm booking is confirmed (payment complete), the corresponding shift(s) on that date appear grayed-out with a "Booked" label in the mobile app and cannot be selected.

**Architecture:** New `bookings.available_farm_shifts(place_id, date)` Supabase RPC returns shift definitions plus an `is_available` boolean per shift. The Flutter `farmShiftsProvider` gains a `date` parameter and calls this RPC. `ShiftCard` gains an `isBooked` parameter that renders a disabled "Booked" state. `FarmSection` wires the date-aware provider and passes `isBooked` down.

**Tech Stack:** Supabase/PostgreSQL, Flutter + Dart, Riverpod (`riverpod_annotation`), Freezed, `supabase_flutter`.

---

## File Map

| File | Action |
|------|--------|
| `supabase/migrations/20260511000002_farm_shift_availability.sql` | **Create** — RPC + public wrapper |
| `lib/features/booking/domain/models/farm_shift.dart` | **Modify** — add `isAvailable` field |
| `lib/features/booking/domain/models/farm_shift.freezed.dart` | **Regenerate** via `build_runner` |
| `lib/features/booking/domain/models/farm_shift.g.dart` | **Regenerate** via `build_runner` |
| `lib/features/booking/domain/repositories/booking_repository.dart` | **Modify** — `fetchFarmShifts` takes `date`, calls RPC |
| `lib/features/booking/presentation/providers/availability_provider.dart` | **Modify** — `farmShiftsProvider` gains `date` param |
| `lib/features/booking/presentation/providers/availability_provider.g.dart` | **Regenerate** via `build_runner` |
| `lib/features/booking/presentation/widgets/shift_card.dart` | **Modify** — add `isBooked` param + booked UI state |
| `lib/features/booking/presentation/sections/farm_section.dart` | **Modify** — pass date to provider, `isBooked` to `ShiftCard` |
| `test/features/booking/domain/models/farm_shift_test.dart` | **Create** — unit tests for `fromJson` with `is_available` |
| `test/features/booking/presentation/widgets/shift_card_test.dart` | **Create** — widget tests for booked state rendering |

---

### Task 1: Supabase migration — `available_farm_shifts` RPC

**Files:**
- Create: `supabase/migrations/20260511000002_farm_shift_availability.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- ============================================================
-- Migration: Farm shift availability RPC
-- Date: 2026-05-11
-- ============================================================
--
-- Returns one row per configured shift for a farm + date,
-- with is_available = true when no confirmed booking overlaps
-- that shift's time window. Uses the same overnight logic as
-- create_farm_booking (ends_time <= starts_time → next day).

CREATE OR REPLACE FUNCTION bookings.available_farm_shifts(
  p_place_id uuid,
  p_date     date
)
RETURNS TABLE (
  place_id     uuid,
  shift_type   bookings.farm_shift_type,
  starts_time  time,
  ends_time    time,
  price_iqd    integer,
  is_available boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT
    fs.place_id,
    fs.shift_type,
    fs.starts_time,
    fs.ends_time,
    fs.price_iqd,
    NOT EXISTS (
      SELECT 1
      FROM bookings.bookings b
      WHERE b.place_id = p_place_id
        AND b.category = 'farm'
        AND b.status   = 'confirmed'
        AND tstzrange(b.starts_at, b.ends_at, '[)') &&
            tstzrange(
              (p_date::text || ' ' || fs.starts_time::text)::timestamp
                AT TIME ZONE 'Asia/Baghdad',
              CASE WHEN fs.ends_time <= fs.starts_time
                THEN ((p_date + 1)::text || ' ' || fs.ends_time::text)::timestamp
                       AT TIME ZONE 'Asia/Baghdad'
                ELSE (p_date::text || ' ' || fs.ends_time::text)::timestamp
                       AT TIME ZONE 'Asia/Baghdad'
              END,
              '[)'
            )
    ) AS is_available
  FROM bookings.farm_shifts fs
  WHERE fs.place_id = p_place_id
  ORDER BY fs.starts_time;
$$;

-- PostgREST-accessible wrapper (shift_type cast to text for JSON serialisation)
CREATE OR REPLACE FUNCTION public.available_farm_shifts(
  p_place_id uuid,
  p_date     date
)
RETURNS TABLE (
  place_id     uuid,
  shift_type   text,
  starts_time  time,
  ends_time    time,
  price_iqd    integer,
  is_available boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = bookings, public
AS $$
  SELECT
    place_id,
    shift_type::text,
    starts_time,
    ends_time,
    price_iqd,
    is_available
  FROM bookings.available_farm_shifts(p_place_id, p_date);
$$;

GRANT EXECUTE ON FUNCTION public.available_farm_shifts(uuid, date)
  TO anon, authenticated;
```

- [ ] **Step 2: Apply the migration to Supabase**

```bash
supabase db push
```

Expected: migration applies without error.

- [ ] **Step 3: Smoke-test the RPC in the Supabase dashboard SQL editor**

```sql
-- Substitute a real farm place_id from your content.places table
SELECT * FROM bookings.available_farm_shifts(
  '<your-farm-place-id>'::uuid,
  current_date
);
```

Expected: 3 rows (day / night / full), all with `is_available = true` if no confirmed booking exists for today. Book one shift and confirm it, then re-run — that shift and any overlapping shift (e.g., full overlaps day+night) should show `is_available = false`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260511000002_farm_shift_availability.sql
git commit -m "feat(db): add available_farm_shifts RPC"
```

---

### Task 2: `FarmShift` model — add `isAvailable` field

**Files:**
- Modify: `lib/features/booking/domain/models/farm_shift.dart`
- Create: `test/features/booking/domain/models/farm_shift_test.dart`
- Regenerate: `farm_shift.freezed.dart`, `farm_shift.g.dart` (done in Task 3)

- [ ] **Step 1: Write the failing unit test**

Create `test/features/booking/domain/models/farm_shift_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';

void main() {
  group('FarmShift.fromJson', () {
    const baseJson = {
      'place_id': 'place-abc',
      'shift_type': 'day',
      'starts_time': '08:00:00',
      'ends_time': '18:00:00',
      'price_iqd': 100000,
    };

    test('parses is_available true', () {
      final shift = FarmShift.fromJson({...baseJson, 'is_available': true});
      expect(shift.isAvailable, isTrue);
    });

    test('parses is_available false', () {
      final shift = FarmShift.fromJson({...baseJson, 'is_available': false});
      expect(shift.isAvailable, isFalse);
    });

    test('defaults isAvailable to true when field is absent', () {
      final shift = FarmShift.fromJson(baseJson);
      expect(shift.isAvailable, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the test — expect compilation failure**

```bash
dart test test/features/booking/domain/models/farm_shift_test.dart
```

Expected: compile error — `The getter 'isAvailable' isn't defined for the class 'FarmShift'`.

- [ ] **Step 3: Add `isAvailable` to the `FarmShift` model**

Replace the entire content of `lib/features/booking/domain/models/farm_shift.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'booking_enums.dart';

part 'farm_shift.freezed.dart';
part 'farm_shift.g.dart';

@freezed
abstract class FarmShift with _$FarmShift {
  const factory FarmShift({
    @Default('') String placeId,
    @Default(FarmShiftType.day) FarmShiftType shiftType,
    @Default('') String startsTime,
    @Default('') String endsTime,
    @Default(0) int priceIqd,
    @Default(true) bool isAvailable,
  }) = _FarmShift;

  factory FarmShift.fromJson(Map<String, dynamic> json) => FarmShift(
        placeId: json['place_id'] ?? '',
        shiftType: FarmShiftTypeFromString.fromString(json['shift_type'] ?? ''),
        startsTime: json['starts_time'] ?? '',
        endsTime: json['ends_time'] ?? '',
        priceIqd: (json['price_iqd'] as num?)?.toInt() ?? 0,
        isAvailable: (json['is_available'] as bool?) ?? true,
      );
}
```

- [ ] **Step 4: Regenerate Freezed/JSON files**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `farm_shift.freezed.dart` and `farm_shift.g.dart` regenerated without errors.

- [ ] **Step 5: Run the test — expect pass**

```bash
dart test test/features/booking/domain/models/farm_shift_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/booking/domain/models/farm_shift.dart \
        lib/features/booking/domain/models/farm_shift.freezed.dart \
        lib/features/booking/domain/models/farm_shift.g.dart \
        test/features/booking/domain/models/farm_shift_test.dart
git commit -m "feat(model): add isAvailable to FarmShift"
```

---

### Task 3: Repository + Provider — wire date-aware RPC call

**Files:**
- Modify: `lib/features/booking/domain/repositories/booking_repository.dart`
- Modify: `lib/features/booking/presentation/providers/availability_provider.dart`
- Regenerate: `availability_provider.g.dart` (done at end of this task)

- [ ] **Step 1: Update `fetchFarmShifts` in `BookingRepository`**

In `lib/features/booking/domain/repositories/booking_repository.dart`, replace the existing `fetchFarmShifts` method:

```dart
// BEFORE:
Future<List<FarmShift>> fetchFarmShifts(String placeId) async {
  final data = await _client.schema('bookings').from('farm_shifts').select().eq('place_id', placeId);
  return data.map(FarmShift.fromJson).toList();
}

// AFTER:
Future<List<FarmShift>> fetchFarmShifts(String placeId, String date) async {
  final data = await _client.schema('bookings').rpc(
    'available_farm_shifts',
    params: {'p_place_id': placeId, 'p_date': date},
  );
  return (data as List)
      .map((e) => FarmShift.fromJson(e as Map<String, dynamic>))
      .toList();
}
```

- [ ] **Step 2: Update `farmShiftsProvider` to accept `date`**

In `lib/features/booking/presentation/providers/availability_provider.dart`, replace:

```dart
// BEFORE:
@riverpod
Future<List<FarmShift>> farmShifts(Ref ref, String placeId) =>
    ref.watch(bookingRepositoryProvider).fetchFarmShifts(placeId);

// AFTER:
@riverpod
Future<List<FarmShift>> farmShifts(Ref ref, String placeId, String date) =>
    ref.watch(bookingRepositoryProvider).fetchFarmShifts(placeId, date);
```

- [ ] **Step 3: Regenerate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `availability_provider.g.dart` regenerated. The generated `FarmShiftsProvider` now takes `(placeId, date)` as its family parameters.

- [ ] **Step 4: Commit**

```bash
git add lib/features/booking/domain/repositories/booking_repository.dart \
        lib/features/booking/presentation/providers/availability_provider.dart \
        lib/features/booking/presentation/providers/availability_provider.g.dart
git commit -m "feat(repo): fetchFarmShifts calls availability RPC with date"
```

---

### Task 4: `ShiftCard` — booked state UI

**Files:**
- Modify: `lib/features/booking/presentation/widgets/shift_card.dart`
- Create: `test/features/booking/presentation/widgets/shift_card_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/booking/presentation/widgets/shift_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/shift_card.dart';

void main() {
  const shift = FarmShift(
    placeId: 'p1',
    shiftType: FarmShiftType.day,
    startsTime: '08:00:00',
    endsTime: '18:00:00',
    priceIqd: 100000,
    isAvailable: false,
  );

  Widget buildCard({required bool isBooked, required VoidCallback onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: ShiftCard(
          shift: shift,
          isSelected: false,
          isBooked: isBooked,
          onTap: onTap,
        ),
      ),
    );
  }

  group('ShiftCard booked state', () {
    testWidgets('shows "Booked" chip when isBooked is true', (tester) async {
      await tester.pumpWidget(buildCard(isBooked: true, onTap: () {}));
      expect(find.text('Booked'), findsOneWidget);
    });

    testWidgets('does not show "Booked" chip when isBooked is false', (tester) async {
      await tester.pumpWidget(buildCard(isBooked: false, onTap: () {}));
      expect(find.text('Booked'), findsNothing);
    });

    testWidgets('does not call onTap when isBooked is true', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
          buildCard(isBooked: true, onTap: () => tapped = true));
      await tester.tap(find.byType(ShiftCard));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('calls onTap when isBooked is false', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
          buildCard(isBooked: false, onTap: () => tapped = true));
      await tester.tap(find.byType(ShiftCard));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the tests — expect compilation failure**

```bash
dart test test/features/booking/presentation/widgets/shift_card_test.dart
```

Expected: compile error — `'isBooked' isn't defined`.

- [ ] **Step 3: Rewrite `ShiftCard` with `isBooked` support**

Replace the entire content of `lib/features/booking/presentation/widgets/shift_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.shift,
    required this.isSelected,
    required this.isBooked,
    required this.onTap,
  });

  final FarmShift shift;
  final bool isSelected;
  final bool isBooked;
  final VoidCallback onTap;

  IconData _icon() {
    switch (shift.shiftType) {
      case FarmShiftType.day:
        return Icons.wb_sunny;
      case FarmShiftType.night:
        return Icons.nightlight_round;
      case FarmShiftType.full:
        return Icons.brightness_4;
    }
  }

  String _label() {
    switch (shift.shiftType) {
      case FarmShiftType.day:
        return 'Day';
      case FarmShiftType.night:
        return 'Night';
      case FarmShiftType.full:
        return 'Full Day';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final Color backgroundColor;
    final Color foregroundColor;
    final Color subtextColor;

    if (isBooked) {
      backgroundColor =
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      foregroundColor = colorScheme.onSurface.withValues(alpha: 0.38);
      subtextColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else if (isSelected) {
      backgroundColor = colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
      subtextColor = colorScheme.onPrimary.withValues(alpha: 0.8);
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      foregroundColor = colorScheme.onSurface;
      subtextColor = colorScheme.outline;
    }

    return GestureDetector(
      onTap: isBooked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected && !isBooked
              ? Border.all(color: colorScheme.primary, width: 2)
              : Border.all(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(_icon(), color: foregroundColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _label(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      // "Booked" chip — takes priority over "Blocks the full day"
                      if (isBooked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAr ? 'محجوز' : 'Booked',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                    ),
                          ),
                        ),
                      ] else if (shift.shiftType == FarmShiftType.full) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(alpha: 0.2)
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAr ? 'يحجب اليوم كاملاً' : 'Blocks the full day',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.onPrimaryContainer,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shift.startsTime} – ${shift.endsTime}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtextColor,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${shift.priceIqd} IQD',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the widget tests — expect pass**

```bash
dart test test/features/booking/presentation/widgets/shift_card_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/widgets/shift_card.dart \
        test/features/booking/presentation/widgets/shift_card_test.dart
git commit -m "feat(ui): ShiftCard booked state — grayed out with Booked chip"
```

---

### Task 5: `FarmSection` — pass date to provider and `isBooked` to `ShiftCard`

**Files:**
- Modify: `lib/features/booking/presentation/sections/farm_section.dart`

- [ ] **Step 1: Update the `farmShiftsProvider` watch call to include the date**

In `lib/features/booking/presentation/sections/farm_section.dart`, inside `_FarmBookingFormView.build`, replace:

```dart
// BEFORE:
final shiftsAsync = ref.watch(farmShiftsProvider(placeId));

// AFTER:
final shiftsAsync = ref.watch(
  farmShiftsProvider(placeId, bookingFormatDate(selectedDate)),
);
```

`selectedDate` is already in scope from the line just above (`ref.watch(_farmSelectedDateProvider)`). Because `farmShiftsProvider` is now keyed on `(placeId, date)`, selecting a different date in the `BookingDateStrip` automatically triggers a re-fetch for the new date — no manual invalidation needed.

- [ ] **Step 2: Pass `isBooked` to every `ShiftCard`**

In the same file, find the `ShiftCard(...)` constructor call and add `isBooked`:

```dart
// BEFORE:
child: ShiftCard(
  shift: shift,
  isSelected: isSelected,
  onTap: () {
    ref
        .read(_farmSelectedShiftProvider.notifier)
        .set(isSelected ? null : shift);
  },
),

// AFTER:
child: ShiftCard(
  shift: shift,
  isSelected: isSelected,
  isBooked: !shift.isAvailable,
  onTap: () {
    ref
        .read(_farmSelectedShiftProvider.notifier)
        .set(isSelected ? null : shift);
  },
),
```

- [ ] **Step 3: Build to verify no analysis errors**

```bash
flutter analyze lib/features/booking/presentation/sections/farm_section.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Run all tests**

```bash
dart test
```

Expected: all tests pass (including the two new test files from Tasks 2 and 4).

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/sections/farm_section.dart
git commit -m "feat(ui): FarmSection uses date-aware shift availability"
```

---

## Manual End-to-End Verification

After all tasks are complete, verify the following on a device or simulator:

1. **Book day shift → confirm payment → reopen farm page on same date**
   - Day shift: grayed out, "Booked" chip visible, not tappable
   - Full-day shift: grayed out, "Booked" chip visible (time ranges overlap)
   - Night shift: still selectable

2. **Book full-day → confirm payment → reopen**
   - All three shifts grayed out with "Booked" chip

3. **Cancel the confirmed booking → reopen**
   - All shifts selectable again

4. **Switch to a different date**
   - All shifts show as available (no bookings on that date)

5. **Arabic locale**
   - Booked chip shows "محجوز"
