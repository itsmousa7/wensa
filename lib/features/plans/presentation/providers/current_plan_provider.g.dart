// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_plan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All subscription plans (for the comparison page).

@ProviderFor(allPlans)
final allPlansProvider = AllPlansProvider._();

/// All subscription plans (for the comparison page).

final class AllPlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanModel>>,
          List<PlanModel>,
          FutureOr<List<PlanModel>>
        >
    with $FutureModifier<List<PlanModel>>, $FutureProvider<List<PlanModel>> {
  /// All subscription plans (for the comparison page).
  AllPlansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPlansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPlansHash();

  @$internal
  @override
  $FutureProviderElement<List<PlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanModel>> create(Ref ref) {
    return allPlans(ref);
  }
}

String _$allPlansHash() => r'bd2f10b3e9bb78fe58ac735f3e0e77c9210ed59b';

/// Current merchant's full plan state.

@ProviderFor(merchantPlanState)
final merchantPlanStateProvider = MerchantPlanStateFamily._();

/// Current merchant's full plan state.

final class MerchantPlanStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<MerchantPlanState>,
          MerchantPlanState,
          FutureOr<MerchantPlanState>
        >
    with
        $FutureModifier<MerchantPlanState>,
        $FutureProvider<MerchantPlanState> {
  /// Current merchant's full plan state.
  MerchantPlanStateProvider._({
    required MerchantPlanStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'merchantPlanStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$merchantPlanStateHash();

  @override
  String toString() {
    return r'merchantPlanStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MerchantPlanState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MerchantPlanState> create(Ref ref) {
    final argument = this.argument as String;
    return merchantPlanState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MerchantPlanStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$merchantPlanStateHash() => r'87cc1ca589581c8eeb92c8e90b60250aaa5ef995';

/// Current merchant's full plan state.

final class MerchantPlanStateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MerchantPlanState>, String> {
  MerchantPlanStateFamily._()
    : super(
        retry: null,
        name: r'merchantPlanStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Current merchant's full plan state.

  MerchantPlanStateProvider call(String merchantId) =>
      MerchantPlanStateProvider._(argument: merchantId, from: this);

  @override
  String toString() => r'merchantPlanStateProvider';
}

/// Current combined item count (places + active events) for quota display.

@ProviderFor(combinedItemCount)
final combinedItemCountProvider = CombinedItemCountFamily._();

/// Current combined item count (places + active events) for quota display.

final class CombinedItemCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Current combined item count (places + active events) for quota display.
  CombinedItemCountProvider._({
    required CombinedItemCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'combinedItemCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$combinedItemCountHash();

  @override
  String toString() {
    return r'combinedItemCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return combinedItemCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CombinedItemCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$combinedItemCountHash() => r'f3a176314da4e78922886bbadf4bf4944b926bed';

/// Current combined item count (places + active events) for quota display.

final class CombinedItemCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  CombinedItemCountFamily._()
    : super(
        retry: null,
        name: r'combinedItemCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Current combined item count (places + active events) for quota display.

  CombinedItemCountProvider call(String merchantId) =>
      CombinedItemCountProvider._(argument: merchantId, from: this);

  @override
  String toString() => r'combinedItemCountProvider';
}

/// Notifier that triggers a plan change and exposes the result.
/// UI checks [PlanChangeResult.paymentUrl] — if set, opens browser.

@ProviderFor(PlanChanger)
final planChangerProvider = PlanChangerProvider._();

/// Notifier that triggers a plan change and exposes the result.
/// UI checks [PlanChangeResult.paymentUrl] — if set, opens browser.
final class PlanChangerProvider
    extends $NotifierProvider<PlanChanger, AsyncValue<PlanChangeResult?>> {
  /// Notifier that triggers a plan change and exposes the result.
  /// UI checks [PlanChangeResult.paymentUrl] — if set, opens browser.
  PlanChangerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planChangerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planChangerHash();

  @$internal
  @override
  PlanChanger create() => PlanChanger();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<PlanChangeResult?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<PlanChangeResult?>>(
        value,
      ),
    );
  }
}

String _$planChangerHash() => r'67a090be6191d4dea2d6730d8af600ca19b98358';

/// Notifier that triggers a plan change and exposes the result.
/// UI checks [PlanChangeResult.paymentUrl] — if set, opens browser.

abstract class _$PlanChanger extends $Notifier<AsyncValue<PlanChangeResult?>> {
  AsyncValue<PlanChangeResult?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<PlanChangeResult?>,
              AsyncValue<PlanChangeResult?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PlanChangeResult?>,
                AsyncValue<PlanChangeResult?>
              >,
              AsyncValue<PlanChangeResult?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
