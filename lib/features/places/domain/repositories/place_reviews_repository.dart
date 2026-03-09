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
    final data = await _client
        .from('reviews')
        .select('*, app_users(first_name, second_name, avatar_url)')
        .eq('place_id', placeId)
        .order('created_at', ascending: false);

    return (data as List).map((row) {
      final user = row['app_users'] as Map<String, dynamic>?;
      return ReviewWithUser(
        review: ReviewModel.fromJson(row),
        firstName: user?['first_name'] as String?,
        secondName: user?['second_name'] as String?,
        avatarUrl: user?['avatar_url'] as String?,
      );
    }).toList();
  }

  Future<void> addReview({
    required String placeId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    await _client.from('reviews').insert({
      'place_id': placeId,
      'user_id': userId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await _client.from('reviews').delete().eq('id', reviewId);
  }
}

@riverpod
PlaceReviewsRepository placeReviewsRepository(Ref ref) =>
    PlaceReviewsRepository(Supabase.instance.client);