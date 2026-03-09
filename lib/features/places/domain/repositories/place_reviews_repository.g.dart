// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_reviews_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placeReviewsRepository)
final placeReviewsRepositoryProvider = PlaceReviewsRepositoryProvider._();

final class PlaceReviewsRepositoryProvider
    extends
        $FunctionalProvider<
          PlaceReviewsRepository,
          PlaceReviewsRepository,
          PlaceReviewsRepository
        >
    with $Provider<PlaceReviewsRepository> {
  PlaceReviewsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeReviewsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeReviewsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaceReviewsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaceReviewsRepository create(Ref ref) {
    return placeReviewsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceReviewsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceReviewsRepository>(value),
    );
  }
}

String _$placeReviewsRepositoryHash() =>
    r'80e017c66d5b197ab4866eb4c41d0f45a2b15516';
