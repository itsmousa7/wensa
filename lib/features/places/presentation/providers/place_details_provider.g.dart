// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlaceDetails)
final placeDetailsProvider = PlaceDetailsFamily._();

final class PlaceDetailsProvider
    extends $AsyncNotifierProvider<PlaceDetails, PlaceModel> {
  PlaceDetailsProvider._({
    required PlaceDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placeDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeDetailsHash();

  @override
  String toString() {
    return r'placeDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaceDetails create() => PlaceDetails();

  @override
  bool operator ==(Object other) {
    return other is PlaceDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeDetailsHash() => r'737de5ffca3a3614a5ab11f08ff774470bb919d9';

final class PlaceDetailsFamily extends $Family
    with
        $ClassFamilyOverride<
          PlaceDetails,
          AsyncValue<PlaceModel>,
          PlaceModel,
          FutureOr<PlaceModel>,
          String
        > {
  PlaceDetailsFamily._()
    : super(
        retry: null,
        name: r'placeDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlaceDetailsProvider call(String placeId) =>
      PlaceDetailsProvider._(argument: placeId, from: this);

  @override
  String toString() => r'placeDetailsProvider';
}

abstract class _$PlaceDetails extends $AsyncNotifier<PlaceModel> {
  late final _$args = ref.$arg as String;
  String get placeId => _$args;

  FutureOr<PlaceModel> build(String placeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PlaceModel>, PlaceModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlaceModel>, PlaceModel>,
              AsyncValue<PlaceModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(placeImages)
final placeImagesProvider = PlaceImagesFamily._();

final class PlaceImagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceImageModel>>,
          List<PlaceImageModel>,
          FutureOr<List<PlaceImageModel>>
        >
    with
        $FutureModifier<List<PlaceImageModel>>,
        $FutureProvider<List<PlaceImageModel>> {
  PlaceImagesProvider._({
    required PlaceImagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placeImagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeImagesHash();

  @override
  String toString() {
    return r'placeImagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlaceImageModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlaceImageModel>> create(Ref ref) {
    final argument = this.argument as String;
    return placeImages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaceImagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeImagesHash() => r'4e12f534d9ec8ce177e07537cb3d06d5805bbe3a';

final class PlaceImagesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlaceImageModel>>, String> {
  PlaceImagesFamily._()
    : super(
        retry: null,
        name: r'placeImagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlaceImagesProvider call(String placeId) =>
      PlaceImagesProvider._(argument: placeId, from: this);

  @override
  String toString() => r'placeImagesProvider';
}

@ProviderFor(placeTags)
final placeTagsProvider = PlaceTagsFamily._();

final class PlaceTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TagModel>>,
          List<TagModel>,
          FutureOr<List<TagModel>>
        >
    with $FutureModifier<List<TagModel>>, $FutureProvider<List<TagModel>> {
  PlaceTagsProvider._({
    required PlaceTagsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placeTagsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeTagsHash();

  @override
  String toString() {
    return r'placeTagsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TagModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TagModel>> create(Ref ref) {
    final argument = this.argument as String;
    return placeTags(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaceTagsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeTagsHash() => r'48c70057abaa27ce6a85fb2b548cae8ec6d3c2e5';

final class PlaceTagsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TagModel>>, String> {
  PlaceTagsFamily._()
    : super(
        retry: null,
        name: r'placeTagsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlaceTagsProvider call(String placeId) =>
      PlaceTagsProvider._(argument: placeId, from: this);

  @override
  String toString() => r'placeTagsProvider';
}
