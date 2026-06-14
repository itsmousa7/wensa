import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

const _seenOnboardingKey = 'has_seen_onboarding';

/// Tracks whether the user has completed the first-launch onboarding.
///
/// State is `null` while the SharedPreferences value is still loading — the
/// router stays on `/splash` during that window (same gating pattern as
/// `isProfileCompleteProvider`) so returning users never flash the onboarding.
@Riverpod(keepAlive: true)
class HasSeenOnboarding extends _$HasSeenOnboarding {
  @override
  bool? build() {
    _load();
    return null; // unknown until SharedPreferences resolves
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_seenOnboardingKey) ?? false;
  }

  /// Marks onboarding as completed and persists it. Updates state immediately
  /// so the router redirect can react without waiting on disk.
  Future<void> complete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenOnboardingKey, true);
  }
}
