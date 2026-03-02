// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedCategory)
final selectedCategoryProvider = SelectedCategoryProvider._();

final class SelectedCategoryProvider
    extends $NotifierProvider<SelectedCategory, int?> {
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
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$selectedCategoryHash() => r'243f684ddabc3d33d7aa92490723d6d6bb36e1ca';

abstract class _$SelectedCategory extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

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

String _$categoryFeedHash() => r'fbf1710b0afd6d6e6750680d5bd13c523edf8092';

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
