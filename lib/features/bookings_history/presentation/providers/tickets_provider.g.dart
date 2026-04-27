// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tickets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userBookings)
final userBookingsProvider = UserBookingsFamily._();

final class UserBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Booking>>,
          List<Booking>,
          FutureOr<List<Booking>>
        >
    with $FutureModifier<List<Booking>>, $FutureProvider<List<Booking>> {
  UserBookingsProvider._({
    required UserBookingsFamily super.from,
    required BookingCategory? super.argument,
  }) : super(
         retry: null,
         name: r'userBookingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userBookingsHash();

  @override
  String toString() {
    return r'userBookingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Booking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Booking>> create(Ref ref) {
    final argument = this.argument as BookingCategory?;
    return userBookings(ref, category: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserBookingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userBookingsHash() => r'91abcd3efe588a7460f904b798453f6eddc6c7b6';

final class UserBookingsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Booking>>, BookingCategory?> {
  UserBookingsFamily._()
    : super(
        retry: null,
        name: r'userBookingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserBookingsProvider call({BookingCategory? category}) =>
      UserBookingsProvider._(argument: category, from: this);

  @override
  String toString() => r'userBookingsProvider';
}

@ProviderFor(userMemberships)
final userMembershipsProvider = UserMembershipsProvider._();

final class UserMembershipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Membership>>,
          List<Membership>,
          FutureOr<List<Membership>>
        >
    with $FutureModifier<List<Membership>>, $FutureProvider<List<Membership>> {
  UserMembershipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userMembershipsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userMembershipsHash();

  @$internal
  @override
  $FutureProviderElement<List<Membership>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Membership>> create(Ref ref) {
    return userMemberships(ref);
  }
}

String _$userMembershipsHash() => r'394a3570795852afcba55455f5590269d36d5af0';

@ProviderFor(bookingDetail)
final bookingDetailProvider = BookingDetailFamily._();

final class BookingDetailProvider
    extends $FunctionalProvider<AsyncValue<Booking>, Booking, FutureOr<Booking>>
    with $FutureModifier<Booking>, $FutureProvider<Booking> {
  BookingDetailProvider._({
    required BookingDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookingDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookingDetailHash();

  @override
  String toString() {
    return r'bookingDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Booking> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Booking> create(Ref ref) {
    final argument = this.argument as String;
    return bookingDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingDetailHash() => r'c3fc1ddf93e2f0ef19bd3ead98acc3c4fc43d6ea';

final class BookingDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Booking>, String> {
  BookingDetailFamily._()
    : super(
        retry: null,
        name: r'bookingDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BookingDetailProvider call(String id) =>
      BookingDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'bookingDetailProvider';
}
