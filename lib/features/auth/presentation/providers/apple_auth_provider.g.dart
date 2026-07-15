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

String _$appleAuthHash() => r'08d68abc8fc061533d2e4a6825f4b432a52e9c26';

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
