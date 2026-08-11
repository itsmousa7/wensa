# Inline Payment Method Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the "Payment Method" modal bottom sheet with an inline card
section embedded directly in each checkout container (Toters-style icon-badge
rows + radio indicator), across all five booking flows that currently use it.

**Architecture:** A new stateless `PaymentMethodSelector` widget replaces the
sheet UI in `payment_method_sheet.dart` (which keeps only its unrelated
`goToCashBookingSuccess` helper). `BookingSummaryCard` gains an optional
`paymentMethodSlot` render slot. Each of the five call sites gets its own
local Riverpod (or `setState`) selection state, following the exact pattern
already used for that file's other local selections (plan/court/date/promo),
and gates its "Proceed to Payment" button on a non-null selection instead of
awaiting the sheet's return value.

**Tech Stack:** Flutter 3.44 (Dart), `flutter_riverpod` (Notifier /
NotifierProvider.autoDispose), `flutter_test` (`testWidgets`). Package name:
`future_riverpod`.

## Global Constraints

- Package import root is `package:future_riverpod/...` — match this exactly
  in every new import.
- Localization pattern used everywhere in this codebase: `final isAr =
  Localizations.localeOf(context).languageCode == 'ar';` then `isAr ? '...' :
  '...'` inline — no separate l10n files.
- Theming: read colors via `Theme.of(context).colorScheme`, never hardcode
  hex except where the codebase already does so for brand colors (Cash green
  `0xFF17A673` is the one existing exception — reuse it, don't invent a new
  color).
- Existing widget-test convention (see
  `test/features/booking/presentation/widgets/party_option_card_test.dart`):
  a local `Widget wrap(Widget child) => MaterialApp(home: Scaffold(body:
  child));` helper, `testWidgets(...)`, assertions via `find.text` /
  `tester.widget<T>(...)`.
- `PaymentMethod` enum already exists at
  `lib/features/booking/domain/models/booking_enums.dart:3` (`enum
  PaymentMethod { wayl, cash }`) — reuse it, do not redefine.
- Local per-flow selection state in this codebase always follows the same
  three-part shape: a private `Notifier<T>` class, a private
  `NotifierProvider.autoDispose<NotifierClass, T>` top-level variable, and a
  `.set(value)` method — e.g. `_padelPromoProvider` /
  `_PadelPromoNotifier` in `padel_section.dart`. New payment-method
  providers must follow this exact shape for consistency.

---

## Task 1: `PaymentMethodSelector` widget + trim the old sheet

**Files:**
- Create: `lib/features/booking/presentation/widgets/payment_method_selector.dart`
- Modify: `lib/features/booking/presentation/widgets/payment_method_sheet.dart`
- Test: `test/features/booking/presentation/widgets/payment_method_selector_test.dart`

**Interfaces:**
- Produces: `PaymentMethodSelector({required bool cashEnabled, required
  PaymentMethod? selected, required ValueChanged<PaymentMethod> onChanged})`
  — a `StatelessWidget`, purely presentational, caller owns state. Consumed
  by Tasks 2–7.
- `payment_method_sheet.dart` keeps exporting `goToCashBookingSuccess(...)`
  unchanged (still consumed by Tasks 3–7); `showPaymentMethodSheet` and
  `_PaymentMethodSheet`/`_PaymentMethodRow` are deleted from it.

- [ ] **Step 1: Write the failing test**

Create `test/features/booking/presentation/widgets/payment_method_selector_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_selector.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows both rows when cashEnabled is true', (tester) async {
    await tester.pumpWidget(
      wrap(
        PaymentMethodSelector(
          cashEnabled: true,
          selected: null,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('E-Payment'), findsOneWidget);
  });

  testWidgets('hides the Cash row when cashEnabled is false', (tester) async {
    await tester.pumpWidget(
      wrap(
        PaymentMethodSelector(
          cashEnabled: false,
          selected: null,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Cash'), findsNothing);
    expect(find.text('E-Payment'), findsOneWidget);
  });

  testWidgets('tapping Cash calls onChanged with PaymentMethod.cash', (
    tester,
  ) async {
    PaymentMethod? picked;
    await tester.pumpWidget(
      wrap(
        PaymentMethodSelector(
          cashEnabled: true,
          selected: null,
          onChanged: (m) => picked = m,
        ),
      ),
    );
    await tester.tap(find.text('Cash'));
    await tester.pump();
    expect(picked, PaymentMethod.cash);
  });

  testWidgets('tapping E-Payment calls onChanged with PaymentMethod.wayl', (
    tester,
  ) async {
    PaymentMethod? picked;
    await tester.pumpWidget(
      wrap(
        PaymentMethodSelector(
          cashEnabled: true,
          selected: null,
          onChanged: (m) => picked = m,
        ),
      ),
    );
    await tester.tap(find.text('E-Payment'));
    await tester.pump();
    expect(picked, PaymentMethod.wayl);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/booking/presentation/widgets/payment_method_selector_test.dart`
Expected: FAIL — `payment_method_selector.dart` doesn't exist yet (import error).

- [ ] **Step 3: Create the widget**

Create `lib/features/booking/presentation/widgets/payment_method_selector.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';

/// Inline "Payment Method" section, shown directly inside the checkout
/// container (as [BookingSummaryCard.paymentMethodSlot] or inline in a
/// checkout sheet) instead of a modal dialog. Purely presentational — the
/// caller owns the selected value.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.cashEnabled,
    required this.selected,
    required this.onChanged,
  });

  /// Whether the Cash row is shown at all — false when the merchant/event
  /// has cash off, in which case E-Payment is the only option offered.
  final bool cashEnabled;

  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'طريقة الدفع' : 'Payment Method',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (cashEnabled) ...[
          _SelectorRow(
            icon: Icons.payments_rounded,
            iconBg: const Color(0xFF17A673),
            title: isAr ? 'نقداً' : 'Cash',
            subtitle: isAr ? 'ادفع عند الوصول' : 'Pay at the venue',
            isSelected: selected == PaymentMethod.cash,
            onTap: () => onChanged(PaymentMethod.cash),
          ),
          const _DashedDivider(),
        ],
        _SelectorRow(
          icon: Icons.credit_card_rounded,
          iconBg: cs.primary,
          title: isAr ? 'الدفع الإلكتروني' : 'E-Payment',
          subtitle: isAr ? 'ادفع الآن عبر الإنترنت' : 'Pay online now',
          isSelected: selected == PaymentMethod.wayl,
          onTap: () => onChanged(PaymentMethod.wayl),
        ),
      ],
    );
  }
}

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            _RadioDot(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? cs.primary : cs.outline,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary,
                ),
              ),
            )
          : null,
    );
  }
}

/// Flutter's stock [Divider] is solid, so this is a small one-off dashed
/// line to match the reference design's separator between rows.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 1,
        child: CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedLinePainter(color: color),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashGap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/booking/presentation/widgets/payment_method_selector_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Trim the old sheet down to just `goToCashBookingSuccess`**

Read `lib/features/booking/presentation/widgets/payment_method_sheet.dart`
first (it currently has `showPaymentMethodSheet`, `_PaymentMethodSheet`,
`_PaymentMethodRow`, then `goToCashBookingSuccess`). Replace its entire
contents with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart'
    show bookingsRefreshProvider;
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
import 'package:go_router/go_router.dart';

/// Shared tail for a cash-confirmed booking/membership: the server already
/// confirmed it (no webview needed), so just refresh caches and land on the
/// ticket page. [routeId] is the raw booking id, or `m_<membershipId>` for a
/// membership — same id shape `context.go('/bookings/$routeId')` expects
/// elsewhere in this feature.
void goToCashBookingSuccess({
  required BuildContext context,
  required WidgetRef ref,
  required String routeId,
  required VoidCallback resetSubmitState,
}) {
  resetSubmitState();
  ref.read(bookingsRefreshProvider.notifier).bump();
  ref.invalidate(userPurchaseHistoryProvider);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking confirmed! Pay with cash at the venue.'),
        backgroundColor: Colors.green,
      ),
    );
    context.go('/bookings/$routeId');
  }
}
```

The file keeps its name (`payment_method_sheet.dart`) even though it no
longer shows a sheet — all five call sites already import it for
`goToCashBookingSuccess`, and Tasks 3–7 are editing those same files anyway,
so renaming would only add import churn with no functional benefit.

- [ ] **Step 6: Confirm nothing else references the deleted symbols yet**

Run: `grep -rn "showPaymentMethodSheet\|_PaymentMethodSheet" lib/`
Expected: 5 matches, all `await showPaymentMethodSheet(...)` call sites in
`concert_section.dart` (×2), `membership_section.dart`, `padel_section.dart`,
`farm_section.dart` — these are fixed in Tasks 3–7, not this one. This step
is just confirming you haven't missed a 6th call site.

- [ ] **Step 7: Commit**

```bash
git add lib/features/booking/presentation/widgets/payment_method_selector.dart \
        lib/features/booking/presentation/widgets/payment_method_sheet.dart \
        test/features/booking/presentation/widgets/payment_method_selector_test.dart
git commit -m "feat(booking): add inline PaymentMethodSelector, retire sheet UI"
```

(This commit intentionally leaves the 5 call sites broken — Task 3 restores
`flutter analyze` to clean by consuming the new widget. If your workflow
requires every commit to compile cleanly, squash Tasks 1–3 before landing
instead of committing here.)

---

## Task 2: `BookingSummaryCard.paymentMethodSlot`

**Files:**
- Modify: `lib/features/booking/presentation/widgets/booking_summary_card.dart`
- Test: `test/features/booking/presentation/widgets/booking_summary_card_test.dart` (new file)

**Interfaces:**
- Consumes: nothing new.
- Produces: `BookingSummaryCard` gains `final Widget? paymentMethodSlot;`
  (optional, default `null`). Also changes disabled-state logic: the action
  button is now visually + functionally disabled whenever `onAction == null`
  (previously only `isLoading` disabled it) — `onAction` was already
  nullable (`final VoidCallback? onAction;`), this task is the first to
  actually pass `null` for it. Consumed by Tasks 3–7 via
  `paymentMethodSlot: PaymentMethodSelector(...)` and `onAction: selected ==
  null ? null : () async {...}`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/booking/presentation/widgets/booking_summary_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders paymentMethodSlot when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        BookingSummaryCard(
          title: 'Summary',
          rows: const [],
          paymentMethodSlot: const Text('PAYMENT_SLOT_MARKER'),
          actionLabel: 'Go',
          onAction: () {},
          isLoading: false,
        ),
      ),
    );
    expect(find.text('PAYMENT_SLOT_MARKER'), findsOneWidget);
  });

  testWidgets('renders nothing extra when paymentMethodSlot is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BookingSummaryCard(
          title: 'Summary',
          rows: const [],
          actionLabel: 'Go',
          onAction: () {},
          isLoading: false,
        ),
      ),
    );
    expect(find.text('PAYMENT_SLOT_MARKER'), findsNothing);
  });

  testWidgets('disables the action button when onAction is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BookingSummaryCard(
          title: 'Summary',
          rows: const [],
          actionLabel: 'Go',
          onAction: null,
          isLoading: false,
        ),
      ),
    );
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/booking/presentation/widgets/booking_summary_card_test.dart`
Expected: FAIL — `paymentMethodSlot` is not a defined named parameter, and
the "disables" test fails because `onTap` is currently `isLoading ? null :
onAction` = `onAction` = `null` already... re-check: actually the third test
may already pass today since `onTap: isLoading ? null : onAction` does
correctly become `null` when `onAction` is `null` and `isLoading` is
`false`. Only the first two tests (referencing `paymentMethodSlot`) fail to
compile. Expected: a compile error on the whole file from the unknown named
parameter, so all three tests report FAIL.

- [ ] **Step 3: Add `paymentMethodSlot` and the disabled-state fix**

In `lib/features/booking/presentation/widgets/booking_summary_card.dart`,
add the field next to `extraSlot` (after line 82, `final Widget?
extraSlot;`):

```dart
  /// Optional payment-method selector, rendered after the detail rows and
  /// before the subtotal/discount/total block.
  final Widget? paymentMethodSlot;
```

Add it to the constructor parameter list (next to `this.extraSlot,` in the
constructor signature):

```dart
    this.extraSlot,
    this.paymentMethodSlot,
```

In `build()`, add an `isDisabled` local right after the existing `isAr`
line:

```dart
    final colorScheme = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDisabled = isLoading || onAction == null;
```

Insert the slot's rendering right after the detail-rows loop and before the
`if (totalValue != null)` block:

```dart
                // Detail rows with dividers
                for (var i = 0; i < rows.length; i++) ...[
                  _DetailRow(row: rows[i]),
                  if (i < rows.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                ],

                if (paymentMethodSlot != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  paymentMethodSlot!,
                ],

                // Subtotal + discount + total stack
                if (totalValue != null) ...[
```

Finally, swap `isLoading` for `isDisabled` in the button's color and
`onTap` (leave every other reference to `isLoading`, e.g. the spinner-vs-text
`Center` child, unchanged — those should still key off the real loading
state):

```dart
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primary,
                      borderRadius: AppSpacing.borderRadiusLG,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isDisabled ? null : onAction,
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/booking/presentation/widgets/booking_summary_card_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Full-suite regression check**

Run: `flutter test`
Expected: PASS — no other test references `BookingSummaryCard`'s internals
in a way this change could break (it's an additive field plus an `isLoading`
→ `isDisabled` swap that's behavior-identical whenever `onAction != null`,
which is every existing call site until Task 3).

- [ ] **Step 6: Commit**

```bash
git add lib/features/booking/presentation/widgets/booking_summary_card.dart \
        test/features/booking/presentation/widgets/booking_summary_card_test.dart
git commit -m "feat(booking): add BookingSummaryCard.paymentMethodSlot, disable action button when onAction is null"
```

---

## Task 3: Wire the padel/sports booking flow

**Files:**
- Modify: `lib/features/booking/presentation/sections/padel_section.dart`

**Interfaces:**
- Consumes: `PaymentMethodSelector` (Task 1), `BookingSummaryCard.paymentMethodSlot` (Task 2).
- Produces: local `_padelPaymentMethodProvider` (`NotifierProvider.autoDispose<_PadelPaymentMethodNotifier, PaymentMethod?>`), file-scoped, not consumed elsewhere.

- [ ] **Step 1: Add imports**

At the top of `padel_section.dart`, add (alphabetically among the existing
`future_riverpod` imports):

```dart
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
```
right before the existing `import 'package:future_riverpod/features/booking/domain/models/court.dart';` line, and:
```dart
import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_selector.dart';
```
right before the existing `import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_sheet.dart';` line.

- [ ] **Step 2: Add the local provider**

Add, right after the existing `_PadelPromoNotifier` class (after the block
ending `void set(PromoApplied? p) => state = p; }`):

```dart
final _padelPaymentMethodProvider =
    NotifierProvider.autoDispose<_PadelPaymentMethodNotifier, PaymentMethod?>(
        _PadelPaymentMethodNotifier.new);

class _PadelPaymentMethodNotifier extends Notifier<PaymentMethod?> {
  @override
  PaymentMethod? build() => null;
  void set(PaymentMethod? m) => state = m;
}
```

- [ ] **Step 3: Watch it in `build()`**

Right after the existing `final promo = ref.watch(_padelPromoProvider);`
line, add:

```dart
    final selectedPaymentMethod = ref.watch(_padelPaymentMethodProvider);
```

- [ ] **Step 4: Pass `paymentMethodSlot` into the summary card**

Find:

```dart
                          totalLabel:
                              isAr ? 'المبلغ الإجمالي' : 'Total Amount',
                          totalValue:
                              _BookingFormView._formatIqd(eff.finalAmount),
                          extraSlot: promoBase > 0
                              ? PromoCodeField(
```

Replace with:

```dart
                          totalLabel:
                              isAr ? 'المبلغ الإجمالي' : 'Total Amount',
                          totalValue:
                              _BookingFormView._formatIqd(eff.finalAmount),
                          paymentMethodSlot: PaymentMethodSelector(
                            cashEnabled: place?.cashEnabled ?? false,
                            selected: selectedPaymentMethod,
                            onChanged: (m) => ref
                                .read(_padelPaymentMethodProvider.notifier)
                                .set(m),
                          ),
                          extraSlot: promoBase > 0
                              ? PromoCodeField(
```

- [ ] **Step 5: Gate `onAction` on the selection, drop the sheet call**

Find the full `onAction: () async { ... }` block (it starts right after
`actionLabel: isAr ? 'المتابعة للدفع' : 'Proceed to Payment',` and ends just
before `isLoading: isLoading,`) and replace it with:

```dart
                          actionLabel:
                              isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
                          onAction: selectedPaymentMethod == null
                              ? null
                              : () async {
                                  // If a pending booking already exists, reuse its payment URL
                                  // instead of creating a new booking (avoids DB constraint error).
                                  final current =
                                      ref.read(bookingSubmitProvider);
                                  final resumed = current.maybeWhen(
                                    success: (bookingId, paymentUrl,
                                        holdUntil, waylReferenceId, cash) {
                                      if (paymentUrl.isNotEmpty) {
                                        openPaymentWebView(bookingId,
                                            paymentUrl, waylReferenceId);
                                      } else if (cash) {
                                        goToCashBookingSuccess(
                                          context: context,
                                          ref: ref,
                                          routeId: bookingId,
                                          resetSubmitState: ref
                                              .read(bookingSubmitProvider
                                                  .notifier)
                                              .reset,
                                        );
                                      }
                                      return true;
                                    },
                                    orElse: () => false,
                                  );
                                  if (resumed) return;
                                  final method = selectedPaymentMethod;
                                  final sorted = selectedSlots.toList()
                                    ..sort();
                                  ref
                                      .read(bookingSubmitProvider.notifier)
                                      .createPadelBooking(
                                        placeId: placeId,
                                        courtId: selectedCourt.id,
                                        startsAt: sorted.first,
                                        hours: selectedSlots.length,
                                        promoCode: promo?.code,
                                        paymentMethod: method,
                                      );
                                },
                          isLoading: isLoading,
```

- [ ] **Step 6: Static + regression check**

Run: `flutter analyze lib/features/booking/presentation/sections/padel_section.dart`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS — no existing test covers `padel_section.dart` directly
(there's no `padel_section_test.dart` in this repo today), so this step is
confirming the change hasn't broken anything unrelated.

- [ ] **Step 7: Commit**

```bash
git add lib/features/booking/presentation/sections/padel_section.dart
git commit -m "feat(booking): inline payment method selection in padel booking flow"
```

---

## Task 4: Wire the membership purchase flow

**Files:**
- Modify: `lib/features/booking/presentation/sections/membership_section.dart`

**Interfaces:**
- Consumes: `PaymentMethodSelector` (Task 1), `BookingSummaryCard.paymentMethodSlot` (Task 2).
- Produces: local `_membershipPaymentMethodProvider` (`NotifierProvider.autoDispose<_MembershipPaymentMethodNotifier, PaymentMethod?>`), file-scoped.

- [ ] **Step 1: Add imports**

Add, alongside the existing `future_riverpod` imports:

```dart
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
```
right before `import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';`, and:
```dart
import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_selector.dart';
```
right before `import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_sheet.dart';`.

- [ ] **Step 2: Add the local provider**

Add, right after the existing `_MembershipPromoNotifier` class:

```dart
final _membershipPaymentMethodProvider = NotifierProvider.autoDispose<
    _MembershipPaymentMethodNotifier, PaymentMethod?>(
  _MembershipPaymentMethodNotifier.new,
);

class _MembershipPaymentMethodNotifier extends Notifier<PaymentMethod?> {
  @override
  PaymentMethod? build() => null;
  void set(PaymentMethod? m) => state = m;
}
```

- [ ] **Step 3: Watch it in `build()`**

Right after `final promo = ref.watch(_membershipPromoProvider);`, add:

```dart
    final selectedPaymentMethod =
        ref.watch(_membershipPaymentMethodProvider);
```

- [ ] **Step 4: Pass `paymentMethodSlot` into the summary card**

Find:

```dart
                          totalLabel: isAr ? 'الإجمالي' : 'Total Amount',
                          totalValue: _formatPrice(eff.finalAmount),
                          extraSlot: subtotal > 0
                              ? PromoCodeField(
```

Replace with:

```dart
                          totalLabel: isAr ? 'الإجمالي' : 'Total Amount',
                          totalValue: _formatPrice(eff.finalAmount),
                          paymentMethodSlot: PaymentMethodSelector(
                            cashEnabled: place?.cashEnabled ?? false,
                            selected: selectedPaymentMethod,
                            onChanged: (m) => ref
                                .read(
                                    _membershipPaymentMethodProvider.notifier)
                                .set(m),
                          ),
                          extraSlot: subtotal > 0
                              ? PromoCodeField(
```

- [ ] **Step 5: Gate `onAction` on the selection, drop the sheet call**

Find the full `onAction: () async { ... }` block for this file (starts
after `actionLabel: isAr ? 'المتابعة للدفع' : 'Proceed to Payment',`, ends
before `isLoading: isLoading,`) and replace it with:

```dart
                          actionLabel:
                              isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
                          onAction: selectedPaymentMethod == null
                              ? null
                              : () async {
                                  // If a pending membership already exists, reuse
                                  // its payment URL instead of creating a new one
                                  // (avoids the DB constraint on the still-open
                                  // pending row).
                                  final current =
                                      ref.read(membershipSubmitProvider);
                                  final resumed = current.maybeWhen(
                                    success: (bookingId, paymentUrl,
                                        holdUntil, waylReferenceId, cash) {
                                      if (paymentUrl.isNotEmpty) {
                                        _openMembershipPaymentWebView(
                                            context,
                                            ref,
                                            bookingId,
                                            paymentUrl,
                                            waylReferenceId);
                                      } else if (cash) {
                                        goToCashBookingSuccess(
                                          context: context,
                                          ref: ref,
                                          routeId: 'm_$bookingId',
                                          resetSubmitState: ref
                                              .read(membershipSubmitProvider
                                                  .notifier)
                                              .reset,
                                        );
                                      }
                                      return true;
                                    },
                                    orElse: () => false,
                                  );
                                  if (resumed) return;
                                  final method = selectedPaymentMethod;
                                  final plan = selectedPlan;
                                  ref
                                      .read(membershipSubmitProvider.notifier)
                                      .createMembership(
                                        placeId: placeId,
                                        planId: plan.id,
                                        promoCode: promo?.code,
                                        paymentMethod: method,
                                      );
                                },
                          isLoading: isLoading,
```

- [ ] **Step 6: Static + regression check**

Run: `flutter analyze lib/features/booking/presentation/sections/membership_section.dart`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/booking/presentation/sections/membership_section.dart
git commit -m "feat(booking): inline payment method selection in membership purchase flow"
```

---

## Task 5: Wire the farm booking flow

**Files:**
- Modify: `lib/features/booking/presentation/sections/farm_section.dart`

**Interfaces:**
- Consumes: `PaymentMethodSelector` (Task 1), `BookingSummaryCard.paymentMethodSlot` (Task 2).
- Produces: local `_farmPaymentMethodProvider` (`NotifierProvider.autoDispose<_FarmPaymentMethodNotifier, PaymentMethod?>`), file-scoped.

`booking_enums.dart` is already imported in this file (for `FarmShiftType`),
so only one new import is needed.

- [ ] **Step 1: Add the import**

Add, right before the existing
`import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_sheet.dart';`
line:

```dart
import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_selector.dart';
```

- [ ] **Step 2: Add the local provider**

Add, right after the existing `_FarmPromoNotifier` class (before the
`_FarmPartyOnNotifier` class):

```dart
final _farmPaymentMethodProvider =
    NotifierProvider.autoDispose<_FarmPaymentMethodNotifier, PaymentMethod?>(
      _FarmPaymentMethodNotifier.new,
    );

class _FarmPaymentMethodNotifier extends Notifier<PaymentMethod?> {
  @override
  PaymentMethod? build() => null;
  void set(PaymentMethod? m) => state = m;
}
```

- [ ] **Step 3: Watch it in `build()`**

Add, alongside the existing `ref.watch(_farmPromoProvider)` line (same
`_FarmBookingFormView.build` method):

```dart
    final selectedPaymentMethod = ref.watch(_farmPaymentMethodProvider);
```

- [ ] **Step 4: Pass `paymentMethodSlot` into the summary card**

Find:

```dart
                          totalLabel: isAr ? 'الإجمالي' : 'Total Amount',
                          totalValue: _FarmBookingFormView._formatIqd(
                            eff.finalAmount,
                          ),
                          extraSlot: subtotal > 0
                              ? PromoCodeField(
```

Replace with:

```dart
                          totalLabel: isAr ? 'الإجمالي' : 'Total Amount',
                          totalValue: _FarmBookingFormView._formatIqd(
                            eff.finalAmount,
                          ),
                          paymentMethodSlot: PaymentMethodSelector(
                            cashEnabled: place?.cashEnabled ?? false,
                            selected: selectedPaymentMethod,
                            onChanged: (m) => ref
                                .read(_farmPaymentMethodProvider.notifier)
                                .set(m),
                          ),
                          extraSlot: subtotal > 0
                              ? PromoCodeField(
```

- [ ] **Step 5: Gate `onAction` on the selection, drop the sheet call**

Find the full block starting at
`actionLabel: isAr ? 'المتابعة للدفع' : 'Proceed to Payment',` and ending
just before `isLoading: isLoading,`, and replace it with:

```dart
                          actionLabel: isAr
                              ? 'المتابعة للدفع'
                              : 'Proceed to Payment',
                          onAction: selectedPaymentMethod == null
                              ? null
                              : () async {
                                  if (guestCountRequired) {
                                    ref
                                        .read(_farmGuestCountErrorProvider
                                            .notifier)
                                        .set(true);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAr
                                              ? 'الرجاء إدخال عدد الأشخاص القادمين'
                                              : 'Please enter the number of guests',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  // If a pending booking already exists, reuse its payment URL
                                  // instead of creating a new booking (avoids DB constraint error).
                                  final current =
                                      ref.read(bookingSubmitProvider);
                                  final resumed = current.maybeWhen(
                                    success: (
                                      bookingId,
                                      paymentUrl,
                                      holdUntil,
                                      waylReferenceId,
                                      cash,
                                    ) {
                                      if (paymentUrl.isNotEmpty) {
                                        openPaymentWebView(
                                          bookingId,
                                          paymentUrl,
                                          waylReferenceId,
                                        );
                                      } else if (cash) {
                                        goToCashBookingSuccess(
                                          context: context,
                                          ref: ref,
                                          routeId: bookingId,
                                          resetSubmitState: ref
                                              .read(bookingSubmitProvider
                                                  .notifier)
                                              .reset,
                                        );
                                      }
                                      return true;
                                    },
                                    orElse: () => false,
                                  );
                                  if (resumed) return;
                                  final method = selectedPaymentMethod;
                                  final shift = selectedShift;
                                  ref
                                      .read(bookingSubmitProvider.notifier)
                                      .createFarmBooking(
                                        placeId: placeId,
                                        date: bookingFormatDate(
                                            selectedDate),
                                        shiftType: shift.shiftType,
                                        promoCode: promo?.code,
                                        partySize:
                                            (!partyOn &&
                                                shift.partyExtraPersonFeeIqd >
                                                    0)
                                            ? partyCount
                                            : null,
                                        bringingParty: partyOn,
                                        paymentMethod: method,
                                      );
                                },
                          isLoading: isLoading,
```

- [ ] **Step 6: Static + regression check**

Run: `flutter analyze lib/features/booking/presentation/sections/farm_section.dart`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/booking/presentation/sections/farm_section.dart
git commit -m "feat(booking): inline payment method selection in farm booking flow"
```

---

## Task 6: Wire the concert seat review sheet

**Files:**
- Modify: `lib/features/booking/presentation/sections/concert_section.dart`
  (`_ReviewSheet` — the seat-based checkout sheet)

**Interfaces:**
- Consumes: `PaymentMethodSelector` (Task 1), `PaymentMethod` (already
  imported in this file).
- Produces: local `_concertReviewPaymentMethodProvider`
  (`NotifierProvider.autoDispose<_ConcertReviewPaymentMethodNotifier,
  PaymentMethod?>`), used only by `_ReviewSheet` (Task 7's `_GASheet` uses
  its own `setState` field instead — the two sheets are mutually exclusive
  but each manages its own selection independently).

This flow is itself already a modal bottom sheet (`_ReviewSheet`, a
`DraggableScrollableSheet`) — there's no separate page to embed into here.
"Inline instead of a floating dialog" means putting the selector inside this
sheet's own scrollable body (between the seat list and the Total row)
instead of popping a second sheet on top when "Proceed to Payment" is
tapped.

- [ ] **Step 1: Add the import**

Add, right before the existing
`import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_sheet.dart';`
line:

```dart
import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_selector.dart';
```

- [ ] **Step 2: Add the local provider**

Add a new section right before the `// Review bottom sheet` comment header
(i.e. right before `class _ReviewSheet extends ConsumerWidget {`):

```dart
// ---------------------------------------------------------------------------
// Payment-method selection for the seat review sheet. autoDispose so a
// fresh sheet always starts unselected.
// ---------------------------------------------------------------------------

final _concertReviewPaymentMethodProvider = NotifierProvider.autoDispose<
    _ConcertReviewPaymentMethodNotifier, PaymentMethod?>(
  _ConcertReviewPaymentMethodNotifier.new,
);

class _ConcertReviewPaymentMethodNotifier extends Notifier<PaymentMethod?> {
  @override
  PaymentMethod? build() => null;
  void set(PaymentMethod? m) => state = m;
}

```

- [ ] **Step 3: Watch it in `_ReviewSheet.build()`**

Right after the existing
`final eventCashEnabled = ref.watch(eventDetailsProvider(eventId)).value?.cashEnabled ?? false;`
line, add:

```dart
    final selectedPaymentMethod =
        ref.watch(_concertReviewPaymentMethodProvider);
```

- [ ] **Step 4: Insert the selector between the seat list and the Total row**

Find:

```dart
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'الإجمالي' : 'Total',
```

(this is the end of the `ListView.separated` seat list inside `Expanded`,
immediately followed by the total row). Replace with:

```dart
                },
              ),
            ),
            const SizedBox(height: 8),
            PaymentMethodSelector(
              cashEnabled: eventCashEnabled,
              selected: selectedPaymentMethod,
              onChanged: (m) => ref
                  .read(_concertReviewPaymentMethodProvider.notifier)
                  .set(m),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'الإجمالي' : 'Total',
```

- [ ] **Step 5: Gate the button on the selection, drop the sheet call**

Find the `PrimaryActionButton` in `_ReviewSheet` (its `onTap` starts with
`selectedSeats.isEmpty ? null : () async {`) and replace the whole widget
with:

```dart
            PrimaryActionButton(
              label: isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
              isLoading: isLoading,
              onTap: (selectedSeats.isEmpty || selectedPaymentMethod == null)
                  ? null
                  : () async {
                      // If a pending group already exists (e.g. the user
                      // closed the payment webview and is retrying), reuse
                      // its payment URL instead of creating a new one —
                      // avoids conflicting with the still-held seats.
                      final current = ref.read(bookingSubmitProvider);
                      final resumed = current.maybeWhen(
                        success: (groupId, paymentUrl, holdUntil,
                            waylReferenceId, cash) {
                          if (paymentUrl.isNotEmpty) {
                            _openConcertPaymentWebView(
                              context,
                              ref,
                              eventId: eventId,
                              groupId: groupId,
                              paymentUrl: paymentUrl,
                              holdUntil: holdUntil,
                              waylReferenceId: waylReferenceId,
                            );
                          }
                          return true;
                        },
                        orElse: () => false,
                      );
                      if (resumed) return;
                      final method = selectedPaymentMethod;
                      // Keep the sheet visible while create-booking runs.
                      // The parent listener pops it once the Wayl URL is
                      // ready (see `_dismissCheckoutSheet`).
                      ref
                          .read(bookingSubmitProvider.notifier)
                          .createConcertBooking(
                            eventId: eventId,
                            seatIds: selectedSeats
                                .map((s) => s.seatId)
                                .toList(),
                            paymentMethod: method,
                          );
                    },
            ),
```

- [ ] **Step 6: Static check** (full-suite + regression check deferred to Task 7, since Task 7 shares this file and this file still has the GA sheet's un-migrated `showPaymentMethodSheet` call until then)

Run: `grep -c "showPaymentMethodSheet" lib/features/booking/presentation/sections/concert_section.dart`
Expected: `1` (only the `_GASheet` call site remains — confirms `_ReviewSheet`'s call was successfully removed).

- [ ] **Step 7: Commit**

```bash
git add lib/features/booking/presentation/sections/concert_section.dart
git commit -m "feat(booking): inline payment method selection in concert seat review sheet"
```

---

## Task 7: Wire the concert general-admission sheet

**Files:**
- Modify: `lib/features/booking/presentation/sections/concert_section.dart`
  (`_GASheet` — the general-admission checkout sheet)

**Interfaces:**
- Consumes: `PaymentMethodSelector` (Task 1), `PaymentMethod` (already imported).
- Produces: `_GASheetState._paymentMethod` (plain `PaymentMethod?` field, no
  new provider — `_GASheet` is already a `ConsumerStatefulWidget` with local
  `_quantity` state, so this follows that existing pattern instead of
  Task 6's provider pattern).

- [ ] **Step 1: Add the local field**

In `_GASheetState`, right next to the existing `int _quantity = 1;` field,
add:

```dart
class _GASheetState extends ConsumerState<_GASheet> {
  int _quantity = 1;
  PaymentMethod? _paymentMethod;
```

- [ ] **Step 2: Insert the selector between the "remaining tickets" text and the Total row**

Find:

```dart
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? "الإجمالي" : "Total",
```

(this is the block right after the `Align`/"N tickets remaining" `Text`,
inside `_GASheetState.build`). Replace with:

```dart
            const SizedBox(height: 16),
            PaymentMethodSelector(
              cashEnabled: eventCashEnabled,
              selected: _paymentMethod,
              onChanged: (m) => setState(() => _paymentMethod = m),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? "الإجمالي" : "Total",
```

- [ ] **Step 3: Gate the button on the selection, drop the sheet call**

Find the `PrimaryActionButton` in `_GASheetState.build` (its `onTap` starts
with `remaining <= 0 || price <= 0 ? null : () async {`) and replace the
whole widget with:

```dart
            PrimaryActionButton(
              label: isAr ? "متابعة للدفع" : "Proceed to Payment",
              isLoading: isLoading,
              onTap: (remaining <= 0 || price <= 0 || _paymentMethod == null)
                  ? null
                  : () async {
                      // If a pending group already exists (e.g. the user
                      // closed the payment webview and is retrying), reuse
                      // its payment URL instead of creating a new one.
                      final current = ref.read(bookingSubmitProvider);
                      final resumed = current.maybeWhen(
                        success: (groupId, paymentUrl, holdUntil,
                            waylReferenceId, cash) {
                          if (paymentUrl.isNotEmpty) {
                            _openConcertPaymentWebView(
                              context,
                              ref,
                              eventId: widget.eventId,
                              groupId: groupId,
                              paymentUrl: paymentUrl,
                              holdUntil: holdUntil,
                              waylReferenceId: waylReferenceId,
                            );
                          }
                          return true;
                        },
                        orElse: () => false,
                      );
                      if (resumed) return;
                      final method = _paymentMethod!;
                      // Keep the sheet visible until the parent's
                      // listener dismisses it once the Wayl URL is
                      // available.
                      ref
                          .read(bookingSubmitProvider.notifier)
                          .createGeneralAdmissionBooking(
                            eventId: widget.eventId,
                            sectionId: widget.section.id,
                            quantity: _quantity,
                            paymentMethod: method,
                          );
                    },
            ),
```

- [ ] **Step 4: Static + regression check**

Run: `flutter analyze lib/features/booking/presentation/sections/concert_section.dart`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/sections/concert_section.dart
git commit -m "feat(booking): inline payment method selection in concert GA sheet"
```

---

## Task 8: Whole-repo verification + manual QA

**Files:** none (verification only).

- [ ] **Step 1: Confirm the old sheet is fully retired**

Run: `grep -rn "showPaymentMethodSheet\|_PaymentMethodSheet\|_PaymentMethodRow" lib/`
Expected: no matches anywhere in `lib/` (all 5 call sites migrated across
Tasks 3–7, and Task 1 deleted the definitions).

- [ ] **Step 2: Full static analysis**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Full test suite**

Run: `flutter test`
Expected: PASS, full suite (including the 7 new tests from Tasks 1–2).

- [ ] **Step 4: Manual QA on a device/simulator**

This step needs a running app (`flutter run`) — it isn't automatable from
this plan. Cover, per the design spec's Testing section:

- All five flows (padel, farm, membership, concert seat, concert GA): the
  "Payment Method" section renders inline (not as a popup), "Proceed to
  Payment" starts disabled, tapping Cash or E-Payment enables it, and the
  booking submits with the tapped method.
- One flow with `cashEnabled: false` (a merchant/event with cash off):
  confirm the Cash row is hidden entirely and E-Payment-only still requires
  an explicit tap before the button enables (no silent default).
- Arabic (RTL) layout: label, row icon/text order, dashed divider, and radio
  indicator position all mirror correctly.
- The "resumed pending booking" retry path (close the Wayl webview, re-tap
  "Proceed to Payment"): still works and bypasses the payment-method gate
  entirely, same as before the change.

- [ ] **Step 5: Final commit (if Step 4 surfaces fixes)**

Only if manual QA in Step 4 requires code changes — otherwise no commit
needed for this task.
