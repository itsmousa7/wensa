// lib/features/places/data/repositories/place_reviews_repository.dart
import 'package:future_riverpod/features/places/domain/models/review_model.dart';
import 'package:future_riverpod/features/places/domain/models/review_with_user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'place_reviews_repository.g.dart';

class PlaceReviewsRepository {
  const PlaceReviewsRepository(this._client);
  final SupabaseClient _client;

  Future<List<ReviewWithUser>> fetchReviews(String placeId) async {
    // SECURITY DEFINER RPC: app_users RLS only exposes the viewer's own row,
    // so an embedded join hides every other reviewer's name/avatar. The RPC
    // returns the public profile fields (name + avatar) for all reviewers.
    final data = await _client.schema('profiles').rpc(
      'get_place_reviews',
      params: {'p_place_id': placeId},
    );

    return (data as List).map((row) {
      return ReviewWithUser(
        review: ReviewModel.fromJson(row),
        firstName: row['first_name'] as String?,
        secondName: row['second_name'] as String?,
        avatarUrl: row['avatar_url'] as String?,
      );
    }).toList();
  }

  Future<void> addReview({
    required String placeId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    await _client.schema('profiles').from('reviews').insert({
      'place_id': placeId,
      'user_id': userId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await _client.schema('profiles').from('reviews').delete().eq('id', reviewId);
  }
}

@riverpod
PlaceReviewsRepository placeReviewsRepository(Ref ref) =>
    PlaceReviewsRepository(Supabase.instance.client);