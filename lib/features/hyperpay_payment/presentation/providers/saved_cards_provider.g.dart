// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_cards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
/// select to the caller; inserts happen server-side (verify-payment) and
/// removal goes through the hyperpay-deregister-tokens edge function, which
/// revokes the token at the gateway before deleting the row.

@ProviderFor(SavedCards)
final savedCardsProvider = SavedCardsProvider._();

/// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
/// select to the caller; inserts happen server-side (verify-payment) and
/// removal goes through the hyperpay-deregister-tokens edge function, which
/// revokes the token at the gateway before deleting the row.
final class SavedCardsProvider
    extends $AsyncNotifierProvider<SavedCards, List<SavedCard>> {
  /// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
  /// select to the caller; inserts happen server-side (verify-payment) and
  /// removal goes through the hyperpay-deregister-tokens edge function, which
  /// revokes the token at the gateway before deleting the row.
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

String _$savedCardsHash() => r'9c6f20c17f809c6b91a0a033733d44c9de7e0db6';

/// The signed-in user's saved HyperPay cards (newest first). RLS scopes the
/// select to the caller; inserts happen server-side (verify-payment) and
/// removal goes through the hyperpay-deregister-tokens edge function, which
/// revokes the token at the gateway before deleting the row.

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
