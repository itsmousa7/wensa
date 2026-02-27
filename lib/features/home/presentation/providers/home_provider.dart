import 'package:future_riverpod/features/home/domain/repositories/home_repository.dart';
import 'package:future_riverpod/features/home/models/category_model.dart';
import 'package:future_riverpod/features/places/domain/models/event_model.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/home/models/promoted_banner.dart';
import 'package:future_riverpod/features/places/domain/models/trending_feed_item_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'home_provider.g.dart';
// ── Repository ────────────────────────────────────────────────────────────────
// instance 
@riverpod
HomeRepository homeRepository(Ref ref) {
  return HomeRepository(Supabase.instance.client);
}

// ── Hot Events ────────────────────────────────────────────────────────────────
@riverpod
Future<List<EventModel>> hotEvents(Ref ref) {
  return ref.read(homeRepositoryProvider).getHotEvents();
}

// ── Trending Feed (places + events mixed) ─────────────────────────────────────
@riverpod
Future<List<TrendingFeedItemModel>> trendingFeed(Ref ref) {
  return ref.read(homeRepositoryProvider).getTrendingFeed();
}

// ── New Openings ──────────────────────────────────────────────────────────────
@riverpod
Future<List<PlaceModel>> newOpenings(Ref ref) {
  return ref.read(homeRepositoryProvider).getNewOpenings();
}

// ── Promoted Banners ──────────────────────────────────────────────────────────
@riverpod
Future<List<PromotedBannerModel>> promotedBanners(Ref ref) {
  return ref.read(homeRepositoryProvider).getPromotedBanners();
}

// ── Categories ────────────────────────────────────────────────────────────────
@riverpod
Future<List<CategoryModel>> categories(Ref ref) {
  return ref.read(homeRepositoryProvider).getCategories();
}

// ── Selected Category Index ───────────────────────────────────────────────────
// State بسيط للـ category المختارة في الـ UI
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  int build() => 0; // الأولى مختارة افتراضياً

  void select(int index) => state = index;
}