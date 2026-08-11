# Inline Payment Method Design

Date: 2026-08-11

## Goal

Replace the "Payment Method" modal bottom sheet (`showPaymentMethodSheet` in
`payment_method_sheet.dart`) with an inline section embedded directly in each
checkout container, styled per the provided Toters reference screenshot:
white rounded card, "Payment Method" label, icon-badge rows with a trailing
radio indicator and a dashed divider between options — no popup dialog on
top of the checkout.

Applies to all five current call sites: concert seat booking, concert
general-admission booking, membership purchase, padel/sports booking, farm
booking.

## Non-goals

- Restaurant booking doesn't offer a payment-method choice today and stays
  that way — out of scope.
- No "View all", wallet top-up, or voucher-card sections from the Toters
  screenshot — only the Payment Method card portion is being replicated.
- No change to the Cash/Wayl submission logic itself (`create-booking` /
  `create-membership` request shape, response handling, `goToCashBookingSuccess`)
  — this is a selection-UI change only.

## 1. New shared widget: `PaymentMethodSelector`

Replaces the sheet-launching UI in `payment_method_sheet.dart`. The file
keeps `goToCashBookingSuccess` (unrelated post-cash-confirmation helper) but
loses `showPaymentMethodSheet` / `_PaymentMethodSheet`.

```dart
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.cashEnabled,
    required this.selected,
    required this.onChanged,
  });
  final bool cashEnabled;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onChanged;
}
```

Renders, top to bottom:

1. "Payment Method" / "طريقة الدفع" label (`titleMedium`, weight 700).
2. Cash row — shown only when `cashEnabled` is true.
3. A dashed divider — only between two rows (i.e. only when Cash is shown).
4. E-Payment row — always shown.

Each row (`_SelectorRow`, private) keeps today's visual language from
`_PaymentMethodRow` (48×48 rounded-12 icon chip, title 700-weight, outline
subtitle) but swaps the trailing `chevron_right` for a radio indicator, and
`onTap` calls `onChanged(method)` instead of `Navigator.pop`:

- Cash: green `0xFF17A673` chip, `Icons.payments_rounded`, "Cash" / "نقداً",
  "Pay at the venue" / "ادفع عند الوصول".
- E-Payment: `colorScheme.primary` chip, `Icons.credit_card_rounded`,
  "E-Payment" / "الدفع الإلكتروني", "Pay online now" / "ادفع الآن عبر الإنترنت".
- Radio indicator: 22px circle, `colorScheme.outline` ring when unselected;
  `colorScheme.primary` ring + filled dot when `selected == method`.
- Row is wrapped in `InkWell` (whole row tappable), `borderRadius: 16`.

### Dashed divider

Flutter's stock `Divider` is solid, so add a small private `_DashedDivider`
(`CustomPaint` + `CustomPainter`) drawing a horizontal dashed line,
`colorScheme.outline.withValues(alpha: 0.3)`, ~4px dash / 3px gap, 1px thick.
Lives in the same file — it's a one-off implementation detail, not a shared
design-system primitive.

## 2. `BookingSummaryCard` change

Add an optional field:

```dart
/// Optional payment-method selector, rendered after the detail rows and
/// before the subtotal/discount/total block.
final Widget? paymentMethodSlot;
```

Rendered right after the existing detail-rows loop (with the same
`Divider(height: 1)` separator style already used between rows) and before
the `if (totalValue != null)` block — i.e. above the totals, mirroring the
Toters screenshot's vertical order (payment method sits well above the
sticky total/footer). `extraSlot` (promo code field) is unaffected and stays
in its current position, just above the action button.

## 3. Per-flow wiring

### Membership / Padel / Farm

All three already follow the same shape: a `ConsumerWidget` inside a single
`SingleChildScrollView`, with a local `NotifierProvider` per selection (plan
/ court+date / shift) sitting next to a `..PromoProvider`. Add one more local
provider following that exact pattern, e.g. for padel:

```dart
class _PaymentMethodNotifier extends Notifier<PaymentMethod?> {
  @override
  PaymentMethod? build() => null;
  void set(PaymentMethod? m) => state = m;
}
final _selectedPaymentMethodProvider =
    NotifierProvider.autoDispose<_PaymentMethodNotifier, PaymentMethod?>(
        _PaymentMethodNotifier.new);
```

In the summary-card `Builder`:

```dart
paymentMethodSlot: PaymentMethodSelector(
  cashEnabled: place?.cashEnabled ?? false,
  selected: ref.watch(_selectedPaymentMethodProvider),
  onChanged: (m) => ref.read(_selectedPaymentMethodProvider.notifier).set(m),
),
```

`onAction` drops the `await showPaymentMethodSheet(...)` + null-check and
instead reads the already-selected value:

```dart
onAction: (isLoading || ref.watch(_selectedPaymentMethodProvider) == null)
    ? null
    : () async {
        // existing "resumed" pending-booking check unchanged
        final method = ref.read(_selectedPaymentMethodProvider)!;
        // existing createXBooking(..., paymentMethod: method) unchanged
      },
```

(`BookingSummaryCard.onAction` is already nullable — passing `null` disables
the button, giving the "disabled until picked" behavior for free.)

### Concert — seat review sheet (`_ReviewSheet`) and GA sheet (`_GASheet`)

Both are themselves already modal bottom sheets — there is no separate
"page" to embed into for these two. "Inline instead of a floating dialog"
here means: put `PaymentMethodSelector` inside each sheet's own existing
scrollable body (between the seat list / quantity picker and the Total row),
instead of popping a second sheet on top of the first when "Proceed to
Payment" is tapped.

- `_ReviewSheet` is a stateless `ConsumerWidget` → add a local
  `NotifierProvider.autoDispose<PaymentMethod?>` (same shape as above,
  scoped to this file) so it resets each time the sheet is reopened.
- `_GASheet` is already `ConsumerStatefulWidget` with local `_quantity`
  state → add a plain `PaymentMethod? _paymentMethod` field, updated via
  `setState` from `onChanged`, no new provider needed.

Both: insert the selector before the `Divider()` + Total row block, and gate
the existing `PrimaryActionButton`'s `onTap` on the selection being non-null
(in addition to today's other guards: `selectedSeats.isEmpty` /
`remaining <= 0 || price <= 0`).

## 4. Testing

- Manual pass through all five flows (padel, farm, membership, concert seat,
  concert GA), both with a merchant/event that has `cashEnabled: true` and
  one with it `false` (Cash row hidden, E-Payment-only selection still
  requires an explicit tap before "Proceed to Payment" enables).
- Verify RTL (Arabic) layout: label, row icon/text order, dashed divider,
  and radio indicator position all mirror correctly.
- Verify the "resumed pending booking" retry path (closing the Wayl webview
  and re-tapping "Proceed to Payment") still works unchanged — it bypasses
  the payment-method gate entirely, same as before.
- No backend/dashboard changes in this pass, so no server-side testing
  needed.
