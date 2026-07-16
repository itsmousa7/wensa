// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_cards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
/// select/delete to the caller; inserts happen server-side (verify-payment).

@ProviderFor(SavedCards)
final savedCardsProvider = SavedCardsProvider._();

/// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
/// select/delete to the caller; inserts happen server-side (verify-payment).
final class SavedCardsProvider
    extends $AsyncNotifierProvider<SavedCards, List<SavedCard>> {
  /// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
  /// select/delete to the caller; inserts happen server-side (verify-payment).
  SavedCardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedCardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedCardsHash();

  @$internal
  @override
  SavedCards create() => SavedCards();
}

String _$savedCardsHash() => r'c47b8d642ba833465d1f0eb48a5c90364812965e';

/// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
/// select/delete to the caller; inserts happen server-side (verify-payment).

abstract class _$SavedCards extends $AsyncNotifier<List<SavedCard>> {
  FutureOr<List<SavedCard>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SavedCard>>, List<SavedCard>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SavedCard>>, List<SavedCard>>,
              AsyncValue<List<SavedCard>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
