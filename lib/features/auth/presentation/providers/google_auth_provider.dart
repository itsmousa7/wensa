import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_auth_provider.g.dart';

@riverpod
class GoogleAuth extends _$GoogleAuth {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncData(null);
    } on GoogleSignInException catch (e, st) {
      // Only a TYPED cancellation counts as a user cancel. Matching 'cancel'
      // in the message text swallowed real failures — GMS wraps config
      // errors (e.g. UNREGISTERED_ON_API_CONSOLE when the app's SHA-1 isn't
      // registered) in cancel-flavored statuses, so sign-in silently did
      // nothing instead of surfacing the error dialog.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        state = const AsyncData(null); // Reset without error
        return;
      }
      state = AsyncError(e, st);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
