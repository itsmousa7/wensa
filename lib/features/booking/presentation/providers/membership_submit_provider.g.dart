// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_submit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MembershipSubmit)
final membershipSubmitProvider = MembershipSubmitProvider._();

final class MembershipSubmitProvider
    extends $NotifierProvider<MembershipSubmit, BookingSubmitState> {
  MembershipSubmitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipSubmitHash();

  @$internal
  @override
  MembershipSubmit create() => MembershipSubmit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingSubmitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingSubmitState>(value),
    );
  }
}

String _$membershipSubmitHash() => r'f0c76008fa7cd677130e1eadf0ef36c3346331e5';

abstract class _$MembershipSubmit extends $Notifier<BookingSubmitState> {
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
