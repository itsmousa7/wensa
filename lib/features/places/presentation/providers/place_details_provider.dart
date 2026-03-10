// lib/features/places/presentation/providers/place_details_provider.dart
//
// REPLACES: lib/features/home/presentation/providers/place_details_provider.dart
// Update all imports in pages / sheets to point here.

import 'package:future_riverpod/features/places/domain/models/place_image_model.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/domain/models/tag_model.dart';
import 'package:future_riverpod/features/places/domain/repositories/place_details_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_details_provider.g.dart';

@riverpod
class PlaceDetails extends _$PlaceDetails {
  @override
  Future<PlaceModel> build(String placeId) =>
      ref.watch(placeDetailsRepositoryProvider).fetchPlace(placeId);

  /// Immediately adjusts the cached savesCount by [delta] (+1 or -1)
  /// without triggering a network refetch.
  void patchSavesCount(int delta) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(savesCount: current.savesCount + delta));
  }
}

@riverpod
Future<List<PlaceImageModel>> placeImages(Ref ref, String placeId) =>
    ref.watch(placeDetailsRepositoryProvider).fetchImages(placeId);

@riverpod
Future<List<TagModel>> placeTags(Ref ref, String placeId) =>
    ref.watch(placeDetailsRepositoryProvider).fetchTags(placeId);
