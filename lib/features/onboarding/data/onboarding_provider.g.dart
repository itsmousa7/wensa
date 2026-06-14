// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks whether the user has completed the first-launch onboarding.
///
/// State is `null` while the SharedPreferences value is still loading — the
/// router stays on `/splash` during that window (same gating pattern as
/// `isProfileCompleteProvider`) so returning users never flash the onboarding.

@ProviderFor(HasSeenOnboarding)
final hasSeenOnboardingProvider = HasSeenOnboardingProvider._();

/// Tracks whether the user has completed the first-launch onboarding.
///
/// State is `null` while the SharedPreferences value is still loading — the
/// router stays on `/splash` during that window (same gating pattern as
/// `isProfileCompleteProvider`) so returning users never flash the onboarding.
final class HasSeenOnboardingProvider
    extends $NotifierProvider<HasSeenOnboarding, bool?> {
  /// Tracks whether the user has completed the first-launch onboarding.
  ///
  /// State is `null` while the SharedPreferences value is still loading — the
  /// router stays on `/splash` during that window (same gating pattern as
  /// `isProfileCompleteProvider`) so returning users never flash the onboarding.
  HasSeenOnboardingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasSeenOnboardingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasSeenOnboardingHash();

  @$internal
  @override
  HasSeenOnboarding create() => HasSeenOnboarding();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool?>(value),
    );
  }
}

String _$hasSeenOnboardingHash() => r'95d4bd6ff55fe7c2de728aba54b3d6fdc3635d2f';

/// Tracks whether the user has completed the first-launch onboarding.
///
/// State is `null` while the SharedPreferences value is still loading — the
/// router stays on `/splash` during that window (same gating pattern as
/// `isProfileCompleteProvider`) so returning users never flash the onboarding.

abstract class _$HasSeenOnboarding extends $Notifier<bool?> {
  bool? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool?, bool?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool?, bool?>,
              bool?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
