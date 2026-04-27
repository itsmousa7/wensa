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

@ProviderFor(seatingOptions)
final seatingOptionsProvider = SeatingOptionsFamily._();

final class SeatingOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RestaurantSeatingOption>>,
          List<RestaurantSeatingOption>,
          FutureOr<List<RestaurantSeatingOption>>
        >
    with
        $FutureModifier<List<RestaurantSeatingOption>>,
        $FutureProvider<List<RestaurantSeatingOption>> {
  SeatingOptionsProvider._({
    required SeatingOptionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'seatingOptionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$seatingOptionsHash();

  @override
  String toString() {
    return r'seatingOptionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RestaurantSeatingOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RestaurantSeatingOption>> create(Ref ref) {
    final argument = this.argument as String;
    return seatingOptions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SeatingOptionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seatingOptionsHash() => r'aefbe0b09de2034be11d6ee887d6298033e61d31';

final class SeatingOptionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<RestaurantSeatingOption>>,
          String
        > {
  SeatingOptionsFamily._()
    : super(
        retry: null,
        name: r'seatingOptionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SeatingOptionsProvider call(String placeId) =>
      SeatingOptionsProvider._(argument: placeId, from: this);

  @override
  String toString() => r'seatingOptionsProvider';
}

/// Generates 30-minute time slots from 10:00 to 22:00 (Asia/Baghdad, UTC+3).
/// Returns ISO datetime strings stored as UTC (Baghdad - 3h).

@ProviderFor(restaurantTimeSlots)
final restaurantTimeSlotsProvider = RestaurantTimeSlotsFamily._();

/// Generates 30-minute time slots from 10:00 to 22:00 (Asia/Baghdad, UTC+3).
/// Returns ISO datetime strings stored as UTC (Baghdad - 3h).

final class RestaurantTimeSlotsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// Generates 30-minute time slots from 10:00 to 22:00 (Asia/Baghdad, UTC+3).
  /// Returns ISO datetime strings stored as UTC (Baghdad - 3h).
  RestaurantTimeSlotsProvider._({
    required RestaurantTimeSlotsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'restaurantTimeSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$restaurantTimeSlotsHash();

  @override
  String toString() {
    return r'restaurantTimeSlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    final argument = this.argument as String;
    return restaurantTimeSlots(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantTimeSlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$restaurantTimeSlotsHash() =>
    r'406f631b522d8fbeddad300dab79d5b85089c5a4';

/// Generates 30-minute time slots from 10:00 to 22:00 (Asia/Baghdad, UTC+3).
/// Returns ISO datetime strings stored as UTC (Baghdad - 3h).

final class RestaurantTimeSlotsFamily extends $Family
    with $FunctionalFamilyOverride<List<String>, String> {
  RestaurantTimeSlotsFamily._()
    : super(
        retry: null,
        name: r'restaurantTimeSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Generates 30-minute time slots from 10:00 to 22:00 (Asia/Baghdad, UTC+3).
  /// Returns ISO datetime strings stored as UTC (Baghdad - 3h).

  RestaurantTimeSlotsProvider call(String date) =>
      RestaurantTimeSlotsProvider._(argument: date, from: this);

  @override
  String toString() => r'restaurantTimeSlotsProvider';
}
