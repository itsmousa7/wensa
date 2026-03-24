// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventDetails)
final eventDetailsProvider = EventDetailsFamily._();

final class EventDetailsProvider
    extends $AsyncNotifierProvider<EventDetails, EventModel> {
  EventDetailsProvider._({
    required EventDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventDetailsHash();

  @override
  String toString() {
    return r'eventDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventDetails create() => EventDetails();

  @override
  bool operator ==(Object other) {
    return other is EventDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventDetailsHash() => r'6b44dcfa8eee161c4d8a3a675da2edebb58f7490';

final class EventDetailsFamily extends $Family
    with
        $ClassFamilyOverride<
          EventDetails,
          AsyncValue<EventModel>,
          EventModel,
          FutureOr<EventModel>,
          String
        > {
  EventDetailsFamily._()
    : super(
        retry: null,
        name: r'eventDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventDetailsProvider call(String eventId) =>
      EventDetailsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventDetailsProvider';
}

abstract class _$EventDetails extends $AsyncNotifier<EventModel> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<EventModel> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EventModel>, EventModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EventModel>, EventModel>,
              AsyncValue<EventModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
