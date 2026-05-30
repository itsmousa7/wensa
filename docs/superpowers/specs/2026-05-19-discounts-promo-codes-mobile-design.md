# Discounts & Promo Codes — Mobile Integration

**Status:** Approved (pending spec review)
**Owner:** mobile
**Backend reference:** `docs/discounts-mobile-integration-prompt.md` in the admin dashboard repo.

## Goal

Surface the platform-level automatic discounts (`business.discounts`) on listings and place details, and let users apply promo codes (`business.promo_codes`) during checkout — with a clear subtotal/discount/final breakdown.

Out of scope: concerts (events don't carry a merchant/category we can scope against, and per product call discounts don't apply to them); merchant-side purchases (subscriptions/banners) — they're a separate dashboard pass.

## Backend contract (already in place)

| Endpoint | Use |
|----------|-----|
| `GET /rest/v1/discounts?is_active=eq.true` (header `Accept-Profile: business`) | List active automatic discounts. Client picks the best applicable per place/booking. |
| RPC `preview_promo_code` | Validate a code + compute discount before submit. Returns `{ valid, reason, percent, discount_amount, final_amount, promo_code_id }`. |
| Edge fns `create-booking` / `create-membership` | Already accept `promo_code` in the body and call `redeem_promo_code` server-side after the order row is created. Mobile sends the code uppercased; redemption is authoritative. |

Discount/code apply when **all** hold:
- `is_active = true` and `now()` within `starts_at` / `ends_at`.
- Purchase type ∈ `applies_to`.
- `scope_type='app'` OR (`scope_type='targeted'` and the purchase's `category_id` / `merchant_id` / `place_id` is in one of the target arrays).

Discount math: `discount = round(amount * percent / 100)`, then `if max_discount_amount != null and discount > max: discount = max`. Pick the single largest `percent` — never stack. Promo code **replaces** the auto-discount when applied.

## Architecture

### 1. Domain layer — `lib/features/discounts/`

**New model** `AutoDiscount` (`domain/models/auto_discount.dart`):

```
id, name, description, percent, maxDiscountAmount, appliesTo (List<String>),
scopeType ('app'|'targeted'), targetCategoryIds, targetMerchantIds, targetPlaceIds,
startsAt, endsAt, isActive
```

with `appliesToOrder({orderType, placeId, merchantId, categoryId})` returning bool. Date-window check uses `DateTime.now()`.

**Repository** `AutoDiscountsRepository` (`data/auto_discounts_repository.dart`):
- `fetchActive()` — `client.schema('business').from('discounts').select().eq('is_active', true)`.

Keep existing `MerchantDiscountsRepository` untouched (separate older feature; out of scope to remove).

### 2. Providers

`autoDiscountsProvider` — `FutureProvider<List<AutoDiscount>>`, cached for the app session.

`bestAutoDiscountProvider` — `Provider.family<AutoDiscount?, AutoDiscountKey>` where `AutoDiscountKey` carries `(orderType, placeId, merchantId, categoryId)`. Returns the single discount with the largest `percent` whose `appliesToOrder` is true. Result is the full object (we need `maxDiscountAmount` at checkout).

`userPurchaseHistoryProvider` — `FutureProvider<PurchaseHistory>`, computed once per session:
```
PurchaseHistory { hasAnyOrder, hasBooking, hasMembership, hasSubscription }
```
Implementation: `select count` against `bookings` and `memberships` for `auth.uid()`. Invalidated after a successful order completion (hook into the existing success path that already invalidates `bookingsRefreshProvider`).

Helper `computeDiscount(int amount, double percent, num? maxCap)` → `(int discountAmount, int finalAmount)`. Rounds to int (matches the IQD currency convention used in `_formatPrice`).

### 3. Card badge (already wired) — minor extension

In `lib/core/widgets/full_width_feed_card.dart` and `lib/features/home/presentation/widgets/feed_card.dart`:
- Today: `resolvedDiscountPercent` reads `bestDiscountPercentProvider` (merchant_discounts).
- Change: take `max(merchantPercent ?? 0, autoDiscount?.percent ?? 0)` so either system surfaces a badge. No UI change.

Cards on event listings remain unchanged (events excluded).

### 4. Place details badge

In `lib/features/places/presentation/widgets/place_info_section.dart`, location chip block:
- After the chip widget, in the same `Row`, append a `Gap(8)` + `DiscountBadge(percent: best.percent)` when `bestAutoDiscountProvider({orderType: 'bookings', placeId, merchantId: place.merchantId, categoryId: place.categoryId})` is non-null.
- Wrap inside `Wrap` so it falls below on narrow screens instead of overflowing.

### 5. Promo-code widget — `lib/features/discounts/presentation/widgets/promo_code_field.dart`

```
PromoCodeField({
  required String orderType,        // 'bookings' | 'memberships'
  required int subtotal,
  required String? placeId,
  required String? merchantId,
  required String? categoryId,
  required ValueChanged<PromoApplied?> onChange,
})
```

Internal state via a local `StateNotifier` (auto-disposed):
- `PromoCodeState.idle`
- `PromoCodeState.loading`
- `PromoCodeState.applied(PromoApplied { code, percent, discountAmount, finalAmount, promoCodeId })`
- `PromoCodeState.error(String message)`

Apply flow:
1. Read user's `PurchaseHistory` via `ref.read(userPurchaseHistoryProvider.future)`.
2. `final code = controller.text.trim().toUpperCase();`
3. Call `client.schema('business').rpc('preview_promo_code', params: { p_code: code, p_order_type: orderType, p_amount: subtotal, p_category_id: categoryId, p_merchant_id: merchantId, p_place_id: placeId, p_is_first_purchase: !history.hasOrderOfType(orderType), p_is_new_customer: !history.hasAnyOrder })`.
4. On `valid: true` → transition to `applied`, fire `onChange`, lock the field (read-only + × remove button).
5. On `valid: false` → map `reason` to a localized message (`not_found` → "Code not found", `expired` → "This code expired", `not_first_purchase` → "Only valid on first purchase", etc.).

Whenever subtotal / placeId / categoryId changes, the parent invalidates by passing a new key — the widget re-runs preview if a code is currently applied and either keeps it (with new amounts) or transitions to `error` and notifies parent to drop it.

### 6. Order summary changes

Extend `BookingSummaryCard` to accept optional discount breakdown:
```
int? subtotal;          // pre-discount; if null, falls back to totalValue display
int? discountAmount;    // pretty-printed below subtotal
String? discountLabel;  // "10% OFF" or "Promo SUMMER25 (25% OFF)"
int? finalTotal;        // shown as the prominent total when set
```

Render rules:
- No discount → unchanged from today.
- Discount present → render three rows: `Subtotal` (struck through), `Discount (label)` in red showing `−IQD X`, `Total` (the bold pill currently used) showing `IQD Y`.
- Action button label/behavior unchanged.

### 7. Wiring per booking section

For each section, the wiring pattern is identical:

```dart
final auto = ref.watch(bestAutoDiscountProvider(key));
final promo = ref.watch(_promoProvider);   // local per-section StateProvider<PromoApplied?>
final subtotal = computeSubtotal(...);     // existing logic, returning int
final effective = promo != null
    ? (promo.discountAmount, promo.finalAmount, 'Promo ${promo.code}')
    : auto != null
        ? computeDiscount(subtotal, auto.percent, auto.maxDiscountAmount)
              .let((d, f) => (d, f, '${auto.percent.round()}% OFF'))
        : (0, subtotal, null);

BookingSummaryCard(
  ...,
  subtotal: subtotal,
  discountAmount: effective.$1 > 0 ? effective.$1 : null,
  discountLabel: effective.$3,
  finalTotal: effective.$2,
  ...
)
```

Promo field is placed **above** the summary card (or inside, just above the action button) — visible only when `subtotal > 0`.

On action tap, pass `promoCode: promo?.code` to the submit provider.

#### Sections affected
- `padel_section.dart` — subtotal = `pricePerHour * hours`, orderType `bookings`.
- `farm_section.dart` — subtotal = `shift.price`, orderType `bookings`.
- `restaurant_section.dart` — subtotal = computed total when paid; hide promo when 0.
- `membership_section.dart` — subtotal = `plan.price`, orderType `memberships`.
- `concert_section.dart` — **no change** (discounts/promos disabled for events).

### 8. Submit provider changes

`BookingSubmit` methods (`createPadelBooking`, `createFarmBooking`, `createRestaurantBooking`) and `MembershipSubmit.createMembership` get an optional named param `String? promoCode`. When non-null, included in the edge-function body as `promo_code` (already uppercased by the field). No change to success/error handling — `redeem_promo_code` runs inside the edge function and the final charged amount is authoritative on the server side.

`BookingSubmit.createConcertBooking` is unchanged — events are out of scope.

### 9. Error message map

```
not_authenticated  → "Please sign in to use a code"
not_found          → "Code not found"
inactive           → "This code is no longer active"
not_started        → "This code isn't valid yet"
expired            → "This code has expired"
wrong_order_type   → "This code can't be used here"
not_first_purchase → "Only valid on first purchase"
not_new_customer   → "Only valid for new customers"
out_of_scope       → "This code doesn't apply to this place"
limit_reached      → "This code has reached its limit"
user_limit_reached → "You've already used this code"
```

Arabic translations follow the same keys (handled inline since the codebase uses inline ternaries on `isAr`).

## Files

**New:**
- `lib/features/discounts/domain/models/auto_discount.dart`
- `lib/features/discounts/data/auto_discounts_repository.dart`
- `lib/features/discounts/presentation/providers/auto_discounts_provider.dart`
- `lib/features/discounts/presentation/providers/user_purchase_history_provider.dart`
- `lib/features/discounts/presentation/widgets/promo_code_field.dart`
- `lib/features/discounts/domain/discount_math.dart` (helper)

**Modified:**
- `lib/features/discounts/presentation/providers/merchant_discounts_provider.dart` — keep, extend `bestDiscountPercentProvider` to merge merchant + auto.
- `lib/core/widgets/full_width_feed_card.dart` — no logic change (uses merged provider).
- `lib/features/home/presentation/widgets/feed_card.dart` — same.
- `lib/features/places/presentation/widgets/place_info_section.dart` — add badge inline beside location chip.
- `lib/features/booking/presentation/widgets/booking_summary_card.dart` — add optional `subtotal` / `discountAmount` / `discountLabel` / `finalTotal` props.
- `lib/features/booking/presentation/sections/{padel,farm,restaurant,membership}_section.dart` — wire promo field + discount math.
- `lib/features/booking/presentation/providers/booking_submit_provider.dart` — accept optional `promoCode`.
- `lib/features/booking/presentation/providers/membership_submit_provider.dart` — accept optional `promoCode`.

## Edge cases

- **Cap (`max_discount_amount`)**: applied client-side for display only; the RPC also enforces it, and the edge function recomputes server-side at redemption time. We trust `discount_amount` / `final_amount` from `preview_promo_code` directly.
- **Subtotal changes after Apply** (e.g. user toggles a slot in padel): re-run `preview_promo_code` with the new amount. If it now fails (e.g. amount dropped below a threshold the code didn't actually have, or another reason), drop the promo and surface the new error.
- **Date/place/category change**: same — re-run preview; on failure drop.
- **Restaurant free reservation (subtotal = 0)**: hide both the badge math and the promo field. The "Subtotal/Discount/Total" block in the summary card collapses to its current single-row behavior.
- **No auto-discount applies for this place**: card and details badge hidden; promo field still shown so the user can try a code.
- **Two auto-discounts match**: pick max percent. Cap is taken from that same row.

## Testing

- Unit: `discount_math.dart` — cap clamping, zero amounts, integer rounding.
- Unit: `AutoDiscount.appliesToOrder` — app vs targeted, expiry windows, applies_to filter.
- Integration (manual): apply a real code on each of the four flows; verify subtotal/discount/total display, verify the code arrives uppercased in the edge function logs, verify `uses_count` increments.

## Acceptance checklist

- [ ] Place card badge shows for places with an active applicable auto-discount (driven by either merchant_discounts or business.discounts, whichever is larger).
- [ ] Place details page shows the same badge beside the location chip.
- [ ] Padel, farm, restaurant (paid only), and membership checkouts show the promo field; concerts do not.
- [ ] Order summary shows subtotal struck through + discount line + final total whenever any discount applies.
- [ ] Promo code is uppercased before being sent to `preview_promo_code` and to the create-* edge function body.
- [ ] All `reason` values from the RPC map to a user-visible message in EN and AR.
- [ ] Eligibility flags are computed once per session and invalidated after a successful order.
- [ ] When subtotal changes after a code is applied, preview re-runs and either updates amounts or drops the code with a message.
