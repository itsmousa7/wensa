// lib/features/places/presentation/providers/place_reviews_provider.dart


import 'package:future_riverpod/features/places/domain/models/review_with_user_model.dart';
import 'package:future_riverpod/features/places/domain/repositories/place_reviews_repository.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_reviews_provider.g.dart';

/// Family AsyncNotifier — one instance per placeId.
/// Exposes [addReview] and [deleteReview]; both use AsyncValue.guard so the
/// UI can react to loading / error states without extra boilerplate.
@riverpod
class PlaceReviewsNotifier extends _$PlaceReviewsNotifier {
  @override
  Future<List<ReviewWithUser>> build(String placeId) =>
      ref.read(placeReviewsRepositoryProvider).fetchReviews(placeId);

  Future<void> addReview({
    required String userId,
    required int rating,
    String? comment,
  }) async {
    // Show spinner while submitting
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(placeReviewsRepositoryProvider)
          .addReview(
            placeId: placeId,
            userId: userId,
            rating: rating,
            comment: comment,
          );
      // Invalidate place cache so reviews_count refreshes on the details page.
      // The DB trigger already updated the counter; invalidating forces a re-fetch.
      ref.invalidate(placeDetailsProvider(placeId));
      return ref.read(placeReviewsRepositoryProvider).fetchReviews(placeId);
    });
  }

  Future<void> deleteReview(String reviewId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(placeReviewsRepositoryProvider).deleteReview(reviewId);
      ref.invalidate(placeDetailsProvider(placeId));
      return ref.read(placeReviewsRepositoryProvider).fetchReviews(placeId);
    });
  }
}
