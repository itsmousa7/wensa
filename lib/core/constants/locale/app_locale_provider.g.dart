// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

final class AppLocaleProvider
    extends $NotifierProvider<AppLocale, LocaleState> {
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  AppLocale create() => AppLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocaleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocaleState>(value),
    );
  }
}

String _$appLocaleHash() => r'44dce62d833ba5165683d115bbb259484783edfe';

abstract class _$AppLocale extends $Notifier<LocaleState> {
  LocaleState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LocaleState, LocaleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocaleState, LocaleState>,
              LocaleState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
