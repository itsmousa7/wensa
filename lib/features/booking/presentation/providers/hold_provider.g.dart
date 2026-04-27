// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hold_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HoldCountdown)
final holdCountdownProvider = HoldCountdownFamily._();

final class HoldCountdownProvider
    extends $NotifierProvider<HoldCountdown, int> {
  HoldCountdownProvider._({
    required HoldCountdownFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'holdCountdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$holdCountdownHash();

  @override
  String toString() {
    return r'holdCountdownProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HoldCountdown create() => HoldCountdown();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HoldCountdownProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$holdCountdownHash() => r'8ea1e6bc0ea4ebe89201d33fd624456e8c6edb0d';

final class HoldCountdownFamily extends $Family
    with $ClassFamilyOverride<HoldCountdown, int, int, int, String> {
  HoldCountdownFamily._()
    : super(
        retry: null,
        name: r'holdCountdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HoldCountdownProvider call(String holdUntil) =>
      HoldCountdownProvider._(argument: holdUntil, from: this);

  @override
  String toString() => r'holdCountdownProvider';
}

abstract class _$HoldCountdown extends $Notifier<int> {
  late final _$args = ref.$arg as String;
  String get holdUntil => _$args;

  int build(String holdUntil);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
