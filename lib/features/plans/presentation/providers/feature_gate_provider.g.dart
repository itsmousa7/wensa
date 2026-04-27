// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_gate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns the FeatureGate for a given merchant.

@ProviderFor(featureGate)
final featureGateProvider = FeatureGateFamily._();

/// Returns the FeatureGate for a given merchant.

final class FeatureGateProvider
    extends
        $FunctionalProvider<
          AsyncValue<FeatureGate>,
          FeatureGate,
          FutureOr<FeatureGate>
        >
    with $FutureModifier<FeatureGate>, $FutureProvider<FeatureGate> {
  /// Returns the FeatureGate for a given merchant.
  FeatureGateProvider._({
    required FeatureGateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'featureGateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$featureGateHash();

  @override
  String toString() {
    return r'featureGateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FeatureGate> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FeatureGate> create(Ref ref) {
    final argument = this.argument as String;
    return featureGate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureGateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$featureGateHash() => r'f1a4f0b0dcfb743a5fe24799664f82e7c47f7bd4';

/// Returns the FeatureGate for a given merchant.

final class FeatureGateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FeatureGate>, String> {
  FeatureGateFamily._()
    : super(
        retry: null,
        name: r'featureGateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns the FeatureGate for a given merchant.

  FeatureGateProvider call(String merchantId) =>
      FeatureGateProvider._(argument: merchantId, from: this);

  @override
  String toString() => r'featureGateProvider';
}

/// Can the merchant add another place or event?
/// [currentCombinedCount] = places + active events combined.

@ProviderFor(canAddItem)
final canAddItemProvider = CanAddItemFamily._();

/// Can the merchant add another place or event?
/// [currentCombinedCount] = places + active events combined.

final class CanAddItemProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Can the merchant add another place or event?
  /// [currentCombinedCount] = places + active events combined.
  CanAddItemProvider._({
    required CanAddItemFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'canAddItemProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canAddItemHash();

  @override
  String toString() {
    return r'canAddItemProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, int);
    return canAddItem(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CanAddItemProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canAddItemHash() => r'b37f47b95b4616ef32fd5803a4cd086b020eb1b2';

/// Can the merchant add another place or event?
/// [currentCombinedCount] = places + active events combined.

final class CanAddItemFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, (String, int)> {
  CanAddItemFamily._()
    : super(
        retry: null,
        name: r'canAddItemProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Can the merchant add another place or event?
  /// [currentCombinedCount] = places + active events combined.

  CanAddItemProvider call(String merchantId, int currentCombinedCount) =>
      CanAddItemProvider._(
        argument: (merchantId, currentCombinedCount),
        from: this,
      );

  @override
  String toString() => r'canAddItemProvider';
}

/// Can the merchant add another photo to a place?

@ProviderFor(canAddPhoto)
final canAddPhotoProvider = CanAddPhotoFamily._();

/// Can the merchant add another photo to a place?

final class CanAddPhotoProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Can the merchant add another photo to a place?
  CanAddPhotoProvider._({
    required CanAddPhotoFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'canAddPhotoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canAddPhotoHash();

  @override
  String toString() {
    return r'canAddPhotoProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, int);
    return canAddPhoto(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CanAddPhotoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canAddPhotoHash() => r'65d8f99aba10af0e6b5489278fc112f3dbaf41f2';

/// Can the merchant add another photo to a place?

final class CanAddPhotoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, (String, int)> {
  CanAddPhotoFamily._()
    : super(
        retry: null,
        name: r'canAddPhotoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Can the merchant add another photo to a place?

  CanAddPhotoProvider call(String merchantId, int currentAdditionalCount) =>
      CanAddPhotoProvider._(
        argument: (merchantId, currentAdditionalCount),
        from: this,
      );

  @override
  String toString() => r'canAddPhotoProvider';
}
