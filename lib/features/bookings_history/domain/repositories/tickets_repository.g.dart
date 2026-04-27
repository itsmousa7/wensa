// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tickets_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticketsRepository)
final ticketsRepositoryProvider = TicketsRepositoryProvider._();

final class TicketsRepositoryProvider
    extends
        $FunctionalProvider<
          TicketsRepository,
          TicketsRepository,
          TicketsRepository
        >
    with $Provider<TicketsRepository> {
  TicketsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TicketsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TicketsRepository create(Ref ref) {
    return ticketsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketsRepository>(value),
    );
  }
}

String _$ticketsRepositoryHash() => r'c0b8a3113700d582964641f57d62ad66694e0e83';
