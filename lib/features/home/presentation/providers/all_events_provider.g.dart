// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(allEvents)
final allEventsProvider = AllEventsProvider._();

final class AllEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EventModel>>,
          List<EventModel>,
          FutureOr<List<EventModel>>
        >
    with $FutureModifier<List<EventModel>>, $FutureProvider<List<EventModel>> {
  AllEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allEventsHash();

  @$internal
  @override
  $FutureProviderElement<List<EventModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EventModel>> create(Ref ref) {
    return allEvents(ref);
  }
}

String _$allEventsHash() => r'81d636eb5495efaa3e3dfc6ff437c4de7f9d0c17';

@ProviderFor(AllEventsSeeAll)
final allEventsSeeAllProvider = AllEventsSeeAllProvider._();

final class AllEventsSeeAllProvider
    extends $NotifierProvider<AllEventsSeeAll, CategoryFeedState> {
  AllEventsSeeAllProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allEventsSeeAllProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allEventsSeeAllHash();

  @$internal
  @override
  AllEventsSeeAll create() => AllEventsSeeAll();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryFeedState>(value),
    );
  }
}

String _$allEventsSeeAllHash() => r'37eaf9a5431980eadb7532c3100a62c3a0cdad0f';

abstract class _$AllEventsSeeAll extends $Notifier<CategoryFeedState> {
  CategoryFeedState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CategoryFeedState, CategoryFeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CategoryFeedState, CategoryFeedState>,
              CategoryFeedState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
