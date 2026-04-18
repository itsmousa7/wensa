import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:future_riverpod/features/home/models/category_model.dart';
import 'package:future_riverpod/features/home/models/promoted_banner.dart';
import 'package:future_riverpod/features/home/models/trending_feed_item_model.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeRepository {
  final SupabaseClient _supabase;
  const HomeRepository(this._supabase);

  // ── 1. Hot Events ─────────────────────────────────────────────────────────
  // جلب أعلى 5 أحداث بالـ hotness_score من جدول events
  Future<List<EventModel>> getHotEvents() async {
    final data = await _supabase
        .schema('content')
        .from('events_mobile')
        .select()
        .eq('event_status', 'approved')
        .or(
          'end_date.is.null,end_date.gt.${DateTime.now().toUtc().toIso8601String()}',
        )
        .order('created_at', ascending: false)
        .limit(5);

    return data.map((e) => EventModel.fromJson(e)).toList();
  }

  // ── 2. Trending Feed (places + events mixed) ───────────────────────────────
  // يجلب من الـ View اللي بنيناه في Supabase — يدمج الأماكن والأحداث تلقائياً
  // مرتب من الأعلى hotness_score للأدنى
  Future<List<TrendingFeedItemModel>> getTrendingFeed() async {
    final data = await _supabase
        .schema('content')
        .from('trending_feed')
        .select()
        .order('hotness_score', ascending: false)
        .limit(10);

    return data.map((e) => TrendingFeedItemModel.fromJson(e)).toList();
  }

  // ── 3. New Openings ────────────────────────────────────────────────────────
  // أماكن is_new = true مرتبة من الأحدث للأقدم
  Future<List<PlaceModel>> getNewOpenings() async {
    final data = await _supabase
        .schema('content')
        .from('places_mobile')
        .select()
        .eq('place_status', 'approved')
        .eq('is_new', true)
        .order('created_at', ascending: false)
        .limit(10);

    return data.map((e) => PlaceModel.fromJson(e)).toList();
  }

  // ── 4. Promoted Banners ────────────────────────────────────────────────────
  // RLS في Supabase تفلتر تلقائياً — ترجع فقط الـ banners الـ active ضمن التاريخ
  Future<List<PromotedBannerModel>> getPromotedBanners() async {
    final data = await _supabase
        .schema('business')
        .from('promoted_banners_full')
        .select()
        .order('created_at', ascending: false);

    return data.map((e) => PromotedBannerModel.fromJson(e)).toList();
  }

  // ── 5. Categories ──────────────────────────────────────────────────────────
  Future<List<CategoryModel>> getCategories() async {
    final data = await _supabase
        .schema('content')
        .from('categories')
        .select()
        .order('name_en');

    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }

  // ── 6. Featured Feed (places + events mixed) ──────────────────────────────
  // يجلب من الـ trending_feed view — مفلتر بـ is_featured = true
  // مرتب من الأحدث للأقدم
  Future<List<TrendingFeedItemModel>> getFeaturedFeed() async {
    final data = await _supabase
        .schema('content')
        .from('trending_feed')
        .select()
        .eq('is_featured', true)
        .order('created_at', ascending: false)
        .limit(10);

    return data.map((e) => TrendingFeedItemModel.fromJson(e)).toList();
  }

  Future<List<EventModel>> getAllEvents({int limit = 20}) async {
    final rows = await _supabase
        .schema('content')
        .from('events_mobile')
        .select()
        .eq('event_status', 'approved')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((r) => EventModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
