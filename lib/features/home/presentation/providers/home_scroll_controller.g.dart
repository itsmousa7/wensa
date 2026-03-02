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
        isAutoDispose: true,
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
    r'29eafadba32fc6ee8c58e0c49dee700974f586f7';
