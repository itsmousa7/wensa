
import 'package:future_riverpod/features/home/models/category_model.dart';
import 'package:future_riverpod/features/places/domain/models/event_model.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/home/models/promoted_banner.dart';
import 'package:future_riverpod/features/places/domain/models/trending_feed_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeRepository {
  final SupabaseClient _supabase;
  const HomeRepository(this._supabase);

  // ── 1. Hot Events ─────────────────────────────────────────────────────────
  // جلب أعلى 5 أحداث بالـ hotness_score من جدول events
  Future<List<EventModel>> getHotEvents() async {
    final data = await _supabase
        .from('events')
        .select()
        .order('hotness_score', ascending: false)
        .limit(5);

    return data.map((e) => EventModel.fromJson(e)).toList();
  }

  // ── 2. Trending Feed (places + events mixed) ───────────────────────────────
  // يجلب من الـ View اللي بنيناه في Supabase — يدمج الأماكن والأحداث تلقائياً
  Future<List<TrendingFeedItemModel>> getTrendingFeed() async {
    final data = await _supabase
        .from('trending_feed')
        .select()
        .limit(10);

    return data.map((e) => TrendingFeedItemModel.fromJson(e)).toList();
  }

  // ── 3. New Openings ────────────────────────────────────────────────────────
  // أماكن is_new = true مرتبة من الأحدث للأقدم
  Future<List<PlaceModel>> getNewOpenings() async {
    final data = await _supabase
        .from('places')
        .select()
        .eq('is_new', true)
        .order('created_at', ascending: false)
        .limit(10);

    return data.map((e) => PlaceModel.fromJson(e)).toList();
  }

  // ── 4. Promoted Banners ────────────────────────────────────────────────────
  // RLS في Supabase تفلتر تلقائياً — ترجع فقط الـ banners الـ active ضمن التاريخ
  Future<List<PromotedBannerModel>> getPromotedBanners() async {
    final data = await _supabase
        .from('promoted_banners')
        .select('*, places(name_ar, name_en, area)')
        .order('created_at', ascending: false);

    return data.map((e) => PromotedBannerModel.fromJson(e)).toList();
  }

  // ── 5. Categories ──────────────────────────────────────────────────────────
  Future<List<CategoryModel>> getCategories() async {
    final data = await _supabase
        .from('categories')
        .select()
        .order('name_en');

    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }
}