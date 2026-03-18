import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'favorites_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Favorites — Set<String> of ALL favorited IDs (places + events)
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

    return (rows as List).expand<String>((r) {
      final ids = <String>[];
      final p = r['place_id'] as String?;
      final e = r['event_id'] as String?;
      if (p != null) ids.add(p);
      if (e != null) ids.add(e);
      return ids;
    }).toSet();
  }

  bool isFavorited(String id) => state.value?.contains(id) ?? false;

  Future<void> toggle(String itemId, {String itemType = 'place'}) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    final current = {...(state.value ?? {})};
    final wasLiked = current.contains(itemId);

    // 1️⃣ Optimistic favorites update (icon)
    if (wasLiked) {
      current.remove(itemId);
    } else {
      current.add(itemId);
    }
    state = AsyncData(current);

    // 2️⃣ Optimistic savesCount update (counter) ← NEW
    if (itemType == 'place') {
      ref
          .read(placeDetailsProvider(itemId).notifier)
          .patchSavesCount(wasLiked ? -1 : 1);
    } else if (itemType == 'event') {
      ref
          .read(eventDetailsProvider(itemId).notifier)
          .patchSavesCount(wasLiked ? -1 : 1);
    }

    try {
      if (!wasLiked) {
        final row = itemType == 'event'
            ? {'user_id': user.id, 'event_id': itemId}
            : {'user_id': user.id, 'place_id': itemId};
        await _db.from('favorites').insert(row);
      } else {
        final col = itemType == 'event' ? 'event_id' : 'place_id';
        await _db
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq(col, itemId);
      }
      ref.invalidate(favoritesFeedProvider);
    } catch (_) {
      // Roll back both on error
      ref.invalidateSelf();
      if (itemType == 'place') {
        ref
            .read(placeDetailsProvider(itemId).notifier)
            .patchSavesCount(wasLiked ? 1 : -1);
      } else if (itemType == 'event') {
        ref
            .read(eventDetailsProvider(itemId).notifier)
            .patchSavesCount(wasLiked ? 1 : -1);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FavoritesFeed
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class FavoritesFeed extends _$FavoritesFeed {
  @override
  CategoryFeedState build() {
    Future.microtask(_load);
    return const CategoryFeedState();
  }

  Future<void> _load() async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;

    if (user == null) {
      state = const CategoryFeedState(isLoading: false, hasMore: false);
      return;
    }

    state = const CategoryFeedState(isLoading: true);

    final items = <CategoryFeedItem>[];

    // ── Places ───────────────────────────────────────────────────────────────
    try {
      final placeRows = await db
          .from('favorites')
          .select('place_id')
          .eq('user_id', user.id)
          .not('place_id', 'is', null);

      final placeIds = (placeRows as List)
          .map((r) => r['place_id'] as String?)
          .whereType<String>()
          .toList();

      if (placeIds.isNotEmpty) {
        final places = await db
            .from('places')
            .select('id, name_en, name_ar, area, cover_image_url, is_verified')
            .inFilter('id', placeIds);

        items.addAll(
          (places as List).map(
            (p) => CategoryFeedItem.fromRow(p as Map<String, dynamic>),
          ),
        );
      }
    } catch (_) {
      state = const CategoryFeedState(
        isLoading: false,
        hasMore: false,
        hasError: true,
      );
      return;
    }

    // ── Events ───────────────────────────────────────────────────────────────
    // events table columns: id, title_en, title_ar, city, cover_image_url
    // subtitle_en / subtitle_ar do NOT exist on events — use city instead
    try {
      final eventRows = await db
          .from('favorites')
          .select('event_id')
          .eq('user_id', user.id)
          .not('event_id', 'is', null);

      final eventIds = (eventRows as List)
          .map((r) => r['event_id'] as String?)
          .whereType<String>()
          .toList();

      if (eventIds.isNotEmpty) {
        // ✅ Only select columns that actually exist on the events table
        final events = await db
            .from('events')
            .select('id, title_en, title_ar, city, cover_image_url')
            .inFilter('id', eventIds);

        items.addAll(
          (events as List).map((e) {
            final m = e as Map<String, dynamic>;
            // Map city → subtitle since events have no subtitle_en/ar column
            return CategoryFeedItem(
              id: m['id'] as String,
              titleEn: m['title_en'] as String? ?? '',
              titleAr: m['title_ar'] as String? ?? '',
              subtitleEn: m['city'] as String?,
              subtitleAr: m['city'] as String?,
              coverImageUrl: m['cover_image_url'] as String?,
              isVerified: false,
              type: 'event',
            );
          }),
        );
      }
    } catch (_) {
      // Events load failed — places already in list, still show them
    }

    state = CategoryFeedState(items: items, isLoading: false, hasMore: false);
  }

  Future<void> refresh() async {
    state = const CategoryFeedState();
    await _load();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SeeAllType
// ─────────────────────────────────────────────────────────────────────────────
enum SeeAllType { trending, newOpenings, allEvents }

// ─────────────────────────────────────────────────────────────────────────────
//  SeeAllFeed
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
        case SeeAllType.allEvents:
          rows = await Supabase.instance.client
              .from('events')
              .select('id, title_en, title_ar, city, cover_image_url')
              .order('hotness_score', ascending: false)
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
