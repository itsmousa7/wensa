import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';
import 'package:future_riverpod/features/auth/domain/repositories/profile_repository.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'complete_profile_provider.g.dart';

@riverpod
class CompleteProfile extends _$CompleteProfile {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String firstName,
    required String secondName,
    required String phone,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          throw const CustomError(
            code: 'NOT_AUTHENTICATED',
            message: 'You are not signed in.',
            plugin: '',
          );
        }

        // Upsert (not just update) so this still works if the
        // `handle_new_user` trigger didn't fire for this auth.users row.
        await ref.read(profileRepositoryProvider).upsertProfileBasics(
              user.id,
              email: user.email ?? '',
              firstName: firstName,
              secondName: secondName,
              phone: phone,
            );

        // Refresh the profile so the router redirect re-evaluates and lets
        // the user into the app.
        ref.invalidate(profileProvider);
      } on AuthException catch (e) {
        throw CustomError(
          code: 'AUTH_ERROR',
          message: e.message,
          plugin: e.statusCode?.toString() ?? '',
        );
      } on CustomError {
        rethrow;
      } catch (e) {
        throw CustomError(
          code: 'UNKNOWN',
          message: e.toString(),
          plugin: '',
        );
      }
    });
  }
}
