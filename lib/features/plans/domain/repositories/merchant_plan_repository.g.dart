// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_plan_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(merchantPlanRepository)
final merchantPlanRepositoryProvider = MerchantPlanRepositoryProvider._();

final class MerchantPlanRepositoryProvider
    extends
        $FunctionalProvider<
          MerchantPlanRepository,
          MerchantPlanRepository,
          MerchantPlanRepository
        >
    with $Provider<MerchantPlanRepository> {
  MerchantPlanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantPlanRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantPlanRepositoryHash();

  @$internal
  @override
  $ProviderElement<MerchantPlanRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MerchantPlanRepository create(Ref ref) {
    return merchantPlanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MerchantPlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MerchantPlanRepository>(value),
    );
  }
}

String _$merchantPlanRepositoryHash() =>
    r'7ca5c972658cd9e8d267ac297e212b5b1ca38788';
