import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'all_events_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  allEventsProvider
//  Fetches the first 20 events for the inline horizontal row.
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
Future<List<EventModel>> allEvents(Ref ref) async {
  final rows = await Supabase.instance.client
      .from('events')
      .select()
      .order('hotness_score', ascending: false)
      .limit(20);

  return (rows as List)
      .map((r) => EventModel.fromJson(r as Map<String, dynamic>))
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
//  AllEventsSeeAll
//  Uses CategoryFeedState so FeedListSection works without any changes.
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
class AllEventsSeeAll extends _$AllEventsSeeAll {
  static const int _pageSize = 20;

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
          .from('events')
          .select()
          .order('hotness_score', ascending: false)
          .range(from, to);

      final fetched = (rows as List)
          .map((r) => EventModel.fromJson(r as Map<String, dynamic>))
          .map(
            (e) => CategoryFeedItem(
              id: e.id,
              titleEn: e.titleEn,
              titleAr: e.titleAr,
              subtitleEn: e.city,
              subtitleAr: e.city,
              coverImageUrl: e.coverImageUrl,
              type: 'event',
            ),
          )
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
