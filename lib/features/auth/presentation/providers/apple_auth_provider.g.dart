// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apple_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppleAuth)
final appleAuthProvider = AppleAuthProvider._();

final class AppleAuthProvider extends $AsyncNotifierProvider<AppleAuth, void> {
  AppleAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appleAuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appleAuthHash();

  @$internal
  @override
  AppleAuth create() => AppleAuth();
}

String _$appleAuthHash() => r'ef2b75fb611ce36c962c6627fc039e4f0b823975';

abstract class _$AppleAuth extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
