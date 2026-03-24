// lib/features/auth/presentation/providers/profile_provider.dart

import 'dart:io';

import 'package:future_riverpod/features/auth/domain/models/user_model.dart';
import 'package:future_riverpod/features/auth/domain/repositories/profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_profile_provider.g.dart';
// ─────────────────────────────────────────────────────────────────────────────
//  Profile — the full user record
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class Profile extends _$Profile {
  @override
  Future<UserModel> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return ref.read(profileRepositoryProvider).fetchProfile(user.id);
  }

  /// Uploads [file] to Supabase Storage, then patches the local state
  /// immediately so the avatar renders without a full refetch.
  Future<void> uploadAvatar(File file) async {
    final user = Supabase.instance.client.auth.currentUser;
    final current = state.value;
    if (user == null || current == null) return;

    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(user.id, file);

      // Persist the new URL to the database row.
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(user.id, avatarUrl: url);

      // Optimistic local patch — no extra network round-trip needed.
      state = AsyncData(current.copyWith(avatarUrl: url));
    } catch (_) {
      // Silently keep the old state; the UI shows no change.
    }
  }

  Future<void> deleteAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    final current = state.value;
    if (user == null || current == null) return;

    // Optimistic — clear immediately
    state = AsyncData(current.copyWith(avatarUrl: null));

    try {
      await ref.read(profileRepositoryProvider).deleteAvatar(user.id);
    } catch (_) {
      // Rollback on failure
      state = AsyncData(current);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ReviewsCount — lightweight count separate from the main profile
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<int> userReviewsCount(Ref ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;
  return ref.watch(profileRepositoryProvider).fetchReviewsCount(user.id);
}
