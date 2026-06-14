import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'apple_auth_provider.g.dart';

@riverpod
class AppleAuth extends _$AppleAuth {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      state = const AsyncData(null);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      // Silently ignore user-initiated cancellations
      if (errorStr.contains('canceled') ||
          errorStr.contains('cancelled') ||
          errorStr.contains('authorizationerrorcode.canceled')) {
        state = const AsyncData(null); // Reset without error
        return;
      }
      state = AsyncError(e, StackTrace.current);
    }
  }
}
