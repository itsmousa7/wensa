# Discounts & Promo Codes — Mobile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface admin/merchant automatic discounts (`business.discounts`) on listings and place details, and let users apply promo codes in padel/farm/membership checkout — with subtotal/discount/final breakdown, uppercased codes, and existing edge-function redemption.

**Architecture:** Add a thin domain layer under `lib/features/discounts/` (model, repo, providers, helper), a shared `PromoCodeField` widget, and discount-aware props on `BookingSummaryCard`. Wire padel, farm, and membership sections; restaurant has no price and concerts are excluded. Existing edge functions already accept `promo_code` and call `redeem_promo_code` server-side.

**Tech Stack:** Flutter, Riverpod (manual `Provider` family for non-async, `@riverpod` codegen for stateful notifiers), Supabase (PostgREST `business` schema + RPC), `flutter_test` for unit tests.

---

## Spec

See `docs/superpowers/specs/2026-05-19-discounts-promo-codes-mobile-design.md`.

## Conventions for every task
- Use `flutter test path/to/test.dart` to run a single test file. Use `flutter analyze` to type-check.
- Match the existing code-gen pattern: providers without state notifier use plain `Provider`/`FutureProvider`; submit-style stateful ones use `@riverpod` (don't run `build_runner` unless you add a new `@riverpod`).
- Import path prefix for this app is `package:future_riverpod/`.
- Commit after each task using the conventional-commit style already in the repo (e.g. `feat: …`, `test: …`, `refactor: …`).

---

## Task 1: Discount math helper

**Files:**
- Create: `lib/features/discounts/domain/discount_math.dart`
- Test: `test/features/discounts/domain/discount_math_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/discounts/domain/discount_math_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/discounts/domain/discount_math.dart';

void main() {
  group('computeDiscount', () {
    test('returns 10% of 40,000 with no cap', () {
      final r = computeDiscount(subtotal: 40000, percent: 10);
      expect(r.discountAmount, 4000);
      expect(r.finalAmount, 36000);
    });

    test('clamps to max cap', () {
      final r = computeDiscount(subtotal: 50000, percent: 30, maxCap: 5000);
      expect(r.discountAmount, 5000);
      expect(r.finalAmount, 45000);
    });

    test('does not clamp when below cap', () {
      final r = computeDiscount(subtotal: 10000, percent: 30, maxCap: 5000);
      expect(r.discountAmount, 3000);
      expect(r.finalAmount, 7000);
    });

    test('rounds to nearest integer IQD', () {
      final r = computeDiscount(subtotal: 9999, percent: 10);
      expect(r.discountAmount, 1000); // round(999.9)
      expect(r.finalAmount, 8999);
    });

    test('zero subtotal yields zero discount', () {
      final r = computeDiscount(subtotal: 0, percent: 25);
      expect(r.discountAmount, 0);
      expect(r.finalAmount, 0);
    });

    test('null cap is treated as no cap', () {
      final r = computeDiscount(subtotal: 100000, percent: 50, maxCap: null);
      expect(r.discountAmount, 50000);
      expect(r.finalAmount, 50000);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/discounts/domain/discount_math_test.dart`
Expected: FAIL — file not found / `computeDiscount` undefined.

- [ ] **Step 3: Implement**

Create `lib/features/discounts/domain/discount_math.dart`:

```dart
/// Pure helper for client-side discount math (display only — the server is
/// authoritative at redemption time).
class DiscountResult {
  const DiscountResult({required this.discountAmount, required this.finalAmount});
  final int discountAmount;
  final int finalAmount;
}

/// Applies [percent] to [subtotal] and clamps the resulting discount to
/// [maxCap] when provided. Amounts are integer IQD (matches the rest of the
/// app's price formatting).
DiscountResult computeDiscount({
  required int subtotal,
  required double percent,
  num? maxCap,
}) {
  if (subtotal <= 0 || percent <= 0) {
    return DiscountResult(discountAmount: 0, finalAmount: subtotal);
  }
  var discount = (subtotal * percent / 100).round();
  if (maxCap != null && discount > maxCap) {
    discount = maxCap.round();
  }
  if (discount > subtotal) discount = subtotal;
  return DiscountResult(discountAmount: discount, finalAmount: subtotal - discount);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/discounts/domain/discount_math_test.dart`
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/discounts/domain/discount_math.dart test/features/discounts/domain/discount_math_test.dart
git commit -m "feat(discounts): add discount math helper with cap clamping"
```

---

## Task 2: AutoDiscount model

**Files:**
- Create: `lib/features/discounts/domain/models/auto_discount.dart`
- Test: `test/features/discounts/domain/models/auto_discount_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/discounts/domain/models/auto_discount_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';

void main() {
  final base = {
    'id': 'd1',
    'name': '10% off',
    'percent': 10,
    'applies_to': ['bookings'],
    'scope_type': 'app',
    'target_category_ids': <String>[],
    'target_merchant_ids': <String>[],
    'target_place_ids': <String>[],
    'is_active': true,
  };

  group('AutoDiscount.fromJson', () {
    test('parses required + optional fields', () {
      final d = AutoDiscount.fromJson({
        ...base,
        'max_discount_amount': '5000',
        'starts_at': '2026-05-01T00:00:00Z',
        'ends_at': '2026-06-01T00:00:00Z',
      });
      expect(d.id, 'd1');
      expect(d.percent, 10);
      expect(d.maxDiscountAmount, 5000);
      expect(d.appliesTo, ['bookings']);
      expect(d.scopeType, 'app');
      expect(d.startsAt!.year, 2026);
    });

    test('handles missing optionals', () {
      final d = AutoDiscount.fromJson(base);
      expect(d.maxDiscountAmount, isNull);
      expect(d.startsAt, isNull);
      expect(d.endsAt, isNull);
    });
  });

  group('appliesToOrder', () {
    final now = DateTime(2026, 5, 19);

    test('app-scope matches any place when order type is allowed', () {
      final d = AutoDiscount.fromJson(base);
      expect(
        d.appliesToOrder(
          orderType: 'bookings',
          placeId: 'p1', merchantId: 'm1', categoryId: 'c1',
          now: now,
        ),
        isTrue,
      );
    });

    test('rejects order type not in applies_to', () {
      final d = AutoDiscount.fromJson(base);
      expect(
        d.appliesToOrder(
          orderType: 'memberships',
          placeId: 'p1', merchantId: 'm1', categoryId: 'c1',
          now: now,
        ),
        isFalse,
      );
    });

    test('targeted with matching place_id', () {
      final d = AutoDiscount.fromJson({
        ...base,
        'scope_type': 'targeted',
        'target_place_ids': ['p1'],
      });
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: null, categoryId: null, now: now),
        isTrue,
      );
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p2', merchantId: null, categoryId: null, now: now),
        isFalse,
      );
    });

    test('targeted matches any of the three arrays', () {
      final d = AutoDiscount.fromJson({
        ...base,
        'scope_type': 'targeted',
        'target_merchant_ids': ['m9'],
      });
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: 'm9', categoryId: null, now: now),
        isTrue,
      );
    });

    test('rejects when inactive', () {
      final d = AutoDiscount.fromJson({...base, 'is_active': false});
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: null, categoryId: null, now: now),
        isFalse,
      );
    });

    test('rejects when before starts_at', () {
      final d = AutoDiscount.fromJson({...base, 'starts_at': '2026-06-01T00:00:00Z'});
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: null, categoryId: null, now: now),
        isFalse,
      );
    });

    test('rejects when after ends_at', () {
      final d = AutoDiscount.fromJson({...base, 'ends_at': '2026-05-01T00:00:00Z'});
      expect(
        d.appliesToOrder(orderType: 'bookings', placeId: 'p1', merchantId: null, categoryId: null, now: now),
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/discounts/domain/models/auto_discount_test.dart`
Expected: FAIL — `AutoDiscount` undefined.

- [ ] **Step 3: Implement**

Create `lib/features/discounts/domain/models/auto_discount.dart`:

```dart
/// Maps to `business.discounts` rows (automatic % discounts).
///
/// Use [appliesToOrder] to check whether this discount matches a given
/// purchase. The biggest applicable percent wins — never stack.
class AutoDiscount {
  const AutoDiscount({
    required this.id,
    required this.name,
    required this.percent,
    required this.appliesTo,
    required this.scopeType,
    required this.targetCategoryIds,
    required this.targetMerchantIds,
    required this.targetPlaceIds,
    required this.isActive,
    this.description,
    this.maxDiscountAmount,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String name;
  final String? description;
  final double percent;
  final num? maxDiscountAmount;
  final List<String> appliesTo;
  final String scopeType; // 'app' | 'targeted'
  final List<String> targetCategoryIds;
  final List<String> targetMerchantIds;
  final List<String> targetPlaceIds;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  bool appliesToOrder({
    required String orderType,
    required String? placeId,
    required String? merchantId,
    required String? categoryId,
    DateTime? now,
  }) {
    if (!isActive) return false;
    final t = now ?? DateTime.now();
    if (startsAt != null && t.isBefore(startsAt!)) return false;
    if (endsAt != null && t.isAfter(endsAt!)) return false;
    if (!appliesTo.contains(orderType)) return false;
    if (scopeType == 'app') return true;
    // targeted: match ANY of the three id arrays
    if (categoryId != null && targetCategoryIds.contains(categoryId)) return true;
    if (merchantId != null && targetMerchantIds.contains(merchantId)) return true;
    if (placeId != null && targetPlaceIds.contains(placeId)) return true;
    return false;
  }

  factory AutoDiscount.fromJson(Map<String, dynamic> json) => AutoDiscount(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        percent: (json['percent'] as num).toDouble(),
        maxDiscountAmount: json['max_discount_amount'] == null
            ? null
            : num.tryParse(json['max_discount_amount'].toString()),
        appliesTo: ((json['applies_to'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        scopeType: (json['scope_type'] as String?) ?? 'app',
        targetCategoryIds: ((json['target_category_ids'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        targetMerchantIds: ((json['target_merchant_ids'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        targetPlaceIds: ((json['target_place_ids'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        startsAt: json['starts_at'] != null
            ? DateTime.parse(json['starts_at'] as String)
            : null,
        endsAt: json['ends_at'] != null
            ? DateTime.parse(json['ends_at'] as String)
            : null,
        isActive: (json['is_active'] as bool?) ?? true,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/discounts/domain/models/auto_discount_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/discounts/domain/models/auto_discount.dart test/features/discounts/domain/models/auto_discount_test.dart
git commit -m "feat(discounts): add AutoDiscount model with applies-to check"
```

---

## Task 3: AutoDiscountsRepository + provider

**Files:**
- Create: `lib/features/discounts/data/auto_discounts_repository.dart`
- Modify: `lib/features/discounts/presentation/providers/merchant_discounts_provider.dart` (add new providers below the existing ones)

- [ ] **Step 1: Create the repository**

Create `lib/features/discounts/data/auto_discounts_repository.dart`:

```dart
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AutoDiscountsRepository {
  const AutoDiscountsRepository(this._client);
  final SupabaseClient _client;

  Future<List<AutoDiscount>> fetchActive() async {
    final rows = await _client
        .schema('business')
        .from('discounts')
        .select()
        .eq('is_active', true);
    return (rows as List)
        .map((r) => AutoDiscount.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 2: Add providers**

Append to `lib/features/discounts/presentation/providers/merchant_discounts_provider.dart` (after the existing `bestDiscountPercentProvider`):

```dart
// ── Auto discounts (business.discounts) ─────────────────────────────────────

final autoDiscountsRepositoryProvider = Provider<AutoDiscountsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AutoDiscountsRepository(client);
});

final autoDiscountsProvider =
    FutureProvider<List<AutoDiscount>>((ref) async {
  final repo = ref.watch(autoDiscountsRepositoryProvider);
  return repo.fetchActive();
});

class AutoDiscountKey {
  const AutoDiscountKey({
    required this.orderType,
    this.placeId,
    this.merchantId,
    this.categoryId,
  });
  final String orderType;
  final String? placeId;
  final String? merchantId;
  final String? categoryId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoDiscountKey &&
          other.orderType == orderType &&
          other.placeId == placeId &&
          other.merchantId == merchantId &&
          other.categoryId == categoryId;

  @override
  int get hashCode =>
      Object.hash(orderType, placeId, merchantId, categoryId);
}

/// Returns the single best applicable [AutoDiscount] for the given purchase
/// (largest percent). Returns null when none match.
final bestAutoDiscountProvider =
    Provider.family<AutoDiscount?, AutoDiscountKey>((ref, key) {
  final discounts = ref.watch(autoDiscountsProvider).value;
  if (discounts == null || discounts.isEmpty) return null;
  AutoDiscount? best;
  for (final d in discounts) {
    if (!d.appliesToOrder(
      orderType: key.orderType,
      placeId: key.placeId,
      merchantId: key.merchantId,
      categoryId: key.categoryId,
    )) continue;
    if (best == null || d.percent > best.percent) best = d;
  }
  return best;
});
```

Also add the imports at the top of the file:

```dart
import 'package:future_riverpod/features/discounts/data/auto_discounts_repository.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
```

- [ ] **Step 3: Update `bestDiscountPercentProvider` to merge both systems**

In the same file, replace the body of `bestDiscountPercentProvider` so it picks the max percent across merchant_discounts AND business.discounts. Replace:

```dart
final bestDiscountPercentProvider =
    Provider.family<int?, PlaceDiscountKey>((ref, key) {
  final discounts = ref.watch(merchantDiscountsProvider).value;
  if (discounts == null || discounts.isEmpty) return null;

  double best = 0;
  for (final d in discounts) {
    if (!d.appliesToPlace(placeId: key.placeId, merchantId: key.merchantId)) {
      continue;
    }
    if (d.percent > best) best = d.percent;
  }
  return best > 0 ? best.round() : null;
});
```

with:

```dart
final bestDiscountPercentProvider =
    Provider.family<int?, PlaceDiscountKey>((ref, key) {
  double best = 0;

  final merchant = ref.watch(merchantDiscountsProvider).value;
  if (merchant != null) {
    for (final d in merchant) {
      if (!d.appliesToPlace(placeId: key.placeId, merchantId: key.merchantId)) {
        continue;
      }
      if (d.percent > best) best = d.percent;
    }
  }

  final auto = ref.watch(bestAutoDiscountProvider(
    AutoDiscountKey(
      orderType: 'bookings',
      placeId: key.placeId,
      merchantId: key.merchantId,
      // category not known at the listing level — null is fine for app-scope
      // and merchant-scope rules.
    ),
  ));
  if (auto != null && auto.percent > best) best = auto.percent;

  return best > 0 ? best.round() : null;
});
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/features/discounts/`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/discounts/
git commit -m "feat(discounts): add AutoDiscount repository + providers; merge into card badge"
```

---

## Task 4: User purchase history provider (eligibility flags)

**Files:**
- Create: `lib/features/discounts/presentation/providers/user_purchase_history_provider.dart`

- [ ] **Step 1: Implement**

Create `lib/features/discounts/presentation/providers/user_purchase_history_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/presentation/providers/supabase_provider.dart';

/// Cached per-session signal of whether the current user has any prior
/// completed orders. Used to populate `p_is_first_purchase` and
/// `p_is_new_customer` when previewing promo codes.
///
/// Invalidate this provider (`ref.invalidate(userPurchaseHistoryProvider)`)
/// after a successful order so the next preview reflects the new state.
class PurchaseHistory {
  const PurchaseHistory({required this.bookingsCount, required this.membershipsCount});
  final int bookingsCount;
  final int membershipsCount;

  bool get hasAnyOrder => bookingsCount > 0 || membershipsCount > 0;

  bool hasOrderOfType(String orderType) {
    switch (orderType) {
      case 'bookings':
        return bookingsCount > 0;
      case 'memberships':
        return membershipsCount > 0;
      default:
        return false;
    }
  }
}

final userPurchaseHistoryProvider =
    FutureProvider<PurchaseHistory>((ref) async {
  final client = ref.watch(supabaseProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    return const PurchaseHistory(bookingsCount: 0, membershipsCount: 0);
  }
  final bookings = await client
      .from('bookings')
      .select('id')
      .eq('user_id', userId)
      .limit(1);
  final memberships = await client
      .from('memberships')
      .select('id')
      .eq('user_id', userId)
      .limit(1);
  return PurchaseHistory(
    bookingsCount: (bookings as List).length,
    membershipsCount: (memberships as List).length,
  );
});
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/features/discounts/presentation/providers/user_purchase_history_provider.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/discounts/presentation/providers/user_purchase_history_provider.dart
git commit -m "feat(discounts): add session-cached user purchase history for promo eligibility"
```

---

## Task 5: Extend BookingSummaryCard with discount breakdown

**Files:**
- Modify: `lib/features/booking/presentation/widgets/booking_summary_card.dart`

- [ ] **Step 1: Add new optional props**

In `lib/features/booking/presentation/widgets/booking_summary_card.dart`, update the constructor signature. Replace:

```dart
  const BookingSummaryCard({
    super.key,
    required this.title,
    this.badgeText,
    required this.rows,
    this.totalLabel,
    this.totalValue,
    required this.actionLabel,
    required this.onAction,
    required this.isLoading,
  });
```

with:

```dart
  const BookingSummaryCard({
    super.key,
    required this.title,
    this.badgeText,
    required this.rows,
    this.totalLabel,
    this.totalValue,
    this.subtotalLabel,
    this.subtotalValue,
    this.discountLabel,
    this.discountValue,
    this.extraSlot,
    required this.actionLabel,
    required this.onAction,
    required this.isLoading,
  });

  /// Optional pre-discount subtotal text (e.g. "IQD 40,000"). When set
  /// alongside [discountValue], the total row renders with a struck-through
  /// subtotal + a discount row above it.
  final String? subtotalLabel;
  final String? subtotalValue;

  /// Optional discount line (e.g. label="10% OFF", value="−IQD 4,000").
  final String? discountLabel;
  final String? discountValue;

  /// Optional slot rendered just above the action button (e.g. the
  /// promo-code field).
  final Widget? extraSlot;
```

- [ ] **Step 2: Render the discount block**

In the same file, replace the existing `if (totalValue != null) ...` block (the gradient total pill) with:

```dart
                // Subtotal + discount + total stack
                if (totalValue != null) ...[
                  const SizedBox(height: 16),
                  if (discountValue != null && subtotalValue != null) ...[
                    _SummaryLineRow(
                      label: subtotalLabel ?? 'Subtotal',
                      value: subtotalValue!,
                      strikethrough: true,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 6),
                    _SummaryLineRow(
                      label: discountLabel ?? 'Discount',
                      value: discountValue!,
                      color: const Color(0xFFE53935),
                      bold: true,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.08),
                          colorScheme.secondary.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_rounded,
                            size: 20, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          totalLabel ?? 'Total Amount',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          totalValue!,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (extraSlot != null) ...[
                  const SizedBox(height: 14),
                  extraSlot!,
                ],
```

- [ ] **Step 3: Add the line-row helper at the bottom of the file**

Append to the end of `booking_summary_card.dart`:

```dart
class _SummaryLineRow extends StatelessWidget {
  const _SummaryLineRow({
    required this.label,
    required this.value,
    this.strikethrough = false,
    this.bold = false,
    this.color,
  });
  final String label;
  final String value;
  final bool strikethrough;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final style = base.copyWith(
      color: color,
      decoration: strikethrough ? TextDecoration.lineThrough : null,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/features/booking/presentation/widgets/booking_summary_card.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/widgets/booking_summary_card.dart
git commit -m "feat(booking): add discount breakdown + extra-slot props to BookingSummaryCard"
```

---

## Task 6: PromoCodeField widget

**Files:**
- Create: `lib/features/discounts/presentation/widgets/promo_code_field.dart`

- [ ] **Step 1: Implement the widget**

Create `lib/features/discounts/presentation/widgets/promo_code_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/presentation/providers/supabase_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';

class PromoApplied {
  const PromoApplied({
    required this.code,
    required this.percent,
    required this.discountAmount,
    required this.finalAmount,
    required this.promoCodeId,
  });
  final String code;
  final double percent;
  final int discountAmount;
  final int finalAmount;
  final String promoCodeId;
}

/// Compact text field + Apply button that previews a promo code against
/// `business.preview_promo_code`. Reports applied state via [onChange].
///
/// The parent owns the [applied] state and passes it back in to keep the
/// widget driven by external state (so the section can clear it when the
/// subtotal changes).
class PromoCodeField extends ConsumerStatefulWidget {
  const PromoCodeField({
    super.key,
    required this.orderType, // 'bookings' | 'memberships'
    required this.subtotal,
    required this.placeId,
    required this.merchantId,
    required this.categoryId,
    required this.applied,
    required this.onChange,
    required this.isAr,
  });

  final String orderType;
  final int subtotal;
  final String? placeId;
  final String? merchantId;
  final String? categoryId;
  final PromoApplied? applied;
  final ValueChanged<PromoApplied?> onChange;
  final bool isAr;

  @override
  ConsumerState<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends ConsumerState<PromoCodeField> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _mapReason(String reason) {
    final ar = widget.isAr;
    switch (reason) {
      case 'not_authenticated':
        return ar ? 'يرجى تسجيل الدخول لاستخدام الرمز' : 'Please sign in to use a code';
      case 'not_found':
        return ar ? 'الرمز غير موجود' : 'Code not found';
      case 'inactive':
        return ar ? 'هذا الرمز غير مفعل' : 'This code is no longer active';
      case 'not_started':
        return ar ? 'هذا الرمز غير صالح بعد' : "This code isn't valid yet";
      case 'expired':
        return ar ? 'انتهت صلاحية الرمز' : 'This code has expired';
      case 'wrong_order_type':
        return ar ? 'هذا الرمز لا يُستخدم هنا' : "This code can't be used here";
      case 'not_first_purchase':
        return ar ? 'صالح لأول عملية شراء فقط' : 'Only valid on first purchase';
      case 'not_new_customer':
        return ar ? 'للعملاء الجدد فقط' : 'Only valid for new customers';
      case 'out_of_scope':
        return ar ? 'لا يسري هذا الرمز هنا' : "This code doesn't apply here";
      case 'limit_reached':
        return ar ? 'وصل الرمز للحد الأقصى' : 'This code has reached its limit';
      case 'user_limit_reached':
        return ar ? 'استخدمت هذا الرمز من قبل' : "You've already used this code";
      default:
        return ar ? 'تعذّر تطبيق الرمز' : 'Could not apply this code';
    }
  }

  Future<void> _apply() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    final code = raw.toUpperCase();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history =
          await ref.read(userPurchaseHistoryProvider.future);
      final client = ref.read(supabaseProvider);
      final res = await client.schema('business').rpc(
        'preview_promo_code',
        params: {
          'p_code': code,
          'p_order_type': widget.orderType,
          'p_amount': widget.subtotal,
          'p_category_id': widget.categoryId,
          'p_merchant_id': widget.merchantId,
          'p_place_id': widget.placeId,
          'p_is_first_purchase': !history.hasOrderOfType(widget.orderType),
          'p_is_new_customer': !history.hasAnyOrder,
        },
      );
      final map = (res as Map).cast<String, dynamic>();
      if (map['valid'] == true) {
        widget.onChange(PromoApplied(
          code: code,
          percent: (map['percent'] as num).toDouble(),
          discountAmount: (map['discount_amount'] as num).round(),
          finalAmount: (map['final_amount'] as num).round(),
          promoCodeId: map['promo_code_id'] as String,
        ));
      } else {
        widget.onChange(null);
        setState(() => _error = _mapReason((map['reason'] as String?) ?? ''));
      }
    } catch (_) {
      widget.onChange(null);
      setState(() => _error =
          widget.isAr ? 'تعذّر التحقق من الرمز' : 'Could not verify code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _remove() {
    _controller.clear();
    setState(() => _error = null);
    widget.onChange(null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final applied = widget.applied;
    final isAr = widget.isAr;

    if (applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF2E7D32), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAr
                    ? 'رمز "${applied.code}" مطبّق · خصم ${applied.percent.round()}%'
                    : 'Code "${applied.code}" applied · ${applied.percent.round()}% OFF',
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            GestureDetector(
              onTap: _remove,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.close_rounded,
                    size: 18, color: cs.outline),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                enabled: !_loading,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: isAr ? 'رمز الخصم' : 'Promo code',
                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _loading ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isAr ? 'تطبيق' : 'Apply'),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/features/discounts/presentation/widgets/promo_code_field.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/discounts/presentation/widgets/promo_code_field.dart
git commit -m "feat(discounts): add PromoCodeField widget (preview RPC + uppercased code)"
```

---

## Task 7: Place details — inline discount badge

**Files:**
- Modify: `lib/features/places/presentation/widgets/place_info_section.dart`

- [ ] **Step 1: Add imports**

At the top of `lib/features/places/presentation/widgets/place_info_section.dart`, add:

```dart
import 'package:future_riverpod/core/widgets/discount_badge.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
```

- [ ] **Step 2: Read the best auto-discount and render the badge**

Inside `build()`, just after `final tagsAsync = ref.watch(placeTagsProvider(placeId));`, add:

```dart
    final autoDiscount = ref.watch(bestAutoDiscountProvider(AutoDiscountKey(
      orderType: 'bookings',
      placeId: place.id,
      merchantId: place.merchantId,
      categoryId: place.categoryId,
    )));
```

Then locate the location chip block (`if (place.area != null || place.city.isNotEmpty)`). The chip is currently wrapped in a `GestureDetector`. Replace the outer expression for that line so the chip + badge sit in a `Wrap` together. Replace:

```dart
                    if (place.area != null || place.city.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: place.latitude != null && place.longitude != null
```

with:

```dart
                    if (place.area != null || place.city.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          GestureDetector(
                        onTap: place.latitude != null && place.longitude != null
```

and the matching closing of the `GestureDetector` (find the line `),` that closes the `GestureDetector` widget, immediately before the closing `],` of the `if` block). Add a comma after it, then append the badge + close the `Wrap`. Replace the existing closing pattern (the `GestureDetector` close + `],`):

```dart
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
```

with:

```dart
                              ],
                            ],
                          ),
                        ),
                      ),
                          if (autoDiscount != null)
                            DiscountBadge(percent: autoDiscount.percent.round()),
                        ],
                      ),
                    ],
```

> Note: this Wrap replaces the previous direct child of the `if` block. If the editor produces conflicting indentation, the canonical structure is:
>
> ```dart
> if (place.area != null || place.city.isNotEmpty) ...[
>   const SizedBox(height: 8),
>   Wrap(
>     spacing: 8, runSpacing: 6,
>     crossAxisAlignment: WrapCrossAlignment.center,
>     children: [
>       GestureDetector( ... existing chip ... ),
>       if (autoDiscount != null)
>         DiscountBadge(percent: autoDiscount.percent.round()),
>     ],
>   ),
> ],
> ```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/features/places/presentation/widgets/place_info_section.dart`
Expected: No errors.

- [ ] **Step 4: Manual smoke test**

Run: `flutter run` and open a place known to have an active row in `business.discounts` that targets that place (or `scope_type='app'`). Expected: a red "X% OFF" pill appears next to the location chip on the details page.

- [ ] **Step 5: Commit**

```bash
git add lib/features/places/presentation/widgets/place_info_section.dart
git commit -m "feat(places): show auto-discount badge next to location chip on details page"
```

---

## Task 8: Submit providers — accept `promoCode`

**Files:**
- Modify: `lib/features/booking/presentation/providers/booking_submit_provider.dart`
- Modify: `lib/features/booking/presentation/providers/membership_submit_provider.dart`

- [ ] **Step 1: Add optional `promoCode` to padel/farm/restaurant submitters**

In `lib/features/booking/presentation/providers/booking_submit_provider.dart`:

For `createPadelBooking`, replace its signature + body:

```dart
  Future<void> createPadelBooking({
    required String placeId,
    required String courtId,
    required String startsAt,
    required int hours,
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
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode.toUpperCase(),
        },
      );
      if (result.status != 200) throw Exception(result.data.toString());
      final data = result.data as Map<String, dynamic>;
      state = BookingSubmitState.success(
        bookingId: data['booking_id'] as String,
        paymentUrl: data['payment_url'] as String,
        holdUntil: data['hold_until'] as String? ?? '',
        waylReferenceId: data['reference_id'] as String,
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }
```

For `createFarmBooking`, same pattern — add `String? promoCode,` to the signature and `if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode.toUpperCase(),` to the body.

For `createRestaurantBooking`, same. (Restaurant has no subtotal today, but accepting the param keeps the API uniform for the future.)

`createConcertBooking` is **not** touched (concerts excluded).

- [ ] **Step 2: Add optional `promoCode` to membership submitter**

In `lib/features/booking/presentation/providers/membership_submit_provider.dart`, update `createMembership`:

```dart
  Future<void> createMembership({
    required String placeId,
    required String planId,
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
      );
    } catch (e) {
      state = BookingSubmitState.error(e.toString());
    }
  }
```

- [ ] **Step 3: Invalidate purchase history on successful payment**

In each section's `onPaymentSuccess` callback (padel, farm, restaurant, membership), after the existing `ref.read(bookingsRefreshProvider.notifier).bump();` line, append:

```dart
ref.invalidate(userPurchaseHistoryProvider);
```

Add the import to each modified section file:

```dart
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
```

Files to touch:
- `lib/features/booking/presentation/sections/padel_section.dart` (onPaymentSuccess inside `openPaymentWebView`)
- `lib/features/booking/presentation/sections/farm_section.dart` (same)
- `lib/features/booking/presentation/sections/restaurant_section.dart` (in the `ref.listen` success path — find `ref.read(bookingsRefreshProvider.notifier).bump();`)
- `lib/features/booking/presentation/sections/membership_section.dart` (inside `onPaymentSuccess`)

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/features/booking/`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/booking/presentation/providers/booking_submit_provider.dart \
        lib/features/booking/presentation/providers/membership_submit_provider.dart \
        lib/features/booking/presentation/sections/
git commit -m "feat(booking): accept optional promoCode (uppercased) in submit providers"
```

---

## Task 9: Wire padel section

**Files:**
- Modify: `lib/features/booking/presentation/sections/padel_section.dart`

- [ ] **Step 1: Add imports + local promo provider**

At the top of `lib/features/booking/presentation/sections/padel_section.dart`, add:

```dart
import 'package:future_riverpod/core/utils/iqd.dart' as iqd; // see step 2 — create if missing
import 'package:future_riverpod/features/discounts/domain/discount_math.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/widgets/promo_code_field.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
```

If `lib/core/utils/iqd.dart` does not exist, create it with the existing `_formatPrice` logic so both auto-discount and promo branches can format IQD identically. Actually skip that — keep the existing `_formatPrice` static inside the section; just add a sibling helper:

Remove the `import 'package:future_riverpod/core/utils/iqd.dart'` line — instead, inline a tiny helper at the top of `_BookingFormView` (right above `_timeLabel`):

```dart
  static String _formatIqd(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'IQD $formatted';
  }
```

- [ ] **Step 2: Add promo state provider near the other locals**

Below the existing `final _selectedSlotsProvider = ...;` line, add:

```dart
final _padelPromoProvider =
    NotifierProvider.autoDispose<_PadelPromoNotifier, PromoApplied?>(
        _PadelPromoNotifier.new);

class _PadelPromoNotifier extends AutoDisposeNotifier<PromoApplied?> {
  @override
  PromoApplied? build() => null;
  void set(PromoApplied? p) => state = p;
}
```

- [ ] **Step 3: Read the place to get merchantId / categoryId**

Inside `build()` of `_BookingFormView`, after the existing `closedDates` line, add:

```dart
    final placeAsync = ref.watch(placeDetailsProvider(placeId));
    final place = placeAsync.value;
    final autoDiscount = ref.watch(bestAutoDiscountProvider(AutoDiscountKey(
      orderType: 'bookings',
      placeId: placeId,
      merchantId: place?.merchantId,
      categoryId: place?.categoryId,
    )));
    final promo = ref.watch(_padelPromoProvider);
```

- [ ] **Step 4: Compute subtotal/final in the summary block**

Locate the `BookingSummaryCard(...)` call inside the `AnimatedSwitcher`. Just before it, compute the numbers:

```dart
                    final hours = selectedSlots.length;
                    final subtotal = (selectedCourt.pricePerHour * hours).toInt();
                    final effective = promo != null
                        ? (
                            discount: promo.discountAmount,
                            finalAmount: promo.finalAmount,
                            label: '${promo.percent.round()}% OFF · ${promo.code}',
                          )
                        : (autoDiscount != null
                            ? () {
                                final r = computeDiscount(
                                  subtotal: subtotal,
                                  percent: autoDiscount.percent,
                                  maxCap: autoDiscount.maxDiscountAmount,
                                );
                                return (
                                  discount: r.discountAmount,
                                  finalAmount: r.finalAmount,
                                  label: '${autoDiscount.percent.round()}% OFF',
                                );
                              }()
                            : (discount: 0, finalAmount: subtotal, label: ''));
```

Note: this needs to live inside the `(selectedCourt != null && selectedSlots.isNotEmpty)` branch — wrap the existing `Padding(...)` in a Builder or convert the ternary's true branch to a block that returns the Padding. The cleanest approach: replace the ternary's true branch with a closure-immediate-invocation, or use a `Builder` widget.

Concretely, replace:

```dart
            child: (selectedCourt != null && selectedSlots.isNotEmpty)
                ? Padding(
                    key: const ValueKey('summary-visible'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BookingSummaryCard(
                      title: isAr ? 'ملخص الحجز' : 'Booking Summary',
                      ...
                      totalLabel: isAr ? 'المبلغ الإجمالي' : 'Total Amount',
                      totalValue: _formatPrice(
                          selectedCourt.pricePerHour, selectedSlots.length),
                      actionLabel:
                          isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
```

with:

```dart
            child: (selectedCourt != null && selectedSlots.isNotEmpty)
                ? Builder(
                    key: const ValueKey('summary-visible'),
                    builder: (context) {
                      final hours = selectedSlots.length;
                      final subtotal =
                          (selectedCourt.pricePerHour * hours).toInt();
                      final eff = _resolveEffective(
                        subtotal: subtotal,
                        promo: promo,
                        autoDiscount: autoDiscount,
                      );
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: BookingSummaryCard(
                          title: isAr ? 'ملخص الحجز' : 'Booking Summary',
                          badgeText: isAr
                              ? '${selectedSlots.length} ${selectedSlots.length == 1 ? 'ساعة' : 'ساعات'}'
                              : '${selectedSlots.length} ${selectedSlots.length == 1 ? 'hour' : 'hours'}',
                          rows: [
                            // ── existing rows kept unchanged
                            BookingSummaryRow(
                              icon: Icons.sports_tennis_rounded,
                              label: isAr ? 'الملعب' : 'Court',
                              valueWidget: BilingualLabel(
                                ar: selectedCourt.nameAr,
                                en: selectedCourt.nameEn,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            BookingSummaryRow(
                              icon: Icons.calendar_today_rounded,
                              label: isAr ? 'التاريخ' : 'Date',
                              value: bookingDisplayDate(selectedDate,
                                  isArabic: isAr),
                            ),
                            BookingSummaryRow(
                              icon: Icons.schedule_rounded,
                              label: isAr ? 'الوقت' : 'Time',
                              value: _timeRange(selectedSlots),
                            ),
                          ],
                          subtotalLabel: isAr ? 'المجموع' : 'Subtotal',
                          subtotalValue:
                              eff.discount > 0 ? _formatIqd(subtotal) : null,
                          discountLabel: eff.discount > 0 ? eff.label : null,
                          discountValue: eff.discount > 0
                              ? '−${_formatIqd(eff.discount)}'
                              : null,
                          totalLabel:
                              isAr ? 'المبلغ الإجمالي' : 'Total Amount',
                          totalValue: _formatIqd(eff.finalAmount),
                          extraSlot: subtotal > 0
                              ? PromoCodeField(
                                  orderType: 'bookings',
                                  subtotal: subtotal,
                                  placeId: placeId,
                                  merchantId: place?.merchantId,
                                  categoryId: place?.categoryId,
                                  applied: promo,
                                  isAr: isAr,
                                  onChange: (p) => ref
                                      .read(_padelPromoProvider.notifier)
                                      .set(p),
                                )
                              : null,
                          actionLabel:
                              isAr ? 'المتابعة للدفع' : 'Proceed to Payment',
                          onAction: () {
                            final current = ref.read(bookingSubmitProvider);
                            current.maybeWhen(
                              success: (bookingId, paymentUrl, holdUntil,
                                  waylReferenceId) {
                                if (paymentUrl.isNotEmpty) {
                                  openPaymentWebView(
                                      bookingId, paymentUrl, waylReferenceId);
                                }
                              },
                              orElse: () {
                                final sorted = selectedSlots.toList()..sort();
                                ref
                                    .read(bookingSubmitProvider.notifier)
                                    .createPadelBooking(
                                      placeId: placeId,
                                      courtId: selectedCourt.id,
                                      startsAt: sorted.first,
                                      hours: selectedSlots.length,
                                      promoCode: promo?.code,
                                    );
                              },
                            );
                          },
                          isLoading: isLoading,
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('summary-hidden')),
```

Add the `_resolveEffective` helper as a static method on `_BookingFormView`:

```dart
  static ({int discount, int finalAmount, String label}) _resolveEffective({
    required int subtotal,
    required PromoApplied? promo,
    required AutoDiscount? autoDiscount,
  }) {
    if (promo != null) {
      return (
        discount: promo.discountAmount,
        finalAmount: promo.finalAmount,
        label: '${promo.percent.round()}% OFF · ${promo.code}',
      );
    }
    if (autoDiscount != null) {
      final r = computeDiscount(
        subtotal: subtotal,
        percent: autoDiscount.percent,
        maxCap: autoDiscount.maxDiscountAmount,
      );
      return (
        discount: r.discountAmount,
        finalAmount: r.finalAmount,
        label: '${autoDiscount.percent.round()}% OFF',
      );
    }
    return (discount: 0, finalAmount: subtotal, label: '');
  }
```

Add the `AutoDiscount` import:

```dart
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
```

- [ ] **Step 5: When subtotal changes, re-preview the promo (or drop it)**

After computing `subtotal` inside the builder, add:

```dart
                      // Re-validate promo on subtotal change.
                      if (promo != null && promo.finalAmount + promo.discountAmount != subtotal) {
                        // The widget will re-run preview next build via key change.
                        // Simplest: clear it; user can re-apply.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(_padelPromoProvider.notifier).set(null);
                        });
                      }
```

- [ ] **Step 6: Invalidate purchase history on success (if not done in Task 8)**

Verify the `onPaymentSuccess` block in `openPaymentWebView` now invalidates `userPurchaseHistoryProvider`. If Task 8 already did this, skip.

- [ ] **Step 7: Run analyzer + smoke test**

Run: `flutter analyze lib/features/booking/presentation/sections/padel_section.dart`
Expected: No errors.

Manual smoke test:
- Open a padel place that has an active `business.discounts` row matching it. Expected: badge on the details page, summary shows subtotal struck-through + discount line + new total.
- Type a known active code in lowercase → tap Apply → expect green chip with uppercased code, summary recomputes.
- Tap the × on the chip → original total restored.
- Try an expired/unknown code → red error message shown, total unchanged.

- [ ] **Step 8: Commit**

```bash
git add lib/features/booking/presentation/sections/padel_section.dart
git commit -m "feat(padel): wire promo code field + discount breakdown into checkout"
```

---

## Task 10: Wire farm section

**Files:**
- Modify: `lib/features/booking/presentation/sections/farm_section.dart`

- [ ] **Step 1: Add imports + local promo provider**

Add at the top:

```dart
import 'package:future_riverpod/features/discounts/domain/discount_math.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/widgets/promo_code_field.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
```

Below the existing `final _farmSelectedShiftProvider = ...;` line, add:

```dart
final _farmPromoProvider =
    NotifierProvider.autoDispose<_FarmPromoNotifier, PromoApplied?>(
        _FarmPromoNotifier.new);

class _FarmPromoNotifier extends AutoDisposeNotifier<PromoApplied?> {
  @override
  PromoApplied? build() => null;
  void set(PromoApplied? p) => state = p;
}
```

- [ ] **Step 2: Apply the same wiring pattern as padel**

Inside `_FarmBookingFormView.build()`, after `final closedDates = ...;`, add:

```dart
    final placeAsync = ref.watch(placeDetailsProvider(placeId));
    final place = placeAsync.value;
    final autoDiscount = ref.watch(bestAutoDiscountProvider(AutoDiscountKey(
      orderType: 'bookings',
      placeId: placeId,
      merchantId: place?.merchantId,
      categoryId: place?.categoryId,
    )));
    final promo = ref.watch(_farmPromoProvider);
```

Replace the `child: selectedShift != null ? Padding(...) : const SizedBox.shrink(...)` block with the same `Builder` pattern from Task 9, computing:

```dart
final subtotal = selectedShift.priceIqd;
```

and threading `subtotalValue` / `discountValue` / `discountLabel` / `totalValue` into `BookingSummaryCard`. The `extraSlot` is the `PromoCodeField` (orderType `bookings`), shown only when `subtotal > 0`.

In `onAction`'s `orElse` branch, pass `promoCode: promo?.code` to `createFarmBooking(...)`.

Add the same `_resolveEffective` static helper to `_FarmBookingFormView` (copy from Task 9).

- [ ] **Step 3: Run analyzer + smoke test**

Run: `flutter analyze lib/features/booking/presentation/sections/farm_section.dart`
Expected: No errors.

Manual: open a farm place with an active discount, select a shift, see the breakdown; apply a code; verify case folding.

- [ ] **Step 4: Commit**

```bash
git add lib/features/booking/presentation/sections/farm_section.dart
git commit -m "feat(farm): wire promo code field + discount breakdown into checkout"
```

---

## Task 11: Wire membership section

**Files:**
- Modify: `lib/features/booking/presentation/sections/membership_section.dart`

- [ ] **Step 1: Add imports + local promo provider**

Add at the top:

```dart
import 'package:future_riverpod/features/discounts/domain/discount_math.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
import 'package:future_riverpod/features/discounts/presentation/widgets/promo_code_field.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
```

Below `final _selectedMembershipPlanProvider = ...;` add:

```dart
final _membershipPromoProvider =
    NotifierProvider.autoDispose<_MembershipPromoNotifier, PromoApplied?>(
        _MembershipPromoNotifier.new);

class _MembershipPromoNotifier extends AutoDisposeNotifier<PromoApplied?> {
  @override
  PromoApplied? build() => null;
  void set(PromoApplied? p) => state = p;
}
```

- [ ] **Step 2: Same wiring pattern**

Inside `_MembershipFormView.build()`, after reading the existing locals, add:

```dart
    final placeAsync = ref.watch(placeDetailsProvider(placeId));
    final place = placeAsync.value;
    final autoDiscount = ref.watch(bestAutoDiscountProvider(AutoDiscountKey(
      orderType: 'memberships',
      placeId: placeId,
      merchantId: place?.merchantId,
      categoryId: place?.categoryId,
    )));
    final promo = ref.watch(_membershipPromoProvider);
```

Wrap the existing `BookingSummaryCard(...)` in a `Builder` with `subtotal = selectedPlan.priceIqd`. Add the `_resolveEffective` static helper (same shape). Pass:

```dart
subtotalLabel: isAr ? 'المجموع' : 'Subtotal',
subtotalValue: eff.discount > 0 ? _formatPrice(subtotal) : null,
discountLabel: eff.discount > 0 ? eff.label : null,
discountValue: eff.discount > 0 ? '−${_formatPrice(eff.discount)}' : null,
totalValue: _formatPrice(eff.finalAmount),
extraSlot: subtotal > 0
    ? PromoCodeField(
        orderType: 'memberships',
        subtotal: subtotal,
        placeId: placeId,
        merchantId: place?.merchantId,
        categoryId: place?.categoryId,
        applied: promo,
        isAr: isAr,
        onChange: (p) => ref.read(_membershipPromoProvider.notifier).set(p),
      )
    : null,
```

In `onAction`, change the `createMembership` call to:

```dart
                            .createMembership(
                              placeId: placeId,
                              planId: plan.id,
                              promoCode: promo?.code,
                            );
```

- [ ] **Step 3: Run analyzer + smoke test**

Run: `flutter analyze lib/features/booking/presentation/sections/membership_section.dart`
Expected: No errors.

Manual: open a place with memberships and an `applies_to: ['memberships']` discount; verify breakdown; apply a code.

- [ ] **Step 4: Commit**

```bash
git add lib/features/booking/presentation/sections/membership_section.dart
git commit -m "feat(membership): wire promo code field + discount breakdown into checkout"
```

---

## Task 12: Final verification

- [ ] **Step 1: Run all tests**

Run: `flutter test`
Expected: All tests pass, including new discount tests and existing tests.

- [ ] **Step 2: Run analyzer across changed dirs**

Run: `flutter analyze lib/features/discounts/ lib/features/booking/ lib/features/places/ lib/core/widgets/`
Expected: No errors, no new warnings.

- [ ] **Step 3: Manual acceptance — walk the checklist**

For each item below, exercise the app:

- [ ] Place card badge shows for a place with an active applicable `business.discounts` row.
- [ ] Place details page shows the same badge next to the location chip.
- [ ] Padel/farm/membership checkouts show the promo field above the action button.
- [ ] Order summary shows Subtotal (struck through) → Discount line → Total when any discount applies.
- [ ] Lowercase / mixed-case codes are uppercased before sending; verify in the network/edge-function log.
- [ ] An invalid code shows the mapped error message (try `BOGUS`); applied state stays clear; total unchanged.
- [ ] Subtotal change after applying a code (e.g. add another padel slot) clears the applied code; user can re-apply.
- [ ] After a successful order, the next promo preview no longer sees the user as first-purchase (verify via `user_limit_reached` or similar code if available).
- [ ] Concerts page: no promo field, no badge change.
- [ ] Restaurants (request-based): no promo field (subtotal is zero).

- [ ] **Step 4: Commit**

If any small fixes were needed during verification, commit them:

```bash
git add -A
git commit -m "chore: post-verification fixes for discount/promo flow"
```

---

## Self-Review

Spec coverage:
- §1 Domain layer → Tasks 1, 2, 3.
- §2 Providers → Tasks 3, 4.
- §3 Card badge → Task 3 step 3.
- §4 Place details badge → Task 7.
- §5 PromoCodeField → Task 6.
- §6 Order summary changes → Task 5.
- §7 Wire each section → Tasks 9, 10, 11.
- §8 Submit provider changes → Task 8.
- §9 Error message map → Task 6 (`_mapReason`).

Restaurant is intentionally excluded from wiring because it has no subtotal today (request-based booking); the spec's "Hide when subtotal is 0" rule means the `extraSlot` would render `null` even if wired — so we save the noise.

Concerts are intentionally untouched per user requirement.
