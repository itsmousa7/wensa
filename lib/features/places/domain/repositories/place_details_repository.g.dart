// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_details_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placeDetailsRepository)
final placeDetailsRepositoryProvider = PlaceDetailsRepositoryProvider._();

final class PlaceDetailsRepositoryProvider
    extends
        $FunctionalProvider<
          PlaceDetailsRepository,
          PlaceDetailsRepository,
          PlaceDetailsRepository
        >
    with $Provider<PlaceDetailsRepository> {
  PlaceDetailsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeDetailsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeDetailsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaceDetailsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaceDetailsRepository create(Ref ref) {
    return placeDetailsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceDetailsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceDetailsRepository>(value),
    );
  }
}

String _$placeDetailsRepositoryHash() =>
    r'3845a6db36b03176754abd11c0bab5e002c644c0';
