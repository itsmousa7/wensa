// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appSettingsRepository)
final appSettingsRepositoryProvider = AppSettingsRepositoryProvider._();

final class AppSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          AppSettingsRepository,
          AppSettingsRepository,
          AppSettingsRepository
        >
    with $Provider<AppSettingsRepository> {
  AppSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppSettingsRepository create(Ref ref) {
    return appSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettingsRepository>(value),
    );
  }
}

String _$appSettingsRepositoryHash() =>
    r'7a9cdcfca98a539241b319ba606e1ad6bec50af9';

@ProviderFor(supportPhone)
final supportPhoneProvider = SupportPhoneProvider._();

final class SupportPhoneProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  SupportPhoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportPhoneProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportPhoneHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return supportPhone(ref);
  }
}

String _$supportPhoneHash() => r'ec7b925217783c7cb03604bf587b92a04d20a943';
