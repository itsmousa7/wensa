import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/hyperpay_payment/hyperpay_payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.wensa.mobile/hyperpay');

  Map<Object?, Object?>? capturedArgs;

  void mockNative(Object? Function() handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'submitCardPayment');
          capturedArgs = call.arguments as Map<Object?, Object?>;
          return handler();
        });
  }

  Future<void> submit(HyperpayChannel c) => c.submitCardPayment(
    checkoutId: 'chk_1',
    brand: 'VISA',
    cardNumber: '4111111111111111',
    expiryMonth: '12',
    expiryYear: '39',
    cvv: '123',
    mode: 'TEST',
  );

  test('sends normalized 4-digit year and all fields', () async {
    mockNative(() => 'SYNC');
    await submit(HyperpayChannel());
    expect(capturedArgs!['year'], '2039');
    expect(capturedArgs!['checkoutid'], 'chk_1');
    expect(capturedArgs!['brand'], 'VISA');
    expect(capturedArgs!['mode'], 'TEST');
  });

  test('always sends the fixed card holder, since the form never asks', () async {
    mockNative(() => 'SYNC');
    await submit(HyperpayChannel());
    // Reaches the native layer as OPPCardPaymentParams(holder:) on iOS and
    // CardPaymentParams(..., holder, ...) on Android — i.e. OPPWA card.holder.
    expect(capturedArgs!['holder_name'], 'Wensa App');
    expect(HyperpayChannel.cardHolder, 'Wensa App');
  });

  test('completes on success result', () async {
    mockNative(() => 'success');
    await expectLater(submit(HyperpayChannel()), completes);
  });

  test('maps cancelled PlatformException', () async {
    mockNative(
      () => throw PlatformException(code: 'cancelled', message: 'user closed'),
    );
    await expectLater(
      submit(HyperpayChannel()),
      throwsA(
        isA<HyperpayPaymentException>().having(
          (e) => e.kind,
          'kind',
          HyperpayFailureKind.cancelled,
        ),
      ),
    );
  });

  test('maps unknown error to failed', () async {
    mockNative(
      () => throw PlatformException(
        code: 'transaction_failed',
        message: 'declined',
      ),
    );
    await expectLater(
      submit(HyperpayChannel()),
      throwsA(
        isA<HyperpayPaymentException>().having(
          (e) => e.kind,
          'kind',
          HyperpayFailureKind.failed,
        ),
      ),
    );
  });

  test('unexpected result string throws failed', () async {
    mockNative(() => 'weird');
    await expectLater(
      submit(HyperpayChannel()),
      throwsA(isA<HyperpayPaymentException>()),
    );
  });
}
