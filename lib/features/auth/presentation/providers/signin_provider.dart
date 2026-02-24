import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signin_provider.g.dart';

@riverpod
class Signin extends _$Signin {
  @override
  FutureOr<void> build() {}

  Future<void> signin(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signIn(
            email: email,
            password: password,
          ),
    );
  }
}
