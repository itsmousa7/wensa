// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_submit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BookingSubmit)
final bookingSubmitProvider = BookingSubmitProvider._();

final class BookingSubmitProvider
    extends $NotifierProvider<BookingSubmit, BookingSubmitState> {
  BookingSubmitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingSubmitHash();

  @$internal
  @override
  BookingSubmit create() => BookingSubmit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingSubmitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingSubmitState>(value),
    );
  }
}

String _$bookingSubmitHash() => r'e1961f55b60d5397602855d35efd1040128cb136';

abstract class _$BookingSubmit extends $Notifier<BookingSubmitState> {
  BookingSubmitState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BookingSubmitState, BookingSubmitState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BookingSubmitState, BookingSubmitState>,
              BookingSubmitState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
