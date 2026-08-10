# Cash Payment — Mobile App (Flutter) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the customer choose Cash or E-Payment right before submitting a booking (sports, farm, concert seats, general admission) or a membership purchase. Cash skips the Wayl checkout entirely and lands straight on the ticket page.

**Architecture:** A new `PaymentMethodSheet` bottom sheet (shown from each "Proceed to Payment" tap) returns the user's choice. `BookingSubmitState.success` gains a `cash` flag so every existing `ref.listen`/`maybeWhen` callback across the booking sections can tell a cash confirmation apart from a Wayl payment link. `PlaceModel` gains `cashEnabled` (from the place's merchant) so the sheet can hide Cash where the merchant has it off.

**Tech Stack:** Flutter, Riverpod (`@riverpod`/freezed generators), go_router.

**Prerequisite:** The backend plan (`2026-08-10-cash-payment-backend.md`) must be deployed first — `create-booking`/`create-membership` must already accept `payment_method` and `content.places_mobile` must already expose `cash_enabled`, or every verification step below will fail against a stale API.

## Global Constraints

- Restaurant reservations (`reservation` category / `RestaurantSection`) are **out of scope** — they're request-based with `amount_iqd = 0` at creation and never open a payment webview today (the UI always shows a "Booking Request Sent" pending screen regardless of any `payment_url`). There is nothing to attach a payment-method choice to. `restaurant_section.dart` is touched in this plan **only** to fix a compile-time arity mismatch (Task 6), not to add cash behavior.
- Every edit that touches a freezed class requires regenerating generated files: `dart run build_runner build --delete-conflicting-outputs`, run once after Tasks 1–2 are both done (they touch different freezed classes but conflicting-outputs mode handles either order).
- `flutter analyze` must be clean (no new warnings/errors) before each task's commit — this codebase has no widget test suite for the booking flow, so static analysis + manual run-through is the verification method throughout.

---

### Task 1: `PaymentMethod` enum + `PlaceModel.cashEnabled` + `EventModel.cashEnabled`

**Files:**
- Modify: `lib/features/booking/domain/models/booking_enums.dart`
- Modify: `lib/features/places/domain/models/place_model.dart`
- Modify: `lib/features/events/domain/models/event_model.dart`

**Interfaces:**
- Produces: `enum PaymentMethod { wayl, cash }` with `.name` giving `"wayl"`/`"cash"` (matches the backend's exact string values). `PlaceModel.cashEnabled` and `EventModel.cashEnabled` (`bool`, default `true`) — the concert flow (Task 8) reads the event's, every other flow reads the place's.

**Note:** both models use a **hand-written `fromJson` factory** (`PlaceModel.fromJson`/`EventModel.fromJson` at the bottom of each file), not `@JsonKey`-driven generation — `place_model.dart:45-61` and `event_model.dart:38-46` map each snake_case key manually (e.g. `logoUrl: json['logo_url']`). New fields must be added to both the constructor's parameter list *and* that manual mapping.

- [ ] **Step 1: Add the enum**

In `lib/features/booking/domain/models/booking_enums.dart`, add after line 1 (`enum BookingCategory { ... }`):

```dart
enum PaymentMethod { wayl, cash }
```

- [ ] **Step 2: Add `cashEnabled` to `PlaceModel`**

In `lib/features/places/domain/models/place_model.dart`, add to the factory's parameter list, right after `String? logoUrl,` (line 24):

```dart
    @Default(true) bool cashEnabled,
```

And in `PlaceModel.fromJson` (the manual mapping), right after `logoUrl: json['logo_url'],` (line 61):

```dart
    cashEnabled: json['cash_enabled'] as bool? ?? true,
```

- [ ] **Step 3: Add `cashEnabled` to `EventModel`**

In `lib/features/events/domain/models/event_model.dart`, add to the factory's parameter list, right after `String? logoUrl,` (line 16):

```dart
    @Default(true) bool cashEnabled,
```

And in `EventModel.fromJson`, right after `logoUrl: json['logo_url'],` (line 46):

```dart
    cashEnabled: json['cash_enabled'] as bool? ?? true,
```

(Both views this reads from — `content.places_mobile` and `content.events_mobile` — already expose `cash_enabled` once the backend plan's Task 1 migration lands; that migration adds `m.cash_enabled` to *both* views, not just `places_mobile`.)

- [ ] **Step 4: Regenerate and verify**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/features/booking/domain/models/booking_enums.dart lib/features/places/domain/models/place_model.dart lib/features/events/domain/models/event_model.dart
```

Expected: no errors; `place_model.freezed.dart`/`.g.dart` and `event_model.freezed.dart`/`.g.dart` now reference `cashEnabled`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/domain/models/booking_enums.dart lib/features/places/domain/models/place_model.dart lib/features/places/domain/models/place_model.freezed.dart lib/features/places/domain/models/place_model.g.dart lib/features/events/domain/models/event_model.dart lib/features/events/domain/models/event_model.freezed.dart lib/features/events/domain/models/event_model.g.dart
git commit -m "feat(booking): add PaymentMethod enum, PlaceModel/EventModel.cashEnabled"
```

---

### Task 2: `BookingSubmitState.success` gains a `cash` flag

**Files:**
- Modify: `lib/features/booking/presentation/providers/booking_submit_provider.dart:10-23`

**Interfaces:**
- Produces: `BookingSubmitState.success(bookingId, paymentUrl, holdUntil, waylReferenceId, cash)` — every consumer's positional destructuring (`success: (a,b,c,d) => ...`) must become 5-arity. This ripples into Tasks 6–9 (every section file) and Task 6.5 (restaurant, arity-only).

- [ ] **Step 1: Add the field**

```dart
@freezed
abstract class BookingSubmitState with _$BookingSubmitState {
  const factory BookingSubmitState.idle() = _Idle;
  const factory BookingSubmitState.loading() = _Loading;
  const factory BookingSubmitState.success({
    required String bookingId,
    required String paymentUrl,
    required String holdUntil,
    // Wayl referenceId (e.g. "booking_{uuid}_{ts}") — use this for polling,
    // NOT bookingId which is just the raw UUID.
    required String waylReferenceId,
    // True when the booking was confirmed via cash (no Wayl link exists).
    @Default(false) bool cash,
  }) = _Success;
  const factory BookingSubmitState.error(String message) = _Error;
}
```

(The same freezed class backs `membershipSubmitProvider` too, per `membership_submit_provider.dart:1-4`'s import — one field addition covers both providers.)

- [ ] **Step 2: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

This will fail to fully compile downstream call sites until Tasks 3–9 are done — that's expected; `build_runner` only regenerates the freezed/riverpod code for this file, it doesn't type-check consumers. Confirm `booking_submit_provider.freezed.dart` and `.g.dart` regenerated (check their timestamps or diff) before moving on; the broader `flutter analyze` clean check happens in Task 9's final step once every call site is updated.

- [ ] **Step 3: Commit**

```bash
git add lib/features/booking/presentation/providers/booking_submit_provider.dart lib/features/booking/presentation/providers/booking_submit_provider.freezed.dart lib/features/booking/presentation/providers/booking_submit_provider.g.dart
git commit -m "feat(booking): add cash flag to BookingSubmitState.success"
```

---

### Task 3: `booking_submit_provider.dart` — send `payment_method`, parse `cash`

**Files:**
- Modify: `lib/features/booking/presentation/providers/booking_submit_provider.dart`

**Interfaces:**
- Consumes: `PaymentMethod` (Task 1).
- Produces: `createPadelBooking`, `createFarmBooking`, `createGeneralAdmissionBooking`, `createConcertBooking` each gain a `required PaymentMethod paymentMethod` parameter. `createRestaurantBooking` is **not** touched (out of scope, per Global Constraints).

- [ ] **Step 1: `createPadelBooking`**

```dart
  Future<void> createPadelBooking({
    required String placeId,
    required String courtId,
    required String startsAt, // ISO datetime string
    required int hours,
    required PaymentMethod paymentMethod,
    String? promoCode,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'hourly',
          'place_id': placeId,
          'court_id': courtId,
          'starts_at': startsAt,
          'hours': hours,
          'payment_method': paymentMethod.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String? ?? '',
        holdUntil: data['hold_until'] as String? ?? '',
        waylReferenceId: data['reference_id'] as String? ?? '',
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }
```

(`paymentUrl`/`waylReferenceId` become `as String?` with `?? ''` fallback since the cash response omits both keys — previously `paymentUrl` was `as String` non-null because the Wayl path always returned it.)

- [ ] **Step 2: `createFarmBooking`** — same shape of change:

```dart
  Future<void> createFarmBooking({
    required String placeId,
    required String date, // 'yyyy-MM-dd'
    required FarmShiftType shiftType,
    required PaymentMethod paymentMethod,
    String? promoCode,
    int? partySize,
    bool bringingParty = false,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'shift',
          'place_id': placeId,
          'date': date,
          'shift_type': shiftType.name,
          'payment_method': paymentMethod.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
          if (partySize case int s) 'party_size': s,
          'bringing_party': bringingParty,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String? ?? '',
        holdUntil: data['hold_until'] as String? ?? '',
        waylReferenceId: data['reference_id'] as String? ?? '',
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }
```

- [ ] **Step 3: `createGeneralAdmissionBooking`**:

```dart
  Future<void> createGeneralAdmissionBooking({
    required String eventId,
    required String sectionId,
    required int quantity,
    required PaymentMethod paymentMethod,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'general_admission',
          'event_id': eventId,
          'section_id': sectionId,
          'quantity': quantity,
          'payment_method': paymentMethod.name,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: (data['booking_id'] ?? '') as String,
        paymentUrl: (data['payment_url'] ?? '') as String,
        holdUntil: (data['hold_until'] ?? '') as String? ?? '',
        waylReferenceId: (data['reference_id'] ?? '') as String,
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }
```

- [ ] **Step 4: `createConcertBooking`**:

```dart
  Future<void> createConcertBooking({
    required String eventId,
    required List<String> seatIds,
    required PaymentMethod paymentMethod,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-booking',
        body: {
          'category': 'venue_seat',
          'event_id': eventId,
          'seat_ids': seatIds,
          'payment_method': paymentMethod.name,
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      // Concerts return group_id (not booking_id) — use group_id as bookingId
      state = BookingSubmitState.success(
        bookingId: (data['group_id'] ?? data['booking_id'] ?? '') as String,
        paymentUrl: (data['payment_url'] ?? '') as String,
        holdUntil: (data['hold_until'] ?? '') as String? ?? '',
        waylReferenceId: (data['reference_id'] ?? '') as String,
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }
```

- [ ] **Step 5: Add the import** for `PaymentMethod` at the top of the file (it lives in `booking_enums.dart`, already imported at line 2 — `PaymentMethod` is a new export from that same file, so no new import line is needed).

- [ ] **Step 6: Commit**

```bash
git add lib/features/booking/presentation/providers/booking_submit_provider.dart
git commit -m "feat(booking): send payment_method to create-booking, parse cash response"
```

---

### Task 4: `membership_submit_provider.dart` — same treatment

**Files:**
- Modify: `lib/features/booking/presentation/providers/membership_submit_provider.dart`

- [ ] **Step 1: `createMembership`**

```dart
  Future<void> createMembership({
    required String placeId,
    required String planId,
    required PaymentMethod paymentMethod,
    String? promoCode,
  }) async {
    state = const BookingSubmitState.loading();
    try {
      final client = Supabase.instance.client;
      final result = await client.functions.invoke(
        'create-membership',
        body: {
          'place_id': placeId,
          'plan_id': planId,
          'payment_method': paymentMethod.name,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['membership_id'] as String,
        paymentUrl: data['payment_url'] as String? ?? '',
        holdUntil: '',
        waylReferenceId: data['reference_id'] as String? ?? '',
        cash: data['cash'] == true,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }
```

- [ ] **Step 2: Add the import**

```dart
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/booking/presentation/providers/membership_submit_provider.dart
git commit -m "feat(membership): send payment_method to create-membership, parse cash response"
```

---

### Task 5: `PaymentMethodSheet` widget + shared cash-success navigation

**Files:**
- Create: `lib/features/booking/presentation/widgets/payment_method_sheet.dart`

**Interfaces:**
- Produces: `Future<PaymentMethod?> showPaymentMethodSheet(BuildContext, {required bool cashEnabled})` — returns the chosen method, or `null` if dismissed. `void goToCashBookingSuccess({required BuildContext context, required WidgetRef ref, required String routeId, required VoidCallback resetSubmitState})` — the shared "cash succeeded, skip the webview" tail every section needs (reset submit state, bump the bookings-refresh signal, invalidate purchase history, snackbar, `context.go('/bookings/$routeId')`).

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/presentation/providers/booking_submit_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart'
    show bookingsRefreshProvider;
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
import 'package:go_router/go_router.dart';

/// Shows the "Payment Method" bottom sheet (Cash / E-Payment) and returns the
/// user's choice, or null if dismissed without choosing. The Cash row is
/// omitted entirely when [cashEnabled] is false — the merchant has cash off.
Future<PaymentMethod?> showPaymentMethodSheet(
  BuildContext context, {
  required bool cashEnabled,
}) {
  return showModalBottomSheet<PaymentMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PaymentMethodSheet(cashEnabled: cashEnabled),
  );
}

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({required this.cashEnabled});
  final bool cashEnabled;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'طريقة الدفع' : 'Payment Method',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (cashEnabled) ...[
              _PaymentMethodRow(
                icon: Icons.payments_rounded,
                iconBg: const Color(0xFF17A673),
                title: isAr ? 'نقداً' : 'Cash',
                subtitle: isAr ? 'ادفع عند الوصول' : 'Pay at the venue',
                onTap: () => Navigator.of(context).pop(PaymentMethod.cash),
              ),
              const Divider(height: 24),
            ],
            _PaymentMethodRow(
              icon: Icons.credit_card_rounded,
              iconBg: cs.primary,
              title: isAr ? 'الدفع الإلكتروني' : 'E-Payment',
              subtitle: isAr ? 'ادفع الآن عبر الإنترنت' : 'Pay online now',
              onTap: () => Navigator.of(context).pop(PaymentMethod.wayl),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.outline),
          ],
        ),
      ),
    );
  }
}

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

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/booking/presentation/widgets/payment_method_sheet.dart
```

Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/features/booking/presentation/widgets/payment_method_sheet.dart
git commit -m "feat(booking): add PaymentMethodSheet and cash-success navigation helper"
```

---

### Task 6: Wire into `padel_section.dart`

**Files:**
- Modify: `lib/features/booking/presentation/sections/padel_section.dart`

- [ ] **Step 1: Add the import**

```dart
import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_sheet.dart';
```

- [ ] **Step 2: Handle `cash` in the `ref.listen` block** (`padel_section.dart:296-313`)

```dart
    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil, waylReferenceId, cash) {
          if (paymentUrl.isNotEmpty) {
            openPaymentWebView(bookingId, paymentUrl, waylReferenceId);
          } else if (cash) {
            goToCashBookingSuccess(
              context: context,
              ref: ref,
              routeId: bookingId,
              resetSubmitState: ref.read(bookingSubmitProvider.notifier).reset,
            );
          }
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        orElse: () {},
      );
    });
```

- [ ] **Step 3: Show the sheet before submitting, in `onAction`** (`padel_section.dart:556-581`)

```dart
                          onAction: () async {
                            // If a pending booking already exists, reuse its payment URL
                            // instead of creating a new booking (avoids DB constraint error).
                            final current = ref.read(bookingSubmitProvider);
                            final resumed = current.maybeWhen(
                              success: (bookingId, paymentUrl, holdUntil,
                                  waylReferenceId, cash) {
                                if (paymentUrl.isNotEmpty) {
                                  openPaymentWebView(
                                      bookingId, paymentUrl, waylReferenceId);
                                } else if (cash) {
                                  goToCashBookingSuccess(
                                    context: context,
                                    ref: ref,
                                    routeId: bookingId,
                                    resetSubmitState: ref
                                        .read(bookingSubmitProvider.notifier)
                                        .reset,
                                  );
                                }
                                return true;
                              },
                              orElse: () => false,
                            );
                            if (resumed) return;
                            final method = await showPaymentMethodSheet(
                              context,
                              cashEnabled: place?.cashEnabled ?? true,
                            );
                            if (method == null) return;
                            final sorted = selectedSlots.toList()..sort();
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
```

`place` is already in scope (`padel_section.dart:219-220`, `final place = placeAsync.value;`), so `place?.cashEnabled` needs no new provider watch.

- [ ] **Step 4: Manual verification**

Run the app (`flutter run`), open a padel place with `cash_enabled = true` on its merchant, select a slot, tap "Proceed to Payment". Expected: the sheet appears with both Cash and E-Payment rows. Tap Cash → lands directly on the ticket page for a `confirmed` booking with no Wayl code shown. Tap E-Payment → existing Wayl webview flow, unchanged. Then repeat against a merchant with `cash_enabled = false` (set via `update business.merchants set cash_enabled=false where id=...` and re-run) — expect only the E-Payment row.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/sections/padel_section.dart
git commit -m "feat(booking): add Cash/E-Payment choice to padel booking flow"
```

---

### Task 7: Wire into `farm_section.dart`

**Files:**
- Modify: `lib/features/booking/presentation/sections/farm_section.dart`

Same shape of change as Task 6, applied to farm's two call sites.

- [ ] **Step 1: Add the import** (same line as Task 6, Step 1).

- [ ] **Step 2: Handle `cash` in the `ref.listen` block** (`farm_section.dart:306-323`)

```dart
    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil, waylReferenceId, cash) {
          if (paymentUrl.isNotEmpty) {
            openPaymentWebView(bookingId, paymentUrl, waylReferenceId);
          } else if (cash) {
            goToCashBookingSuccess(
              context: context,
              ref: ref,
              routeId: bookingId,
              resetSubmitState: ref.read(bookingSubmitProvider.notifier).reset,
            );
          }
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        orElse: () {},
      );
    });
```

- [ ] **Step 3: Show the sheet before submitting** (`farm_section.dart:601-654`, the `onAction:` callback). `place` is already in scope here (`farm_section.dart:242-243`, `final place = placeAsync.value;` — same pattern as padel, no new provider watch needed).

Change the enclosing `onAction: () {` to `onAction: () async {`, and inside it:

```dart
                            // If a pending booking already exists, reuse its payment URL
                            // instead of creating a new booking (avoids DB constraint error).
                            final current = ref.read(bookingSubmitProvider);
                            final resumed = current.maybeWhen(
                              success:
                                  (
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
                                            .read(bookingSubmitProvider.notifier)
                                            .reset,
                                      );
                                    }
                                    return true;
                                  },
                              orElse: () => false,
                            );
                            if (resumed) return;
                            final method = await showPaymentMethodSheet(
                              context,
                              cashEnabled: place?.cashEnabled ?? true,
                            );
                            if (method == null) return;
                            final shift = selectedShift;
                            ref
                                .read(bookingSubmitProvider.notifier)
                                .createFarmBooking(
                                  placeId: placeId,
                                  date: bookingFormatDate(selectedDate),
                                  shiftType: shift.shiftType,
                                  promoCode: promo?.code,
                                  partySize:
                                      (!partyOn &&
                                          shift.partyExtraPersonFeeIqd > 0)
                                      ? partyCount
                                      : null,
                                  bringingParty: partyOn,
                                  paymentMethod: method,
                                );
```

- [ ] **Step 4: Manual verification** — same as Task 6 Step 4, using a farm/shift place.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/sections/farm_section.dart
git commit -m "feat(booking): add Cash/E-Payment choice to farm booking flow"
```

---

### Task 8: Wire into `concert_section.dart` (seat picking + general admission)

**Files:**
- Modify: `lib/features/booking/presentation/sections/concert_section.dart`

This file has two independent submission paths sharing one `bookingSubmitProvider` (reserved seats via `createConcertBooking`, and general admission via `createGeneralAdmissionBooking`), plus two arity-only `success: (_, _, _, _) => true` busy-checks that need a 5th `_` but no behavior change.

**Interfaces:**
- Consumes: `EventModel.cashEnabled` (Task 1) via the existing `eventDetailsProvider(eventId)` (`lib/features/events/presentation/providers/event_details_provider.dart:13-17`, wraps `EventsRepository.fetchEvent` which queries `content.events_mobile` — already used elsewhere in the app for event detail screens, just not currently watched inside `concert_section.dart`).

- [ ] **Step 1: Add the imports**

```dart
import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_sheet.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
```

- [ ] **Step 2: Handle `cash` in `_openConcertPaymentWebView`'s caller — the top-level `ref.listen`** (`concert_section.dart:222-247`)

```dart
    ref.listen<BookingSubmitState>(bookingSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (groupId, paymentUrl, holdUntil, waylReferenceId, cash) {
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
          } else if (cash) {
            _dismissCheckoutSheet(context);
            ref.read(bookingSubmitProvider.notifier).reset();
            ref.read(_concertSelectionProvider.notifier).reset();
            ref.read(bookingsRefreshProvider.notifier).bump();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Booking confirmed! Pay with cash at the venue.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              context.goNamed('bookingsHistory');
            }
          }
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        orElse: () {},
      );
    });
```

(Cash lands on `bookingsHistory`, not a specific ticket — the group's `success.bookingId` field carries `groupId`, not an individual booking id fit for `/bookings/$id`; the existing Wayl success handler resolves a real `firstBookingId` via `confirmConcertGroupPayment`'s return, which cash has no equivalent call for. Mirrors the existing `else { context.goNamed('bookingsHistory'); }` fallback already used a few lines above for the no-firstBookingId case.)

- [ ] **Step 3: Fix arity on the two busy-checks** (`concert_section.dart:593` and `:736`)

Both:
```dart
            success: (_, _, _, _) => true,
```
become:
```dart
            success: (_, _, _, _, _) => true,
```

- [ ] **Step 4: Show the sheet before submitting — seat-picking checkout** (`concert_section.dart:877-914`)

```dart
              onTap: selectedSeats.isEmpty
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
                      final method = await showPaymentMethodSheet(
                        context,
                        cashEnabled: ref
                                .watch(eventDetailsProvider(eventId))
                                .value
                                ?.cashEnabled ??
                            true,
                      );
                      if (method == null) return;
                      // Keep the sheet visible while create-booking runs.
                      // The parent listener pops it once the Wayl URL is
                      // ready (see `_dismissCheckoutSheet`).
                      ref
                          .read(bookingSubmitProvider.notifier)
                          .createConcertBooking(
                            eventId: eventId,
                            seatIds: selectedSeats.map((s) => s.seatId).toList(),
                            paymentMethod: method,
                          );
                    },
```

`ref.watch(eventDetailsProvider(eventId))` must be called from this widget's `build` method (not inside the `onTap` closure at evaluation time — closures can still *read* a value captured from an outer `ref.watch` at build time, but calling `ref.watch` itself must happen during build). If this `onTap` callback's enclosing widget doesn't already watch `eventDetailsProvider(eventId)` in its `build`, add `final eventCashEnabled = ref.watch(eventDetailsProvider(eventId)).value?.cashEnabled ?? true;` near its other `ref.watch` calls, and reference that local variable inside `onTap` instead of calling `ref.watch` directly inside the closure.

- [ ] **Step 5: Show the sheet before submitting — general admission checkout** (`concert_section.dart:1112-1147`), same shape:

```dart
              onTap: remaining <= 0 || price <= 0
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
                      final method = await showPaymentMethodSheet(
                        context,
                        cashEnabled: ref
                                .watch(eventDetailsProvider(widget.eventId))
                                .value
                                ?.cashEnabled ??
                            true,
                      );
                      if (method == null) return;
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
```

Same watch-in-`build`-not-in-closure caveat as Step 4 applies here (using `widget.eventId`).

- [ ] **Step 6: Manual verification** — book a concert seat with Cash, confirm it lands on `bookingsHistory` with a new `confirmed` entry; repeat for general admission. Then set `cash_enabled = false` on the event's merchant and confirm the Cash row disappears from the sheet for both flows.

- [ ] **Step 7: Commit**

```bash
git add lib/features/booking/presentation/sections/concert_section.dart
git commit -m "feat(booking): add Cash/E-Payment choice to concert seat and GA flows"
```

---

### Task 9: Wire into `membership_section.dart`

**Files:**
- Modify: `lib/features/booking/presentation/sections/membership_section.dart`

**Why this one's different:** it already has an `else` branch on empty `paymentUrl` that treats it as an **error** ("Unable to get payment link") — this must become a `cash` check instead of always erroring.

- [ ] **Step 1: Add the import** (same as Task 6, Step 1).

- [ ] **Step 2: Fix the `ref.listen` block** (`membership_section.dart:120-135+`, the block currently reading):

```dart
    ref.listen<BookingSubmitState>(membershipSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil, waylReferenceId) {
          if (paymentUrl.isNotEmpty) {
            _openMembershipPaymentWebView(
                context, ref, bookingId, paymentUrl, waylReferenceId);
          } else {
            ref.read(membershipSubmitProvider.notifier).reset();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Unable to get payment link. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
```

becomes:

```dart
    ref.listen<BookingSubmitState>(membershipSubmitProvider, (prev, next) {
      next.maybeWhen(
        success: (bookingId, paymentUrl, holdUntil, waylReferenceId, cash) {
          if (paymentUrl.isNotEmpty) {
            _openMembershipPaymentWebView(
                context, ref, bookingId, paymentUrl, waylReferenceId);
          } else if (cash) {
            goToCashBookingSuccess(
              context: context,
              ref: ref,
              routeId: 'm_$bookingId',
              resetSubmitState: ref.read(membershipSubmitProvider.notifier).reset,
            );
          } else {
            ref.read(membershipSubmitProvider.notifier).reset();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Unable to get payment link. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
```

(Leave the rest of that `maybeWhen` call — `error:`/`orElse:` — untouched; only this `success:` closure's signature and body change.)

- [ ] **Step 3: Show the sheet before submitting** (`membership_section.dart:376-401`)

```dart
                          onAction: () async {
                            // If a pending membership already exists, reuse
                            // its payment URL instead of creating a new one
                            // (avoids the DB constraint on the still-open
                            // pending row).
                            final current = ref.read(membershipSubmitProvider);
                            final resumed = current.maybeWhen(
                              success: (bookingId, paymentUrl, holdUntil,
                                  waylReferenceId, cash) {
                                if (paymentUrl.isNotEmpty) {
                                  _openMembershipPaymentWebView(context, ref,
                                      bookingId, paymentUrl, waylReferenceId);
                                } else if (cash) {
                                  goToCashBookingSuccess(
                                    context: context,
                                    ref: ref,
                                    routeId: 'm_$bookingId',
                                    resetSubmitState: ref
                                        .read(membershipSubmitProvider.notifier)
                                        .reset,
                                  );
                                }
                                return true;
                              },
                              orElse: () => false,
                            );
                            if (resumed) return;
                            final method = await showPaymentMethodSheet(
                              context,
                              cashEnabled: place?.cashEnabled ?? true,
                            );
                            if (method == null) return;
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
```

Confirm `place` (a `PlaceModel?`) is already in scope in this build method the same way it is in `padel_section.dart` (via `placeDetailsProvider(placeId)`) — this file's `_resolveEffective`/`PromoCodeField` usage already references `place?.merchantId`/`place?.categoryId` nearby, so it should already be watched; if not, add the watch the same way as padel's.

- [ ] **Step 4: Manual verification** — buy a membership with Cash, confirm it lands on `/bookings/m_<id>` with an `active` membership and no Wayl code.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/sections/membership_section.dart
git commit -m "feat(membership): add Cash/E-Payment choice to membership purchase flow"
```

---

### Task 10: `restaurant_section.dart` — arity-only compile fix

**Files:**
- Modify: `lib/features/booking/presentation/sections/restaurant_section.dart`

**Why this task exists:** `BookingSubmitState` (Task 2) is shared by every `bookingSubmitProvider` consumer, including this file — even though restaurant reservations get no cash/e-payment choice (Global Constraints), its two `success: (...)` destructures must grow a 5th positional parameter or the file fails to compile. No behavior changes here.

- [ ] **Step 1:** `restaurant_section.dart:83`, change:

```dart
        success: (_, _, _, _) {
```

to:

```dart
        success: (_, _, _, _, _) {
```

- [ ] **Step 2:** `restaurant_section.dart:100`, change:

```dart
      success: (bookingId, paymentUrl, holdUntil, waylReferenceId) =>
          const _RestaurantPendingView(),
```

to:

```dart
      success: (bookingId, paymentUrl, holdUntil, waylReferenceId, cash) =>
          const _RestaurantPendingView(),
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/features/booking/presentation/sections/restaurant_section.dart
git add lib/features/booking/presentation/sections/restaurant_section.dart
git commit -m "fix(booking): update restaurant section for BookingSubmitState.cash arity"
```

---

### Task 11: Full-app verification pass

- [ ] **Step 1: Static analysis across the whole booking feature**

```bash
flutter analyze lib/features/booking lib/features/bookings_history lib/features/places
```

Expected: zero errors. (Warnings pre-existing before this plan are out of scope to fix.)

- [ ] **Step 2: Manual run-through**

Launch the app against the deployed backend (Task prerequisite). For each of: padel (hourly), farm (shift), concert seat, general admission, membership — run both a Cash purchase and an E-Payment purchase end to end, confirming: the sheet shows/hides Cash per the test merchant's `cash_enabled`; Cash lands on the correct ticket/history screen with a `confirmed`/`active` status and no Wayl code; E-Payment is completely unaffected (still opens the Wayl webview and behaves as before this plan).

- [ ] **Step 3: No commit** — this task is verification only; if it uncovers a defect, fix it within the task that owns the broken file and re-run this task.
