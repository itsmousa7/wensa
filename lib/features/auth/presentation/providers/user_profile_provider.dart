import 'package:future_riverpod/core/constants/supabase_constants.dart';
import 'package:future_riverpod/features/auth/domain/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true) // only one, not two
class UserProfile extends _$UserProfile {
  @override
  FutureOr<List<UserModel>> build() async {
    return _fetch();
  }

  Future<List<UserModel>> _fetch() async {
    final response = await supabase.from('app_users').select();
    return response.map(UserModel.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
