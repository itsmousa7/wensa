// lib/features/auth/data/repositories/profile_repository.dart

import 'dart:io';

import 'package:future_riverpod/features/auth/domain/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<UserModel> fetchProfile(String userId) async {
    final data = await _client
        .from('app_users')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(data);
  }

  Future<int> fetchReviewsCount(String userId) async {
    final res = await _client
        .from('reviews')
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
    return res.count;
  }

  // ── Write ────────────────────────────────────────────────────────────────

  /// Uploads [file] to `avatars/{userId}/avatar.jpg` (upsert).
  /// Returns the public URL for the file.
  Future<String> uploadAvatar(String userId, File file) async {
    const bucket = 'avatars';
    final path = '$userId/avatar.jpg';

    await _client.storage
        .from(bucket)
        .upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    // Append a cache-buster so CachedNetworkImage always reloads the new photo.
    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> deleteAvatar(String userId) async {
    // Remove from storage
    await _client.storage.from('avatars').remove(['$userId/avatar.jpg']);

    // Clear the url from the database row
    await _client
        .from('app_users')
        .update({
          'avatar_url': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Persists any combination of updatable fields to `app_users`.
  Future<UserModel> updateProfile(
    String userId, {
    String? firstName,
    String? secondName,
    String? phone,
    String? city,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{
      'first_name': ?firstName,
      'second_name': ?secondName,
      'phone': ?phone,
      'city': ?city,
      'avatar_url': ?avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final data = await _client
        .from('app_users')
        .update(payload)
        .eq('id', userId)
        .select()
        .single();

    return UserModel.fromJson(data);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

@riverpod
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepository(Supabase.instance.client);
