import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/presentation/providers/supabase_provider.dart';
import 'package:future_riverpod/features/discounts/data/auto_discounts_repository.dart';
import 'package:future_riverpod/features/discounts/data/merchant_discounts_repository.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/domain/models/merchant_discount.dart';

final merchantDiscountsRepositoryProvider =
    Provider<MerchantDiscountsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return MerchantDiscountsRepository(client);
});

final merchantDiscountsProvider =
    FutureProvider<List<MerchantDiscount>>((ref) async {
  final repo = ref.watch(merchantDiscountsRepositoryProvider);
  return repo.fetchActive();
});

class PlaceDiscountKey {
  const PlaceDiscountKey({required this.placeId, this.merchantId});
  final String placeId;
  final String? merchantId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceDiscountKey &&
          other.placeId == placeId &&
          other.merchantId == merchantId;

  @override
  int get hashCode => Object.hash(placeId, merchantId);
}

/// Returns the best applicable [MerchantDiscount] for the given place
/// (largest percent, currently within the validity window). Returns null
/// when no merchant discount matches.
final placeMerchantDiscountProvider =
    Provider.family<MerchantDiscount?, PlaceDiscountKey>((ref, key) {
  final list = ref.watch(merchantDiscountsProvider).value;
  if (list == null) return null;
  MerchantDiscount? best;
  for (final d in list) {
    if (!d.isCurrentlyActive()) continue;
    if (!d.appliesToPlace(placeId: key.placeId, merchantId: key.merchantId)) {
      continue;
    }
    if (best == null || d.percent > best.percent) best = d;
  }
  return best;
});

/// Returns the best applicable percent for the given place (largest percent,
/// ignoring the hours window — that's evaluated at checkout). Returns null
/// when no discount matches.
final bestDiscountPercentProvider =
    Provider.family<int?, PlaceDiscountKey>((ref, key) {
  double best = 0;

  final merchant = ref.watch(merchantDiscountsProvider).value;
  if (merchant != null) {
    for (final d in merchant) {
      if (!d.isCurrentlyActive()) continue;
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
      // categoryId not known at the listing level — null is fine for
      // app-scope and merchant-scope rules.
    ),
  ));
  if (auto != null && auto.percent > best) best = auto.percent;

  return best > 0 ? best.round() : null;
});

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
    )) { continue; }
    if (best == null || d.percent > best.percent) { best = d; }
  }
  return best;
});
