// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(courts)
final courtsProvider = CourtsFamily._();

final class CourtsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Court>>,
          List<Court>,
          FutureOr<List<Court>>
        >
    with $FutureModifier<List<Court>>, $FutureProvider<List<Court>> {
  CourtsProvider._({
    required CourtsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'courtsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courtsHash();

  @override
  String toString() {
    return r'courtsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Court>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Court>> create(Ref ref) {
    final argument = this.argument as String;
    return courts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CourtsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courtsHash() => r'7864ff488637f37e9bf3be5d192ae3e8e92d47b9';

final class CourtsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Court>>, String> {
  CourtsFamily._()
    : super(
        retry: null,
        name: r'courtsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CourtsProvider call(String placeId) =>
      CourtsProvider._(argument: placeId, from: this);

  @override
  String toString() => r'courtsProvider';
}

@ProviderFor(availableSlots)
final availableSlotsProvider = AvailableSlotsFamily._();

final class AvailableSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Slot>>,
          List<Slot>,
          FutureOr<List<Slot>>
        >
    with $FutureModifier<List<Slot>>, $FutureProvider<List<Slot>> {
  AvailableSlotsProvider._({
    required AvailableSlotsFamily super.from,
    required ({String courtId, String date}) super.argument,
  }) : super(
         retry: null,
         name: r'availableSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$availableSlotsHash();

  @override
  String toString() {
    return r'availableSlotsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Slot>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Slot>> create(Ref ref) {
    final argument = this.argument as ({String courtId, String date});
    return availableSlots(ref, courtId: argument.courtId, date: argument.date);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableSlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availableSlotsHash() => r'391c6cc7a6407a81899ba8ccecbaa89130b7128c';

final class AvailableSlotsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Slot>>,
          ({String courtId, String date})
        > {
  AvailableSlotsFamily._()
    : super(
        retry: null,
        name: r'availableSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AvailableSlotsProvider call({
    required String courtId,
    required String date,
  }) => AvailableSlotsProvider._(
    argument: (courtId: courtId, date: date),
    from: this,
  );

  @override
  String toString() => r'availableSlotsProvider';
}

@ProviderFor(farmShifts)
final farmShiftsProvider = FarmShiftsFamily._();

final class FarmShiftsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FarmShift>>,
          List<FarmShift>,
          FutureOr<List<FarmShift>>
        >
    with $FutureModifier<List<FarmShift>>, $FutureProvider<List<FarmShift>> {
  FarmShiftsProvider._({
    required FarmShiftsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'farmShiftsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$farmShiftsHash();

  @override
  String toString() {
    return r'farmShiftsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FarmShift>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FarmShift>> create(Ref ref) {
    final argument = this.argument as String;
    return farmShifts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FarmShiftsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$farmShiftsHash() => r'604db61ea0ed1094844588e5f618e830b6a89b43';

final class FarmShiftsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FarmShift>>, String> {
  FarmShiftsFamily._()
    : super(
        retry: null,
        name: r'farmShiftsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FarmShiftsProvider call(String placeId) =>
      FarmShiftsProvider._(argument: placeId, from: this);

  @override
  String toString() => r'farmShiftsProvider';
}
