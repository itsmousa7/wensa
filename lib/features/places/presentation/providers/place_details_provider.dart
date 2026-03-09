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
Future<PlaceModel> placeDetails(Ref ref, String placeId) =>
    ref.watch(placeDetailsRepositoryProvider).fetchPlace(placeId);

@riverpod
Future<List<PlaceImageModel>> placeImages(Ref ref, String placeId) =>
    ref.watch(placeDetailsRepositoryProvider).fetchImages(placeId);

@riverpod
Future<List<TagModel>> placeTags(Ref ref, String placeId) =>
    ref.watch(placeDetailsRepositoryProvider).fetchTags(placeId);
