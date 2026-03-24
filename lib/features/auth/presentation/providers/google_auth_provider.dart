import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
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
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      // Silently ignore user-initiated cancellations
      if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        state = const AsyncData(null); // Reset without error
        return;
      }
      state = AsyncError(e, StackTrace.current);
    }
  }
}
