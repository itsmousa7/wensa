// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoryFeed)
final categoryFeedProvider = CategoryFeedFamily._();

final class CategoryFeedProvider
    extends $NotifierProvider<CategoryFeed, CategoryFeedState> {
  CategoryFeedProvider._({
    required CategoryFeedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'categoryFeedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryFeedHash();

  @override
  String toString() {
    return r'categoryFeedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CategoryFeed create() => CategoryFeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryFeedState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryFeedHash() => r'044938c60794835365ac3a8a23b803aed0d6e442';

final class CategoryFeedFamily extends $Family
    with
        $ClassFamilyOverride<
          CategoryFeed,
          CategoryFeedState,
          CategoryFeedState,
          CategoryFeedState,
          String
        > {
  CategoryFeedFamily._()
    : super(
        retry: null,
        name: r'categoryFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CategoryFeedProvider call(String categoryId) =>
      CategoryFeedProvider._(argument: categoryId, from: this);

  @override
  String toString() => r'categoryFeedProvider';
}

abstract class _$CategoryFeed extends $Notifier<CategoryFeedState> {
  late final _$args = ref.$arg as String;
  String get categoryId => _$args;

  CategoryFeedState build(String categoryId);
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

@ProviderFor(AllPlacesFeed)
final allPlacesFeedProvider = AllPlacesFeedProvider._();

final class AllPlacesFeedProvider
    extends $NotifierProvider<AllPlacesFeed, CategoryFeedState> {
  AllPlacesFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPlacesFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPlacesFeedHash();

  @$internal
  @override
  AllPlacesFeed create() => AllPlacesFeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryFeedState>(value),
    );
  }
}

String _$allPlacesFeedHash() => r'b914c66bfa4d0e2c2f123f946094f47af505fe62';

abstract class _$AllPlacesFeed extends $Notifier<CategoryFeedState> {
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
