// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_reviews_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Family AsyncNotifier — one instance per placeId.
/// Exposes [addReview] and [deleteReview]; both use AsyncValue.guard so the
/// UI can react to loading / error states without extra boilerplate.

@ProviderFor(PlaceReviewsNotifier)
final placeReviewsProvider = PlaceReviewsNotifierFamily._();

/// Family AsyncNotifier — one instance per placeId.
/// Exposes [addReview] and [deleteReview]; both use AsyncValue.guard so the
/// UI can react to loading / error states without extra boilerplate.
final class PlaceReviewsNotifierProvider
    extends $AsyncNotifierProvider<PlaceReviewsNotifier, List<ReviewWithUser>> {
  /// Family AsyncNotifier — one instance per placeId.
  /// Exposes [addReview] and [deleteReview]; both use AsyncValue.guard so the
  /// UI can react to loading / error states without extra boilerplate.
  PlaceReviewsNotifierProvider._({
    required PlaceReviewsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placeReviewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeReviewsNotifierHash();

  @override
  String toString() {
    return r'placeReviewsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaceReviewsNotifier create() => PlaceReviewsNotifier();

  @override
  bool operator ==(Object other) {
    return other is PlaceReviewsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeReviewsNotifierHash() =>
    r'b9a026c6c028d4ed6ac2e8bd9ee4ccaeb40409ec';

/// Family AsyncNotifier — one instance per placeId.
/// Exposes [addReview] and [deleteReview]; both use AsyncValue.guard so the
/// UI can react to loading / error states without extra boilerplate.

final class PlaceReviewsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PlaceReviewsNotifier,
          AsyncValue<List<ReviewWithUser>>,
          List<ReviewWithUser>,
          FutureOr<List<ReviewWithUser>>,
          String
        > {
  PlaceReviewsNotifierFamily._()
    : super(
        retry: null,
        name: r'placeReviewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family AsyncNotifier — one instance per placeId.
  /// Exposes [addReview] and [deleteReview]; both use AsyncValue.guard so the
  /// UI can react to loading / error states without extra boilerplate.

  PlaceReviewsNotifierProvider call(String placeId) =>
      PlaceReviewsNotifierProvider._(argument: placeId, from: this);

  @override
  String toString() => r'placeReviewsProvider';
}

/// Family AsyncNotifier — one instance per placeId.
/// Exposes [addReview] and [deleteReview]; both use AsyncValue.guard so the
/// UI can react to loading / error states without extra boilerplate.

abstract class _$PlaceReviewsNotifier
    extends $AsyncNotifier<List<ReviewWithUser>> {
  late final _$args = ref.$arg as String;
  String get placeId => _$args;

  FutureOr<List<ReviewWithUser>> build(String placeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ReviewWithUser>>, List<ReviewWithUser>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ReviewWithUser>>,
                List<ReviewWithUser>
              >,
              AsyncValue<List<ReviewWithUser>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
