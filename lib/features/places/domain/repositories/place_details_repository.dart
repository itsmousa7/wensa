// lib/features/places/data/repositories/place_details_repository.dart
import 'package:future_riverpod/features/places/domain/models/place_image_model.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/domain/models/tag_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'place_details_repository.g.dart';

class PlaceDetailsRepository {
  const PlaceDetailsRepository(this._client);
  final SupabaseClient _client;

  Future<PlaceModel> fetchPlace(String placeId) async {
    final data = await _client
        .schema('content')
        .from('places_mobile')
        .select()
        .eq('id', placeId)
        .single();
    return PlaceModel.fromJson(data);
  }

  Future<List<PlaceImageModel>> fetchImages(String placeId) async {
    final data = await _client
        .schema('content')
        .from('place_images')
        .select()
        .eq('place_id', placeId)
        .order('display_order', ascending: true);
    return data
        .map((e) => PlaceImageModel.fromJson(e))
        .where((img) => img.imageUrl.isNotEmpty)
        .toList();
  }

  Future<List<TagModel>> fetchTags(String placeId) async {
    final data = await _client
        .schema('content')
        .from('place_tags')
        .select('tags(id, name_ar, name_en)')
        .eq('place_id', placeId);
    return (data as List)
        .map((row) => TagModel.fromJson(row['tags'] as Map<String, dynamic>))
        .toList();
  }

  /// Records a view for the given user. The SQL function deduplicates per 24h
  /// and atomically increments places.view_count.
  Future<void> recordView(String placeId, String userId) async {
    await _client.rpc(
      'record_place_view',
      params: {'p_place_id': placeId, 'p_user_id': userId},
    );
  }
}

@riverpod
PlaceDetailsRepository placeDetailsRepository(Ref ref) =>
    PlaceDetailsRepository(Supabase.instance.client);
