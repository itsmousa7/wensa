// lib/features/auth/presentation/providers/profile_provider.dart

import 'dart:io';

import 'package:future_riverpod/features/auth/domain/models/user_model.dart';
import 'package:future_riverpod/features/auth/domain/repositories/profile_repository.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
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
    // Watch currentUserProvider so the profile rebuilds whenever the signed-in
    // user changes — sign-in / sign-up / sign-out all flow through here. The
    // previous implementation read currentUser directly, so the provider built
    // once at app start with a null user, errored, and stayed errored after
    // sign-up — leaving the redirect gate unable to evaluate completeness.
    final user = ref.watch(currentUserProvider);
    if (user == null) throw const _NotAuthenticated();
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

// ─────────────────────────────────────────────────────────────────────────────
//  ProfileCompletion — sync view used by the router redirect.
//
//  Returns `null` while the profile is still loading (router should wait),
//  `true` when the row has a phone number on file, `false` otherwise (router
//  should redirect to /complete-profile).
//
//  Note: the name is intentionally NOT part of this gate. Sign in with Apple
//  only returns the user's name on the very first authorization — every
//  re-authorization (and App Store re-review) returns null — so requiring the
//  name right after authentication violates Sign in with Apple's guidelines.
//  The name is instead captured inside the booking flow (prefilled from any
//  Apple/Google-provided value), where asking for it is a legitimate
//  functional requirement rather than an auth gate.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
bool? isProfileComplete(Ref ref) {
  // Without a signed-in user the question is meaningless — return null so the
  // router falls through to its standard auth guards.
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final async = ref.watch(profileProvider);
  return async.when(
    data: (u) => (u.phone ?? '').trim().isNotEmpty,
    loading: () => null,
    // A genuine fetch failure (missing row, RLS issue, network) is treated as
    // "incomplete" so the user is sent to /complete-profile, where the upsert
    // path can repair the row instead of leaving them stranded on /home.
    error: (_, _) => false,
  );
}

/// Sentinel used by [Profile.build] when there is no signed-in user. Kept
/// private so callers don't pattern-match on it; they just see AsyncError.
class _NotAuthenticated implements Exception {
  const _NotAuthenticated();
  @override
  String toString() => 'Not authenticated';
}
