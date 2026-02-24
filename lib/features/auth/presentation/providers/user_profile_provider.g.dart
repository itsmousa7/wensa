// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserProfile)
final userProfileProvider = UserProfileProvider._();

final class UserProfileProvider
    extends $AsyncNotifierProvider<UserProfile, List<UserModel>> {
  UserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  UserProfile create() => UserProfile();
}

String _$userProfileHash() => r'7824c040076518955bd2ccaec57cb2d830e14c09';

abstract class _$UserProfile extends $AsyncNotifier<List<UserModel>> {
  FutureOr<List<UserModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<UserModel>>, List<UserModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserModel>>, List<UserModel>>,
              AsyncValue<List<UserModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
