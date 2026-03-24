// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_scroll_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeScrollController)
final homeScrollControllerProvider = HomeScrollControllerProvider._();

final class HomeScrollControllerProvider
    extends
        $FunctionalProvider<
          ScrollController,
          ScrollController,
          ScrollController
        >
    with $Provider<ScrollController> {
  HomeScrollControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeScrollControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeScrollControllerHash();

  @$internal
  @override
  $ProviderElement<ScrollController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScrollController create(Ref ref) {
    return homeScrollController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScrollController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScrollController>(value),
    );
  }
}

String _$homeScrollControllerHash() =>
    r'2c0f0239c973665bf060af6cccf96bede8c9b47a';
