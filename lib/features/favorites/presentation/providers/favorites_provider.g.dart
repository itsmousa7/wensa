// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Favorites)
final favoritesProvider = FavoritesProvider._();

final class FavoritesProvider
    extends $AsyncNotifierProvider<Favorites, Set<String>> {
  FavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesHash();

  @$internal
  @override
  Favorites create() => Favorites();
}

String _$favoritesHash() => r'1be1a15df4c05f43add50a1dcc1c9b9ac4a83811';

abstract class _$Favorites extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FavoritesFeed)
final favoritesFeedProvider = FavoritesFeedProvider._();

final class FavoritesFeedProvider
    extends $NotifierProvider<FavoritesFeed, CategoryFeedState> {
  FavoritesFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesFeedHash();

  @$internal
  @override
  FavoritesFeed create() => FavoritesFeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryFeedState>(value),
    );
  }
}

String _$favoritesFeedHash() => r'45084b1ab00d26043a287d1c4e1b9adb0b678f3b';

abstract class _$FavoritesFeed extends $Notifier<CategoryFeedState> {
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

@ProviderFor(SeeAllFeed)
final seeAllFeedProvider = SeeAllFeedFamily._();

final class SeeAllFeedProvider
    extends $NotifierProvider<SeeAllFeed, CategoryFeedState> {
  SeeAllFeedProvider._({
    required SeeAllFeedFamily super.from,
    required SeeAllType super.argument,
  }) : super(
         retry: null,
         name: r'seeAllFeedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$seeAllFeedHash();

  @override
  String toString() {
    return r'seeAllFeedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SeeAllFeed create() => SeeAllFeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryFeedState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SeeAllFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seeAllFeedHash() => r'838c7fedbef22f05f7c2ab171d86d4b599b859e6';

final class SeeAllFeedFamily extends $Family
    with
        $ClassFamilyOverride<
          SeeAllFeed,
          CategoryFeedState,
          CategoryFeedState,
          CategoryFeedState,
          SeeAllType
        > {
  SeeAllFeedFamily._()
    : super(
        retry: null,
        name: r'seeAllFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SeeAllFeedProvider call(SeeAllType type) =>
      SeeAllFeedProvider._(argument: type, from: this);

  @override
  String toString() => r'seeAllFeedProvider';
}

abstract class _$SeeAllFeed extends $Notifier<CategoryFeedState> {
  late final _$args = ref.$arg as SeeAllType;
  SeeAllType get type => _$args;

  CategoryFeedState build(SeeAllType type);
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
    element.handleCreate(ref, () => build(_$args));
  }
}
