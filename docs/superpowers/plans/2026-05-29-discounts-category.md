# Discounts Category Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a synthetic "Discounts" chip to the home-screen category bar that shows a paginated feed of all places with any active discount.

**Architecture:** A hardcoded chip is prepended to the existing `CategoryBar` at virtual index `-1`. Tapping it sets `selectedCategoryProvider` to `-1`, which `home_page.dart` routes to a new `DiscountsFeedSection`. The section is backed by a new `DiscountsFeed` Riverpod notifier that reads the already-loaded `merchantDiscountsProvider` / `autoDiscountsProvider` to build eligible ID sets, then queries `content.places_mobile` with an OR filter.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation / build_runner), Supabase Flutter client, `flutter_test`

**Existing foundation (uncommitted in working tree — build ON it, do not revert):**
- `category_bar.dart`: `_categoryIcon` already maps `case 'Discounts'` → `assets/lottie/categories/discount.lottie`. The chip MUST use `_categoryIcon('Discounts', animate: isActive)`, NOT a `CupertinoIcons` icon. Verified: `Lottie.asset` (no decoder) handles the dotLottie `.lottie` file automatically (defaults to `decodeZip`).
- `category_feed_provider.dart`: `CategoryFeedItem` already has a `merchantId` field; `fromRow`/`fromTrendingRow` already read `merchant_id`; the `CategoryFeed`/`AllPlacesFeed` queries already select `merchant_id, logo_url`. The new `DiscountsFeed` query aligns with this.
- `home_page.dart`: `_onRefresh` already invalidates `merchantDiscountsProvider` and `autoDiscountsProvider`, and already imports `merchant_discounts_provider.dart`. Only `discountsFeedProvider` invalidation needs adding.

Commits land on `main` (user confirmed). Each commit stages only its own files — never `git add -A` (≈140 unrelated files are uncommitted in the tree).

---

## File Map

| File | Action | What changes |
|------|--------|-------------|
| `lib/features/home/presentation/providers/category_feed_provider.dart` | Modify | Add `buildDiscountEligibility` helper + `DiscountsFeed` notifier |
| `lib/features/home/presentation/providers/category_feed_provider.g.dart` | Regenerate | build_runner output |
| `lib/features/home/presentation/widgets/when_no_data_available.dart` | Modify | Add `DiscountsFeedSection` widget |
| `lib/features/home/presentation/widgets/category_bar.dart` | Modify | Prepend hardcoded Discounts chip |
| `lib/features/home/presentation/pages/home_page.dart` | Modify | Add constant, guard, Discounts branch, refresh invalidation |
| `test/features/discounts/domain/discount_eligibility_test.dart` | Create | Unit tests for `buildDiscountEligibility` |

---

## Task 1: Extract and test `buildDiscountEligibility` helper

This is the only non-trivial pure logic in the feature. Extract it first so it can be tested in isolation before the Riverpod wiring goes in.

**Files:**
- Modify: `lib/features/home/presentation/providers/category_feed_provider.dart`
- Create: `test/features/discounts/domain/discount_eligibility_test.dart`

- [ ] **Step 1: Add the helper and its return type to `category_feed_provider.dart`**

Open `lib/features/home/presentation/providers/category_feed_provider.dart`. Add these two declarations **before** the `CategoryFeedItem` class (after the existing imports / `part` line):

```dart
// ─────────────────────────────────────────────────────────────────────────────
//  DiscountEligibility — result of buildDiscountEligibility
// ─────────────────────────────────────────────────────────────────────────────
class DiscountEligibility {
  const DiscountEligibility({
    required this.merchantIds,
    required this.placeIds,
    required this.appWide,
  });

  final Set<String> merchantIds;
  final Set<String> placeIds;
  final bool appWide; // true → all places qualify (app-scope AutoDiscount exists)

  bool get isEmpty => !appWide && merchantIds.isEmpty && placeIds.isEmpty;
}

/// Derives which places are eligible for a discount from the two discount lists.
/// Pure function — no I/O, easy to test.
DiscountEligibility buildDiscountEligibility({
  required List<MerchantDiscount> merchantDiscounts,
  required List<AutoDiscount> autoDiscounts,
  DateTime? now,
}) {
  final t = now ?? DateTime.now();
  final merchantIds = <String>{};
  final placeIds = <String>{};

  for (final d in merchantDiscounts) {
    if (!d.isCurrentlyActive(t)) continue;
    merchantIds.add(d.merchantId);
    if (!d.appliesToAllPlaces) placeIds.addAll(d.placeIds);
  }

  for (final d in autoDiscounts) {
    if (!d.isActive) continue;
    if (d.startsAt != null && t.isBefore(d.startsAt!)) continue;
    if (d.endsAt != null && t.isAfter(d.endsAt!)) continue;
    if (d.scopeType == 'app') {
      return DiscountEligibility(
        merchantIds: merchantIds,
        placeIds: placeIds,
        appWide: true,
      );
    }
    merchantIds.addAll(d.targetMerchantIds);
    placeIds.addAll(d.targetPlaceIds);
  }

  return DiscountEligibility(
    merchantIds: merchantIds,
    placeIds: placeIds,
    appWide: false,
  );
}
```

The two imports needed at the top of the file (add after the existing imports):
```dart
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/domain/models/merchant_discount.dart';
```

- [ ] **Step 2: Write the failing tests**

Create `test/features/discounts/domain/discount_eligibility_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/domain/models/merchant_discount.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';

void main() {
  final now = DateTime(2026, 5, 29, 12, 0);

  MerchantDiscount merchantDiscount({
    required String id,
    required String merchantId,
    bool appliesToAllPlaces = true,
    List<String> placeIds = const [],
    bool isActive = true,
    DateTime? startsAt,
    DateTime? expiresAt,
  }) =>
      MerchantDiscount(
        id: id,
        merchantId: merchantId,
        percent: 10,
        appliesToAllPlaces: appliesToAllPlaces,
        placeIds: placeIds,
        timeMode: 'all_day',
        hourSlots: const [],
        discountDates: const [],
        isActive: isActive,
        startsAt: startsAt,
        expiresAt: expiresAt,
      );

  AutoDiscount autoDiscount({
    required String scopeType,
    List<String> targetMerchantIds = const [],
    List<String> targetPlaceIds = const [],
    bool isActive = true,
    DateTime? startsAt,
    DateTime? endsAt,
  }) =>
      AutoDiscount(
        id: 'a1',
        name: 'test',
        percent: 5,
        appliesTo: const ['bookings'],
        scopeType: scopeType,
        targetCategoryIds: const [],
        targetMerchantIds: targetMerchantIds,
        targetPlaceIds: targetPlaceIds,
        isActive: isActive,
        startsAt: startsAt,
        endsAt: endsAt,
      );

  group('buildDiscountEligibility', () {
    test('empty inputs → isEmpty', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [],
        now: now,
      );
      expect(e.isEmpty, isTrue);
      expect(e.appWide, isFalse);
    });

    test('active merchant discount adds merchantId', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [merchantDiscount(id: 'd1', merchantId: 'm1')],
        autoDiscounts: [],
        now: now,
      );
      expect(e.merchantIds, contains('m1'));
      expect(e.appWide, isFalse);
    });

    test('inactive merchant discount is ignored', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [
          merchantDiscount(id: 'd1', merchantId: 'm1', isActive: false),
        ],
        autoDiscounts: [],
        now: now,
      );
      expect(e.isEmpty, isTrue);
    });

    test('expired merchant discount is ignored', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [
          merchantDiscount(
            id: 'd1',
            merchantId: 'm1',
            expiresAt: DateTime(2026, 5, 1),
          ),
        ],
        autoDiscounts: [],
        now: now,
      );
      expect(e.isEmpty, isTrue);
    });

    test('place-specific discount adds placeIds', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [
          merchantDiscount(
            id: 'd1',
            merchantId: 'm1',
            appliesToAllPlaces: false,
            placeIds: ['p1', 'p2'],
          ),
        ],
        autoDiscounts: [],
        now: now,
      );
      expect(e.merchantIds, contains('m1'));
      expect(e.placeIds, containsAll(['p1', 'p2']));
    });

    test('app-scope AutoDiscount → appWide = true', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [autoDiscount(scopeType: 'app')],
        now: now,
      );
      expect(e.appWide, isTrue);
    });

    test('targeted AutoDiscount adds merchant and place ids', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [
          autoDiscount(
            scopeType: 'targeted',
            targetMerchantIds: ['m2'],
            targetPlaceIds: ['p3'],
          ),
        ],
        now: now,
      );
      expect(e.merchantIds, contains('m2'));
      expect(e.placeIds, contains('p3'));
      expect(e.appWide, isFalse);
    });

    test('inactive AutoDiscount is ignored', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [autoDiscount(scopeType: 'app', isActive: false)],
        now: now,
      );
      expect(e.appWide, isFalse);
    });

    test('future AutoDiscount is ignored', () {
      final e = buildDiscountEligibility(
        merchantDiscounts: [],
        autoDiscounts: [
          autoDiscount(
            scopeType: 'app',
            startsAt: DateTime(2026, 6, 1),
          ),
        ],
        now: now,
      );
      expect(e.appWide, isFalse);
    });
  });
}
```

- [ ] **Step 3: Run tests — expect failures (helper not yet in file)**

```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
flutter test test/features/discounts/domain/discount_eligibility_test.dart --reporter=compact
```

Expected: compile error or test failures (function doesn't exist yet).

- [ ] **Step 4: Confirm the helper is in the file (Step 1 already added it — verify it compiles)**

```bash
flutter test test/features/discounts/domain/discount_eligibility_test.dart --reporter=compact
```

Expected output: all 9 tests **PASS**.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/providers/category_feed_provider.dart \
        test/features/discounts/domain/discount_eligibility_test.dart
git commit -m "feat: add buildDiscountEligibility helper with tests"
```

---

## Task 2: Add `DiscountsFeed` notifier and regenerate

**Files:**
- Modify: `lib/features/home/presentation/providers/category_feed_provider.dart`
- Regenerate: `lib/features/home/presentation/providers/category_feed_provider.g.dart`

- [ ] **Step 1: Add the `DiscountsFeed` notifier at the bottom of `category_feed_provider.dart`**

Add this after the existing `AllPlacesFeed` class:

```dart
// ─────────────────────────────────────────────────────────────────────────────
//  DiscountsFeed — paginated places that have any active discount
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class DiscountsFeed extends _$DiscountsFeed {
  static const _pageSize = 10;

  @override
  CategoryFeedState build() {
    Future.microtask(loadMore);
    return const CategoryFeedState();
  }

  Future<void> loadMore() async {
    if (state.isLoading && state.page > 0) return;
    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final eligibility = buildDiscountEligibility(
        merchantDiscounts:
            await ref.read(merchantDiscountsProvider.future),
        autoDiscounts:
            await ref.read(autoDiscountsProvider.future),
      );

      if (eligibility.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasMore: false,
          items: [],
        );
        return;
      }

      final from = state.page * _pageSize;
      final to = from + _pageSize - 1;

      var query = Supabase.instance.client
          .schema('content')
          .from('places_mobile')
          .select(
            'id, merchant_id, name_en, name_ar, area, cover_image_url, logo_url, is_verified',
          )
          .eq('place_status', 'approved');

      if (!eligibility.appWide) {
        final filters = <String>[];
        if (eligibility.merchantIds.isNotEmpty) {
          filters.add(
            'merchant_id.in.(${eligibility.merchantIds.join(',')})',
          );
        }
        if (eligibility.placeIds.isNotEmpty) {
          filters.add('id.in.(${eligibility.placeIds.join(',')})');
        }
        query = query.or(filters.join(','));
      }

      final rows = await query
          .order('hotness_score', ascending: false)
          .range(from, to);

      final fetched = (rows as List)
          .map((r) => CategoryFeedItem.fromRow(r as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...fetched],
        isLoading: false,
        hasMore: fetched.length == _pageSize,
        page: state.page + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasMore: false, hasError: true);
    }
  }

  Future<void> refresh() async {
    state = const CategoryFeedState();
    await loadMore();
  }
}
```

Also add the missing imports at the top of the file (after existing imports):
```dart
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
```

(The `auto_discount.dart` and `merchant_discount.dart` imports were added in Task 1.)

- [ ] **Step 2: Run build_runner**

```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: exits with no errors. `category_feed_provider.g.dart` now contains `discountsFeedProvider`.

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/features/home/presentation/providers/category_feed_provider.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/providers/category_feed_provider.dart \
        lib/features/home/presentation/providers/category_feed_provider.g.dart
git commit -m "feat: add DiscountsFeed Riverpod notifier"
```

---

## Task 3: Add `DiscountsFeedSection` widget

**Files:**
- Modify: `lib/features/home/presentation/widgets/when_no_data_available.dart`

- [ ] **Step 1: Add `DiscountsFeedSection` to the bottom of `when_no_data_available.dart`**

Add this after the closing brace of `CategoryFeedSection`:

```dart
class DiscountsFeedSection extends ConsumerWidget {
  const DiscountsFeedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(discountsFeedProvider);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final cs = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    if (feed.isFirstLoad) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: buildFullWidthSkeleton(context),
          ),
          childCount: 3,
        ),
      );
    }

    if (feed.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: Lottie.asset('assets/lottie/animation/no_internet.json'),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'تعذّر تحميل البيانات' : 'Failed to load',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    if (feed.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                child: Lottie.asset('assets/lottie/animation/empty.json'),
              ),
              Text(
                isAr
                    ? 'لا توجد خصومات متاحة حالياً'
                    : 'No discounts available right now',
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'تحقق لاحقاً!' : 'Check back later!',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == feed.items.length) {
          if (feed.hasMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(discountsFeedProvider.notifier).loadMore();
            });
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                isAr ? '— لقد وصلت للنهاية —' : '— You\'ve reached the end —',
                style: tt.labelMedium?.copyWith(
                  color: cs.onTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: FullWidthFeedCard(item: feed.items[index]),
        );
      }, childCount: feed.items.length + 1),
    );
  }
}
```

Add the missing import at the top of `when_no_data_available.dart`:
```dart
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
```

(It already imports `category_feed_provider.dart` — verify the import is present before adding.)

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/home/presentation/widgets/when_no_data_available.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/widgets/when_no_data_available.dart
git commit -m "feat: add DiscountsFeedSection widget"
```

---

## Task 4: Update `CategoryBar` with hardcoded Discounts chip

**Files:**
- Modify: `lib/features/home/presentation/widgets/category_bar.dart`

- [ ] **Step 1: Replace the `ListView` block inside `data:` in `category_bar.dart`**

The current `data:` callback (lines 24–92) renders `itemCount: cats.length` with `select(i)` and `isActive = selectedIndex == i`. Replace the entire `data:` lambda with:

```dart
data: (cats) => SizedBox(
  height: 110,
  child: ListView.separated(
    physics: const BouncingScrollPhysics(),
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
    itemCount: cats.length + 1,
    separatorBuilder: (_, _) => const SizedBox(width: 12),
    itemBuilder: (_, i) {
      // ── Discounts chip (synthetic index -1) ──────────────────────
      if (i == 0) {
        final isActive = selectedIndex == -1;
        return GestureDetector(
          onTap: () => ref.read(selectedCategoryProvider.notifier).select(-1),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.colorScheme.surfaceContainerHigh,
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                // Reuses the existing _categoryIcon path, which maps
                // 'Discounts' → assets/lottie/categories/discount.lottie.
                child: Center(
                  child: _categoryIcon('Discounts', animate: isActive),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAr ? 'خصومات' : 'Discounts',
                style: tt.labelLarge?.copyWith(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      // ── Regular DB category (offset by 1) ────────────────────────
      final catIndex = i - 1;
      final isActive = selectedIndex == catIndex;
      final cat = cats[catIndex];

      return GestureDetector(
        onTap: () {
          ref.read(selectedCategoryProvider.notifier).select(catIndex);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.surfaceContainerHigh,
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: _categoryIcon(cat.nameEn, animate: isActive),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAr ? cat.nameAr : cat.nameEn,
              style: tt.labelLarge?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    },
  ),
),
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/home/presentation/widgets/category_bar.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/widgets/category_bar.dart
git commit -m "feat: prepend Discounts chip to CategoryBar"
```

---

## Task 5: Wire Discounts branch into `home_page.dart`

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`

- [ ] **Step 1: Add the constant and fix the `selectedCat` guard**

At the top of `home_page.dart`, after the existing imports, add:

```dart
const int kDiscountsCategoryIndex = -1;
```

Find the existing `selectedCat` derivation (around line 102–108):

```dart
final selectedCat =
    (selectedIdx != null &&
        categories != null &&
        selectedIdx < categories.length)
    ? categories[selectedIdx]
    : null;
```

Replace with:

```dart
final selectedCat =
    (selectedIdx != null &&
        selectedIdx >= 0 &&
        categories != null &&
        selectedIdx < categories.length)
    ? categories[selectedIdx]
    : null;
```

- [ ] **Step 2: Add the Discounts sliver branch**

Find the existing branch (around line 294–305):

```dart
} else ...[
  SliverToBoxAdapter(
    child: _sectionTitle(
      isAr ? selectedCat.nameAr : selectedCat.nameEn,
    ),
  ),
  CategoryFeedSection(
    categoryId: selectedCat.id,
    categoryNameEn: selectedCat.nameEn,
    categoryNameAr: selectedCat.nameAr,
  ),
],
```

Replace with:

```dart
} else if (selectedIdx == kDiscountsCategoryIndex) ...[
  SliverToBoxAdapter(
    child: _sectionTitle(isAr ? 'خصومات' : 'Discounts'),
  ),
  const DiscountsFeedSection(),
] else if (selectedCat != null) ...[
  SliverToBoxAdapter(
    child: _sectionTitle(
      isAr ? selectedCat.nameAr : selectedCat.nameEn,
    ),
  ),
  CategoryFeedSection(
    categoryId: selectedCat.id,
    categoryNameEn: selectedCat.nameEn,
    categoryNameAr: selectedCat.nameAr,
  ),
],
```

- [ ] **Step 3: Invalidate `discountsFeedProvider` in `_onRefresh`**

`_onRefresh()` already invalidates `merchantDiscountsProvider` and `autoDiscountsProvider` (existing foundation). Add one more line after the existing `ref.invalidate` calls so the discounts feed itself re-queries on pull-to-refresh:

```dart
ref.invalidate(discountsFeedProvider);
```

- [ ] **Step 4: Add the missing import for `DiscountsFeedSection`**

The `DiscountsFeedSection` is defined in `when_no_data_available.dart`. That file is already imported in `home_page.dart` (check line ~26). If it isn't, add:

```dart
import 'package:future_riverpod/features/home/presentation/widgets/when_no_data_available.dart';
```

- [ ] **Step 5: Verify no analysis errors**

```bash
flutter analyze lib/features/home/presentation/pages/home_page.dart
```

Expected: `No issues found!`

- [ ] **Step 6: Run full analysis**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/features/home/presentation/pages/home_page.dart
git commit -m "feat: wire Discounts category into home page feed"
```

---

## Task 6: Run all tests

- [ ] **Step 1: Run the full test suite**

```bash
cd /Users/mousaalhamad/Desktop/wensa_app/wensa
flutter test --reporter=compact
```

Expected: all tests **PASS**, including the 9 new `discount_eligibility_test.dart` tests.

- [ ] **Step 2: If any test fails, fix the root cause before proceeding**

Do not skip or comment out tests. Read the failure message, identify which assertion is wrong, fix the code or the test (whichever is incorrect), and re-run.
