import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'signup_provider.g.dart';

@riverpod
class Signup extends _$Signup {
  Object? _lifecycleToken;

  @override
  FutureOr<void> build() {
    _lifecycleToken = Object();
    ref.onDispose(() {
      _lifecycleToken = null;
    });
  }

  Future<void> signup({
    required String firstName,
    required String secondName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final lifecycleToken = _lifecycleToken;

    final newState = await AsyncValue.guard(() async {
      try {
        final response = await ref
            .read(authRepositoryProvider)
            .signUp(
              email: email,
              password: password,
              data: {
                'first_name': firstName,
                'second_name': secondName,
              },
            );

        // Supabase silently "succeeds" for duplicate emails but returns
        // a user with an empty identities list. Detect and surface this.
        final identities = response.user?.identities;
        if (identities != null && identities.isEmpty) {
          throw const CustomError(
            code: 'EMAIL_ALREADY_REGISTERED',
            message:
                'This email is already registered. Please sign in instead.',
            plugin: '400',
          );
        }
      } on AuthException catch (e) {
        throw CustomError(
          code: 'AUTH_ERROR',
          message: e.message,
          plugin: e.statusCode?.toString() ?? '',
        );
      } on CustomError {
        rethrow; // already formatted above
      } catch (e) {
        throw CustomError(
          code: 'UNKNOWN',
          message: e.toString(),
          plugin: '',
        );
      }
    });

    if (lifecycleToken == _lifecycleToken) {
      state = newState;
    }
  }
}
