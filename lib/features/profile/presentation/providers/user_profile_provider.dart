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
//  `true` once it is known (so the router lets the user into /home).
//
//  Note: NOTHING personal is required at the authentication step anymore.
//  - The name is not required because Sign in with Apple only returns it on the
//    very first authorization — requiring it later violates its guidelines.
//  - The phone number is not required because Apple guideline 5.1.1(v) forbids
//    requiring personal information that is not needed to create the account.
//  Both the name and the phone number are instead collected inside the booking
//  flow (see [BookingDetailsGate]), prefilled from any value we already hold,
//  where asking for them is a legitimate functional requirement of the
//  reservation rather than an account-creation gate. As a result this gate no
//  longer redirects anyone to /complete-profile — a signed-in, verified user is
//  always allowed straight through to /home.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
bool? isProfileComplete(Ref ref) {
  // Without a signed-in user the question is meaningless — return null so the
  // router falls through to its standard auth guards.
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final async = ref.watch(profileProvider);
  return async.when(
    // The profile carries no auth-time required fields, so it is "complete" as
    // soon as we have a signed-in user. We only wait for the first load to
    // avoid the /home screen flashing before the profile row is available.
    data: (_) => true,
    loading: () => null,
    // A fetch failure (missing row, RLS issue, network) must not strand the
    // user: there is no longer a /complete-profile step to send them to, and
    // any missing name/phone is repaired inside the booking flow. Let them in.
    error: (_, _) => true,
  );
}

/// Sentinel used by [Profile.build] when there is no signed-in user. Kept
/// private so callers don't pattern-match on it; they just see AsyncError.
class _NotAuthenticated implements Exception {
  const _NotAuthenticated();
  @override
  String toString() => 'Not authenticated';
}
