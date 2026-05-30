// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CompleteProfile)
final completeProfileProvider = CompleteProfileProvider._();

final class CompleteProfileProvider
    extends $AsyncNotifierProvider<CompleteProfile, void> {
  CompleteProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'completeProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$completeProfileHash();

  @$internal
  @override
  CompleteProfile create() => CompleteProfile();
}

String _$completeProfileHash() => r'2d11b275d39449adb7df1d48f50011d5bde0ef7d';

abstract class _$CompleteProfile extends $AsyncNotifier<void> {
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
