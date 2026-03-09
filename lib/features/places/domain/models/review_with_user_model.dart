// lib/features/places/domain/models/review_with_user.dart
import 'package:future_riverpod/features/places/domain/models/review_model.dart';

class ReviewWithUser {
  final ReviewModel review;
  final String? firstName;
  final String? secondName;
  final String? avatarUrl;

  const ReviewWithUser({
    required this.review,
    this.firstName,
    this.secondName,
    this.avatarUrl,
  });

  /// Full name from app_users. Empty string if neither field has data.
  String get displayName {
    final parts = [firstName, secondName]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toList();
    return parts.join(' ');
  }

  /// First letter(s) for the avatar fallback circle.
  String get initials {
    final name = displayName;
    if (name.isEmpty) return '?';
    final words = name.split(' ').where((w) => w.isNotEmpty).take(2).toList();
    return words.map((w) => w[0].toUpperCase()).join();
  }
}
