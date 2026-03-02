import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'category_feed_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CategoryFeedItem
// ─────────────────────────────────────────────────────────────────────────────
class CategoryFeedItem {
  final String id;
  final String titleEn;
  final String titleAr;
  final String? subtitleEn;
  final String? subtitleAr;
  final String? coverImageUrl;
  final bool isVerified;
  final String type; // 'place' | 'event'

  const CategoryFeedItem({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    this.subtitleEn,
    this.subtitleAr,
    this.coverImageUrl,
    this.isVerified = false,
    required this.type,
  });

  factory CategoryFeedItem.fromPlace(Map<String, dynamic> m) =>
      CategoryFeedItem(
        id: m['id'] as String,
        titleEn: m['name_en'] as String? ?? '',
        titleAr: m['name_ar'] as String? ?? '',
        subtitleEn: m['area'] as String?,
        subtitleAr: m['area'] as String?,
        coverImageUrl: m['cover_image_url'] as String?,
        isVerified: m['is_verified'] as bool? ?? false,
        type: 'place',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  CategoryFeedState
// ─────────────────────────────────────────────────────────────────────────────
class CategoryFeedState {
  final List<CategoryFeedItem> items;
  final bool isLoading;
  final bool hasMore;
  final int page;

  const CategoryFeedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
  });

  CategoryFeedState copyWith({
    List<CategoryFeedItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) => CategoryFeedState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SelectedCategory — starts at null (nothing selected)
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  int? build() => null; // ✅ null = no category selected by default

  void select(int index) {
    // Tap same category → deselect; tap different → select
    state = state == index ? null : index;
  }

  void clear() => state = null;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CategoryFeed — autoDispose family, one per categoryId
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class CategoryFeed extends _$CategoryFeed {
  static const _pageSize = 10;
  final _db = Supabase.instance.client;

  @override
  CategoryFeedState build(String categoryId) {
    // Kick off first page after the frame
    Future.microtask(loadMore);
    return const CategoryFeedState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final from = state.page * _pageSize;
      final to = from + _pageSize - 1;

      final rows = await _db
          .from('places')
          .select('id, name_en, name_ar, area, cover_image_url, is_verified')
          .eq('category_id', categoryId)
          .order('hotness_score', ascending: false)
          .range(from, to);

      final fetched = (rows as List)
          .map((r) => CategoryFeedItem.fromPlace(r as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...fetched],
        isLoading: false,
        hasMore: fetched.length == _pageSize,
        page: state.page + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  Future<void> refresh() async {
    state = const CategoryFeedState();
    await loadMore();
  }
}
