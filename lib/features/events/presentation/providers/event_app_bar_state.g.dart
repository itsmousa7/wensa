// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_app_bar_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventAppbarState)
final eventAppbarStateProvider = EventAppbarStateFamily._();

final class EventAppbarStateProvider
    extends $NotifierProvider<EventAppbarState, EventAppBarDetailsState> {
  EventAppbarStateProvider._({
    required EventAppbarStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventAppbarStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventAppbarStateHash();

  @override
  String toString() {
    return r'eventAppbarStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventAppbarState create() => EventAppbarState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventAppBarDetailsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventAppBarDetailsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventAppbarStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventAppbarStateHash() => r'490a6b19cfd7aedbf9fe6c135897ff6e1f425095';

final class EventAppbarStateFamily extends $Family
    with
        $ClassFamilyOverride<
          EventAppbarState,
          EventAppBarDetailsState,
          EventAppBarDetailsState,
          EventAppBarDetailsState,
          String
        > {
  EventAppbarStateFamily._()
    : super(
        retry: null,
        name: r'eventAppbarStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventAppbarStateProvider call(String eventId) =>
      EventAppbarStateProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventAppbarStateProvider';
}

abstract class _$EventAppbarState extends $Notifier<EventAppBarDetailsState> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  EventAppBarDetailsState build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<EventAppBarDetailsState, EventAppBarDetailsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventAppBarDetailsState, EventAppBarDetailsState>,
              EventAppBarDetailsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
