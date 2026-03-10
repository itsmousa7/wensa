// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_app_bar_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlaceAppbarState)
final placeAppbarStateProvider = PlaceAppbarStateFamily._();

final class PlaceAppbarStateProvider
    extends $NotifierProvider<PlaceAppbarState, PlaceAppBarDetailsState> {
  PlaceAppbarStateProvider._({
    required PlaceAppbarStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placeAppbarStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeAppbarStateHash();

  @override
  String toString() {
    return r'placeAppbarStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaceAppbarState create() => PlaceAppbarState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceAppBarDetailsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceAppBarDetailsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaceAppbarStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeAppbarStateHash() => r'03578bd3f355890d1b49c907bcc5b22a5bee8c8e';

final class PlaceAppbarStateFamily extends $Family
    with
        $ClassFamilyOverride<
          PlaceAppbarState,
          PlaceAppBarDetailsState,
          PlaceAppBarDetailsState,
          PlaceAppBarDetailsState,
          String
        > {
  PlaceAppbarStateFamily._()
    : super(
        retry: null,
        name: r'placeAppbarStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlaceAppbarStateProvider call(String placeId) =>
      PlaceAppbarStateProvider._(argument: placeId, from: this);

  @override
  String toString() => r'placeAppbarStateProvider';
}

abstract class _$PlaceAppbarState extends $Notifier<PlaceAppBarDetailsState> {
  late final _$args = ref.$arg as String;
  String get placeId => _$args;

  PlaceAppBarDetailsState build(String placeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<PlaceAppBarDetailsState, PlaceAppBarDetailsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaceAppBarDetailsState, PlaceAppBarDetailsState>,
              PlaceAppBarDetailsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
