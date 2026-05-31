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
        .schema('profiles')
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
        await _db.schema('profiles').from('favorites').insert(row);
      } else {
        final col = itemType == 'event' ? 'event_id' : 'place_id';
        await _db
            .schema('profiles')
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

    // ── Favorites ordered by when they were added (newest first) ───────────
    final List favRows;
    try {
      favRows = await db
          .schema('profiles')
          .from('favorites')
          .select('place_id, event_id, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
    } catch (_) {
      state = const CategoryFeedState(
        isLoading: false,
        hasMore: false,
        hasError: true,
      );
      return;
    }

    final placeIds = <String>[];
    final eventIds = <String>[];
    for (final r in favRows) {
      final p = r['place_id'] as String?;
      final e = r['event_id'] as String?;
      if (p != null) placeIds.add(p);
      if (e != null) eventIds.add(e);
    }

    final placeById = <String, CategoryFeedItem>{};
    final eventById = <String, CategoryFeedItem>{};

    if (placeIds.isNotEmpty) {
      try {
        final places = await db
            .schema('content')
            .from('places_mobile')
            .select(
              'id, merchant_id, name_en, name_ar, area, area_ar, cover_image_url, logo_url, is_verified',
            )
            .inFilter('id', placeIds);
        for (final p in places as List) {
          final m = p as Map<String, dynamic>;
          placeById[m['id'] as String] = CategoryFeedItem.fromRow(m);
        }
      } catch (_) {
        state = const CategoryFeedState(
          isLoading: false,
          hasMore: false,
          hasError: true,
        );
        return;
      }
    }

    if (eventIds.isNotEmpty) {
      try {
        final events = await db
            .schema('content')
            .from('events_mobile')
            .select('id, title_en, title_ar, city, city_ar, cover_image_url, logo_url, is_verified')
            .inFilter('id', eventIds)
            .eq('event_status', 'approved');
        for (final e in events as List) {
          final m = e as Map<String, dynamic>;
          eventById[m['id'] as String] = CategoryFeedItem(
            id: m['id'] as String,
            titleEn: m['title_en'] as String? ?? '',
            titleAr: m['title_ar'] as String? ?? '',
            subtitleEn: m['city'] as String?,
            subtitleAr: (m['city_ar'] ?? m['city']) as String?,
            coverImageUrl: m['cover_image_url'] as String?,
            logoUrl: m['logo_url'] as String?,
            isVerified: m['is_verified'] as bool? ?? false,
            type: 'event',
          );
        }
      } catch (_) {
        // Events load failed — places still shown
      }
    }

    // Preserve the favorites order (newest → oldest) when assembling items.
    final items = <CategoryFeedItem>[];
    for (final r in favRows) {
      final p = r['place_id'] as String?;
      final e = r['event_id'] as String?;
      if (p != null) {
        final item = placeById[p];
        if (item != null) items.add(item);
      } else if (e != null) {
        final item = eventById[e];
        if (item != null) items.add(item);
      }
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
enum SeeAllType { trending, newOpenings, allEvents, featured }

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
              .schema('content')
              .from('trending_feed')
              .select(
                'id, merchant_id, title_en, title_ar, subtitle_en, subtitle_ar, cover_image_url, logo_url, is_verified, type',
              )
              .order('created_at', ascending: false)
              .range(from, to);
        case SeeAllType.newOpenings:
          rows = await Supabase.instance.client
              .schema('content')
              .from('places_mobile')
              .select(
                'id, merchant_id, name_en, name_ar, area, area_ar, cover_image_url, logo_url, is_verified',
              )
              .eq('is_new', true)
              .order('created_at', ascending: false)
              .range(from, to);
        case SeeAllType.allEvents:
          rows = await Supabase.instance.client
              .schema('content')
              .from('events_mobile')
              .select('id, title_en, title_ar, city, city_ar, cover_image_url, logo_url')
              .eq('event_status', 'approved')
              .or(
                'end_date.is.null,end_date.gt.${DateTime.now().toUtc().toIso8601String()}',
              )
              .order('created_at', ascending: false)
              .range(from, to);
        case SeeAllType.featured:
          rows = await Supabase.instance.client
              .schema('content')
              .from('trending_feed')
              .select(
                'id, merchant_id, title_en, title_ar, subtitle_en, subtitle_ar, cover_image_url, logo_url, is_verified, type',
              )
              .eq('is_featured', true)
              .order('hotness_score', ascending: false)
              .range(from, to);
      }

      final fetched = rows.map((r) {
        final m = r as Map<String, dynamic>;
        if (type == SeeAllType.trending || type == SeeAllType.featured) {
          return CategoryFeedItem.fromTrendingRow(m);
        }
        if (type == SeeAllType.allEvents) {
          return CategoryFeedItem(
            id: m['id'] as String,
            titleEn: m['title_en'] as String? ?? '',
            titleAr: m['title_ar'] as String? ?? '',
            subtitleEn: m['city'] as String?,
            subtitleAr: (m['city_ar'] ?? m['city']) as String?,
            coverImageUrl: m['cover_image_url'] as String?,
            logoUrl: m['logo_url'] as String?,
            type: 'event',
          );
        }
        return CategoryFeedItem.fromRow(m);
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
