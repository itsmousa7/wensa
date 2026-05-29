import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:future_riverpod/features/discounts/domain/models/auto_discount.dart';
import 'package:future_riverpod/features/discounts/domain/models/merchant_discount.dart';

part 'category_feed_provider.g.dart';

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

// ─────────────────────────────────────────────────────────────────────────────
//  CategoryFeedItem
// ─────────────────────────────────────────────────────────────────────────────
class CategoryFeedItem {
  final String id;
  final String? merchantId;
  final String titleEn;
  final String titleAr;
  final String? subtitleEn;
  final String? subtitleAr;
  final String? coverImageUrl;
  final String? logoUrl;
  final bool isVerified;
  final String type; // 'place' | 'event'

  const CategoryFeedItem({
    required this.id,
    this.merchantId,
    required this.titleEn,
    required this.titleAr,
    this.subtitleEn,
    this.subtitleAr,
    this.coverImageUrl,
    this.logoUrl,
    this.isVerified = false,
    this.type = 'place',
  });

  /// From places table (name_en / name_ar)
  factory CategoryFeedItem.fromRow(Map<String, dynamic> m) => CategoryFeedItem(
    id: m['id'] as String,
    merchantId: m['merchant_id'] as String?,
    titleEn: m['name_en'] as String? ?? '',
    titleAr: m['name_ar'] as String? ?? '',
    subtitleEn: m['area'] as String?,
    subtitleAr: m['area'] as String?,
    coverImageUrl: m['cover_image_url'] as String?,
    logoUrl: m['logo_url'] as String?,
    isVerified: m['is_verified'] as bool? ?? false,
    type: 'place',
  );

  /// From trending_feed view (title_en / title_ar)
  factory CategoryFeedItem.fromTrendingRow(Map<String, dynamic> m) =>
      CategoryFeedItem(
        id: m['id'] as String,
        merchantId: m['merchant_id'] as String?,
        titleEn: m['title_en'] as String? ?? '',
        titleAr: m['title_ar'] as String? ?? '',
        subtitleEn: m['subtitle_en'] as String?,
        subtitleAr: m['subtitle_ar'] as String?,
        coverImageUrl: m['cover_image_url'] as String?,
        logoUrl: m['logo_url'] as String?,
        isVerified: m['is_verified'] as bool? ?? false,
        type: m['type'] as String? ?? 'place',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  CategoryFeedState
// ─────────────────────────────────────────────────────────────────────────────
class CategoryFeedState {
  final List<CategoryFeedItem> items;
  final bool isLoading;
  final bool hasMore;
  final bool hasError; // ✅ BUG 2 FIX: نتتبع الـ error بشكل صريح
  final int page;

  const CategoryFeedState({
    this.items = const [],
    this.isLoading = true, // ← true عند البداية حتى يظهر skeleton
    this.hasMore = true,
    this.hasError = false,
    this.page = 0,
  });

  CategoryFeedState copyWith({
    List<CategoryFeedItem>? items,
    bool? isLoading,
    bool? hasMore,
    bool? hasError,
    int? page,
  }) => CategoryFeedState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    hasError: hasError ?? this.hasError,
    page: page ?? this.page,
  );

  // ── Convenience getters ────────────────────────────────────────────────────
  bool get isEmpty => items.isEmpty && !isLoading && !hasError;
  bool get isFirstLoad => items.isEmpty && isLoading;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CategoryFeedNotifier — ✅ BUG 3: Riverpod Generator
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class CategoryFeed extends _$CategoryFeed {
  static const _pageSize = 10;

  @override
  CategoryFeedState build(String categoryId) {
    // نشغّل الـ loadMore بعد أول build مباشرة
    Future.microtask(loadMore);
    return const CategoryFeedState(); // isLoading = true
  }

  Future<void> loadMore() async {
    if (state.isLoading && state.page > 0) return; // منع تكرار
    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final from = state.page * _pageSize;
      final to = from + _pageSize - 1;

      final rows = await Supabase.instance.client
          .schema('content')
          .from('places_mobile')
          .select('id, merchant_id, name_en, name_ar, area, cover_image_url, logo_url, is_verified')
          .eq('place_status', 'approved')
          .eq('category_id', categoryId)
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
    } catch (e) {
      // ✅ BUG 2 FIX: نحفظ الـ error في state بدل crash
      state = state.copyWith(isLoading: false, hasMore: false, hasError: true);
    }
  }

  Future<void> refresh() async {
    state = const CategoryFeedState();
    await loadMore();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AllPlacesFeed — نفس CategoryFeed لكن بدون فلتر category
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class AllPlacesFeed extends _$AllPlacesFeed {
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
      final from = state.page * _pageSize;
      final to = from + _pageSize - 1;

      final rows = await Supabase.instance.client
          .schema('content')
          .from('places_mobile')
          .select('id, merchant_id, name_en, name_ar, area, cover_image_url, logo_url, is_verified')
          .eq('place_status', 'approved')
          .order('created_at', ascending: false)
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
