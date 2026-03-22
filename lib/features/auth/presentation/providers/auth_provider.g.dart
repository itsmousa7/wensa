// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentUser)
final currentUserProvider = CurrentUserProvider._();

final class CurrentUserProvider
    extends $NotifierProvider<CurrentUser, supa.User?> {
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  CurrentUser create() => CurrentUser();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(supa.User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<supa.User?>(value),
    );
  }
}

String _$currentUserHash() => r'eb811900788f4f2bc12ae77332196889a393685c';

abstract class _$CurrentUser extends $Notifier<supa.User?> {
  supa.User? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<supa.User?, supa.User?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<supa.User?, supa.User?>,
              supa.User?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = IsAuthenticatedProvider._();

final class IsAuthenticatedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsAuthenticatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAuthenticatedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAuthenticatedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAuthenticated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAuthenticatedHash() => r'6d67d64c22072310457fc0024272859f112c0be2';

@ProviderFor(isEmailVerified)
final isEmailVerifiedProvider = IsEmailVerifiedProvider._();

final class IsEmailVerifiedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsEmailVerifiedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isEmailVerifiedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isEmailVerifiedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isEmailVerified(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isEmailVerifiedHash() => r'9fcce6e284e7193177858e29bd681cbef1aa9c0d';
