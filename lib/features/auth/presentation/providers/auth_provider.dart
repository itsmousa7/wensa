import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'supabase_provider.dart';

part 'auth_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FIX 1 — multiple "Refresh session" calls
//
//  Removed ref.watch(authStateChangeProvider) from build().
//  ref.watch re-ran build() on every stream event, and the ref.listen inside
//  that same build() then set state=, causing a notification loop that drove
//  Supabase to call _recoverAndRefresh() 6-7 times on cold start.
//
//  FIX 2 — compile errors (type mismatch + missing .session)
//
//  The class was named AuthState, clashing with Supabase's own AuthState.
//  Dart resolved AsyncValue<AuthState> to THIS class, so:
//    - AuthStateChangeProvider didn't match ProviderListenable<AsyncValue<AuthState>>
//    - .session didn't exist (it's on Supabase's AuthState, not ours)
//
//  Solution: rename to CurrentUser and import Supabase with an alias (supa.)
//  so supa.AuthState, supa.User etc. are always unambiguous.
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class CurrentUser extends _$CurrentUser {
  @override
  supa.User? build() {
    // Single, flat listener — never re-runs build(), no loop.
    ref.listen<AsyncValue<supa.AuthState>>(
      authStateChangeProvider,
      (_, next) {
        state = next.value?.session?.user;
      },
      fireImmediately: false,
    );

    return ref.read(supabaseProvider).auth.currentUser;
  }

  bool get isAuthenticated => state != null;
  bool get isEmailVerified => state?.emailConfirmedAt != null;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Convenience providers
//  All callers that used authStateProvider now use currentUserProvider.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
bool isAuthenticated(Ref ref) => ref.watch(currentUserProvider) != null;

@riverpod
bool isEmailVerified(Ref ref) =>
    ref.watch(currentUserProvider)?.emailConfirmedAt != null;