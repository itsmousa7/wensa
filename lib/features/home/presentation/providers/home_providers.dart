import 'package:future_riverpod/features/home/domain/repositories/home_repository.dart';
import 'package:future_riverpod/features/home/models/category_model.dart';
import 'package:future_riverpod/features/home/models/promoted_banner.dart';
import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/home/models/trending_feed_item_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'home_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────────
@riverpod
HomeRepository homeRepository(Ref ref) {
  return HomeRepository(Supabase.instance.client);
}

// ── Hot Events ────────────────────────────────────────────────────────────────
@riverpod
Future<List<EventModel>> hotEvents(Ref ref) {
  return ref.read(homeRepositoryProvider).getHotEvents();
}

// ── Trending Feed ─────────────────────────────────────────────────────────────
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

// ── Selected Category ─────────────────────────────────────────────────────────
// ✅ BUG 1 FIX: int? بدل int — null = لا يوجد اختيار افتراضياً
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  int? build() => null; // ← null يعني لا فئة مختارة

  void select(int index) {
    // نفس الفئة مرة ثانية → deselect (يرجع null)
    if (state == index) {
      state = null;
    } else {
      state = index;
    }
  }

  void clear() => state = null;
}
