import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'favorites_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Favorites — Set<String> of favorited place IDs
//  Stored in Supabase `favorites` table (wain_flosi project)
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class Favorites extends _$Favorites {
  static final _db = Supabase.instance.client;

  @override
  Future<Set<String>> build() async {
    final user = _db.auth.currentUser;
    if (user == null) return {};

    final rows = await _db
        .from('favorites')
        .select('place_id, event_id')
        .eq('user_id', user.id);

    return (rows as List).expand((r) {
      final ids = <String>[];
      if (r['place_id'] != null) ids.add(r['place_id'] as String);
      if (r['event_id'] != null) ids.add(r['event_id'] as String);
      return ids;
    }).toSet();
  }

  bool isFavorited(String placeId) =>
      state.value?.contains(placeId) ?? false;

  /// Toggle favorite — works for both places and events
  /// itemType: 'place' (default) | 'event'
  Future<void> toggle(String itemId, {String itemType = 'place'}) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    final current = {...(state.value ?? {})};
    final wasLiked = current.contains(itemId);

    // Optimistic update
    if (wasLiked) {
      current.remove(itemId);
    } else {
      current.add(itemId);
    }
    state = AsyncData(current);

    try {
      if (!wasLiked) {
        // Add — use place_id or event_id based on type
        final row = itemType == 'event'
            ? {'user_id': user.id, 'event_id': itemId}
            : {'user_id': user.id, 'place_id': itemId};
        await _db.from('favorites').upsert(row);
      } else {
        // Remove
        final col = itemType == 'event' ? 'event_id' : 'place_id';
        await _db
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq(col, itemId);
      }
      ref.invalidate(favoritesFeedProvider);
    } catch (_) {
      ref.invalidateSelf();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FavoritesFeed — جلب الأماكن المفضلة كاملة من Supabase
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class FavoritesFeed extends _$FavoritesFeed {
  @override
  CategoryFeedState build() {
    Future.microtask(_load);
    return const CategoryFeedState();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = const CategoryFeedState(isLoading: false, hasMore: false);
      return;
    }

    state = const CategoryFeedState(isLoading: true);

    try {
      final rows = await Supabase.instance.client
          .from('favorites')
          .select(
            'place_id, event_id, places(id, name_en, name_ar, area, cover_image_url, is_verified), events(id, title_en, title_ar, subtitle_en, subtitle_ar, cover_image_url, is_verified)',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final items = (rows as List)
          .map((r) {
            final p = r['places'] as Map<String, dynamic>?;
            if (p != null) return CategoryFeedItem.fromRow(p);
            final e = r['events'] as Map<String, dynamic>?;
            if (e != null)
              return CategoryFeedItem.fromTrendingRow({...e, 'type': 'event'});
            return null;
          })
          .whereType<CategoryFeedItem>()
          .toList();

      state = CategoryFeedState(items: items, isLoading: false, hasMore: false);
    } catch (_) {
      state = const CategoryFeedState(
        isLoading: false,
        hasMore: false,
        hasError: true,
      );
    }
  }

  Future<void> refresh() async {
    state = const CategoryFeedState();
    await _load();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SeeAllType — نوع صفحة "عرض الكل"
// ─────────────────────────────────────────────────────────────────────────────
enum SeeAllType { trending, newOpenings }

// ─────────────────────────────────────────────────────────────────────────────
//  SeeAllFeed — paginated feed لـ See All pages
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class SeeAllFeed extends _$SeeAllFeed {
  static const _pageSize = 10;

  @override
  CategoryFeedState build(SeeAllType type) {
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

      final List rows;
      switch (type) {
        case SeeAllType.trending:
          rows = await Supabase.instance.client
              .from('trending_feed')
              .select(
                'id, title_en, title_ar, subtitle_en, subtitle_ar, cover_image_url, is_verified, type',
              )
              .order('hotness_score', ascending: false)
              .range(from, to);
        case SeeAllType.newOpenings:
          rows = await Supabase.instance.client
              .from('places')
              .select(
                'id, name_en, name_ar, area, cover_image_url, is_verified',
              )
              .eq('is_new', true)
              .order('created_at', ascending: false)
              .range(from, to);
      }

      final fetched = rows.map((r) {
        final m = r as Map<String, dynamic>;
        return type == SeeAllType.trending
            ? CategoryFeedItem.fromTrendingRow(m)
            : CategoryFeedItem.fromRow(m);
      }).toList();

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
