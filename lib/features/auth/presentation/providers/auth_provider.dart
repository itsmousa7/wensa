import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  User? build() {
    final client = ref.watch(supabaseProvider);

    // ✅ Force the stream provider to initialize immediately so no auth
    // events are missed before the first listener attaches.
    ref.watch(authStateChangeProvider);

    // Now listen for changes and update state
    ref.listen(authStateChangeProvider, (previous, next) {
      state = next.value?.session?.user;
    });

    return client.auth.currentUser;
  }

  bool get isAuthenticated => state != null;
  bool get isEmailVerified => state?.emailConfirmedAt != null;
}

// Convenience provider for checking auth status
@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authStateProvider) != null;
}

@riverpod
bool isEmailVerified(Ref ref) {
  final user = ref.watch(authStateProvider);
  return user?.emailConfirmedAt != null;
}
