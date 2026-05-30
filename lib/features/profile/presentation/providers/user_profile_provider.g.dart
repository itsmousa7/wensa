// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Profile)
final profileProvider = ProfileProvider._();

final class ProfileProvider extends $AsyncNotifierProvider<Profile, UserModel> {
  ProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileHash();

  @$internal
  @override
  Profile create() => Profile();
}

String _$profileHash() => r'f54ff0e89486724c7475331ac45078ff422e7819';

abstract class _$Profile extends $AsyncNotifier<UserModel> {
  FutureOr<UserModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserModel>, UserModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserModel>, UserModel>,
              AsyncValue<UserModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(userReviewsCount)
final userReviewsCountProvider = UserReviewsCountProvider._();

final class UserReviewsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  UserReviewsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userReviewsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userReviewsCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return userReviewsCount(ref);
  }
}

String _$userReviewsCountHash() => r'ba6335d1e0bcb60b91fef030e84b30d4cf4603a7';

@ProviderFor(isProfileComplete)
final isProfileCompleteProvider = IsProfileCompleteProvider._();

final class IsProfileCompleteProvider
    extends $FunctionalProvider<bool?, bool?, bool?>
    with $Provider<bool?> {
  IsProfileCompleteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isProfileCompleteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isProfileCompleteHash();

  @$internal
  @override
  $ProviderElement<bool?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool? create(Ref ref) {
    return isProfileComplete(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool?>(value),
    );
  }
}

String _$isProfileCompleteHash() => r'1d775df23503afcaa8a8d07959ca9e7978488b71';
