// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GoogleAuth)
final googleAuthProvider = GoogleAuthProvider._();

final class GoogleAuthProvider
    extends $AsyncNotifierProvider<GoogleAuth, void> {
  GoogleAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleAuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleAuthHash();

  @$internal
  @override
  GoogleAuth create() => GoogleAuth();
}

String _$googleAuthHash() => r'bdc2f62a1f03bfc7bdb0402610ee34ae05515a22';

abstract class _$GoogleAuth extends $AsyncNotifier<void> {
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
