// lib/features/search/data/repositories/search_repository.dart

import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'search_repository.g.dart';

class SearchRepository {
  const SearchRepository(this._client);

  final SupabaseClient _client;

  /// Searches places + events whose AR or EN name contains [query].
  /// Results are limited to [limit] items per table (default 10 each = 20 max).
  Future<List<CategoryFeedItem>> search(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return [];

    final pattern = '%${query.trim()}%';

    // Run both queries concurrently
    final results = await Future.wait([
      _searchPlaces(pattern, limit),
      _searchEvents(pattern, limit),
    ]);

    // Places first, then events
    return [...results[0], ...results[1]];
  }

  Future<List<CategoryFeedItem>> _searchPlaces(
    String pattern,
    int limit,
  ) async {
    final rows = await _client
        .from('places')
        .select(
          'id, name_en, name_ar, area, city, cover_image_url, is_verified',
        )
        .or('name_en.ilike.$pattern,name_ar.ilike.$pattern')
        .limit(limit);

    return (rows as List)
        .map((r) => CategoryFeedItem.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryFeedItem>> _searchEvents(
    String pattern,
    int limit,
  ) async {
    final rows = await _client
        .from('events')
        .select('id, title_en, title_ar, city, cover_image_url')
        .or('title_en.ilike.$pattern,title_ar.ilike.$pattern')
        .limit(limit);

    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
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
    }).toList();
  }
}

@riverpod
SearchRepository searchRepository(Ref ref) =>
    SearchRepository(Supabase.instance.client);
