// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_realtime_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MembershipRealtimeSync)
final membershipRealtimeSyncProvider = MembershipRealtimeSyncFamily._();

final class MembershipRealtimeSyncProvider
    extends $NotifierProvider<MembershipRealtimeSync, void> {
  MembershipRealtimeSyncProvider._({
    required MembershipRealtimeSyncFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'membershipRealtimeSyncProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$membershipRealtimeSyncHash();

  @override
  String toString() {
    return r'membershipRealtimeSyncProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MembershipRealtimeSync create() => MembershipRealtimeSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MembershipRealtimeSyncProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$membershipRealtimeSyncHash() =>
    r'3d176df6727b8c0da5b28d1a1fec526aa1a0f1dd';

final class MembershipRealtimeSyncFamily extends $Family
    with
        $ClassFamilyOverride<MembershipRealtimeSync, void, void, void, String> {
  MembershipRealtimeSyncFamily._()
    : super(
        retry: null,
        name: r'membershipRealtimeSyncProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MembershipRealtimeSyncProvider call(String membershipId) =>
      MembershipRealtimeSyncProvider._(argument: membershipId, from: this);

  @override
  String toString() => r'membershipRealtimeSyncProvider';
}

abstract class _$MembershipRealtimeSync extends $Notifier<void> {
  late final _$args = ref.$arg as String;
  String get membershipId => _$args;

  void build(String membershipId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
