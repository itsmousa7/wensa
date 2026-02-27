// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeRepository)
final homeRepositoryProvider = HomeRepositoryProvider._();

final class HomeRepositoryProvider
    extends $FunctionalProvider<HomeRepository, HomeRepository, HomeRepository>
    with $Provider<HomeRepository> {
  HomeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRepositoryHash();

  @$internal
  @override
  $ProviderElement<HomeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeRepository create(Ref ref) {
    return homeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeRepository>(value),
    );
  }
}

String _$homeRepositoryHash() => r'3cd60e6bcffc0871e9b6eba9043708ad6b136576';

@ProviderFor(hotEvents)
final hotEventsProvider = HotEventsProvider._();

final class HotEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EventModel>>,
          List<EventModel>,
          FutureOr<List<EventModel>>
        >
    with $FutureModifier<List<EventModel>>, $FutureProvider<List<EventModel>> {
  HotEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotEventsHash();

  @$internal
  @override
  $FutureProviderElement<List<EventModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EventModel>> create(Ref ref) {
    return hotEvents(ref);
  }
}

String _$hotEventsHash() => r'84fbf28fdc3b5ee63beb20d7f454545bf9ccb404';

@ProviderFor(trendingFeed)
final trendingFeedProvider = TrendingFeedProvider._();

final class TrendingFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrendingFeedItemModel>>,
          List<TrendingFeedItemModel>,
          FutureOr<List<TrendingFeedItemModel>>
        >
    with
        $FutureModifier<List<TrendingFeedItemModel>>,
        $FutureProvider<List<TrendingFeedItemModel>> {
  TrendingFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendingFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendingFeedHash();

  @$internal
  @override
  $FutureProviderElement<List<TrendingFeedItemModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TrendingFeedItemModel>> create(Ref ref) {
    return trendingFeed(ref);
  }
}

String _$trendingFeedHash() => r'001c4c388d4e9a87ee90eddb9266986bd32ed0eb';

@ProviderFor(newOpenings)
final newOpeningsProvider = NewOpeningsProvider._();

final class NewOpeningsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceModel>>,
          List<PlaceModel>,
          FutureOr<List<PlaceModel>>
        >
    with $FutureModifier<List<PlaceModel>>, $FutureProvider<List<PlaceModel>> {
  NewOpeningsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newOpeningsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newOpeningsHash();

  @$internal
  @override
  $FutureProviderElement<List<PlaceModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlaceModel>> create(Ref ref) {
    return newOpenings(ref);
  }
}

String _$newOpeningsHash() => r'fb816449804d6c54811f5504ce663e81f00da781';

@ProviderFor(promotedBanners)
final promotedBannersProvider = PromotedBannersProvider._();

final class PromotedBannersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PromotedBannerModel>>,
          List<PromotedBannerModel>,
          FutureOr<List<PromotedBannerModel>>
        >
    with
        $FutureModifier<List<PromotedBannerModel>>,
        $FutureProvider<List<PromotedBannerModel>> {
  PromotedBannersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promotedBannersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promotedBannersHash();

  @$internal
  @override
  $FutureProviderElement<List<PromotedBannerModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PromotedBannerModel>> create(Ref ref) {
    return promotedBanners(ref);
  }
}

String _$promotedBannersHash() => r'516b525ae5cf20550182c4f0c9066fc7f6362f01';

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryModel>>,
          List<CategoryModel>,
          FutureOr<List<CategoryModel>>
        >
    with
        $FutureModifier<List<CategoryModel>>,
        $FutureProvider<List<CategoryModel>> {
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<CategoryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CategoryModel>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'526aa6e532539af2cf061b001b5491c2a3b13012';

@ProviderFor(SelectedCategory)
final selectedCategoryProvider = SelectedCategoryProvider._();

final class SelectedCategoryProvider
    extends $NotifierProvider<SelectedCategory, int> {
  SelectedCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCategoryHash();

  @$internal
  @override
  SelectedCategory create() => SelectedCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$selectedCategoryHash() => r'002df8395441d97c9bb68549b7f238c43f0e0840';

abstract class _$SelectedCategory extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
