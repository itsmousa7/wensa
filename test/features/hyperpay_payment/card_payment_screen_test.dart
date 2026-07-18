import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/core/widgets/primary_action_button.dart';
import 'package:future_riverpod/features/hyperpay_payment/hyperpay_payment.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

class _FakeLockService extends BookingLockService {
  const _FakeLockService({this.locked = true});
  final bool locked;
  @override
  Future<bool> lockForPayment({
    required String kind,
    required String id,
  }) async => locked;
}

class _FakeChannel extends HyperpayChannel {
  const _FakeChannel();
  @override
  Future<void> submitCardPayment({
    required String checkoutId,
    required String brand,
    required String cardNumber,
    required String holderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String mode,
  }) async {}
}

class _RecordingChannel extends HyperpayChannel {
  bool submitCalled = false;
  @override
  Future<void> submitCardPayment({
    required String checkoutId,
    required String brand,
    required String cardNumber,
    required String holderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String mode,
  }) async {
    submitCalled = true;
  }
}

class _RecordingVerifyService extends HyperpayVerifyService {
  _RecordingVerifyService();
  bool? lastSaveCard;
  @override
  Future<VerifyResult> verify({
    required String checkoutId,
    required String kind,
    required String id,
    required String referenceId,
    bool saveCard = false,
  }) async {
    lastSaveCard = saveCard;
    return const VerifyResult(paid: true);
  }
}

class _DecliningVerifyService extends HyperpayVerifyService {
  @override
  Future<VerifyResult> verify({
    required String checkoutId,
    required String kind,
    required String id,
    required String referenceId,
    bool saveCard = false,
  }) async => const VerifyResult(paid: false, description: 'declined');
}

void main() {
  testWidgets('PAY is disabled until the form is valid', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CardPaymentScreen(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
        ),
      ),
    );

    final payButton = find.byType(PrimaryActionButton);
    expect(tester.widget<PrimaryActionButton>(payButton).onTap, isNull);

    await tester.enterText(
      find.byKey(const Key('card_number')),
      '4111111111111111',
    );
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry')), '12/39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    expect(tester.widget<PrimaryActionButton>(payButton).onTap, isNotNull);
  });

  testWidgets('invalid Luhn number keeps PAY disabled', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CardPaymentScreen(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('card_number')),
      '4111111111111112',
    );
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry')), '12/39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    final payButton = find.byType(PrimaryActionButton);
    expect(tester.widget<PrimaryActionButton>(payButton).onTap, isNull);
  });

  testWidgets('save-card defaults to true and is passed through to verify', (
    tester,
  ) async {
    final verify = _RecordingVerifyService();
    await tester.pumpWidget(
      _wrap(
        CardPaymentScreen(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
          channel: const _FakeChannel(),
          verifyService: verify,
          lockService: const _FakeLockService(),
          onPaymentSuccess: (_, _, _) {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('card_number')),
      '4111111111111111',
    );
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry')), '12/39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    // Default is checked — paying without touching the toggle still saves.
    await tester.tap(find.byType(PrimaryActionButton));
    await tester.pumpAndSettle();
    expect(verify.lastSaveCard, isTrue);
  });

  testWidgets('unchecking save-card is passed through to verify', (
    tester,
  ) async {
    final verify = _RecordingVerifyService();
    await tester.pumpWidget(
      _wrap(
        CardPaymentScreen(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
          channel: const _FakeChannel(),
          verifyService: verify,
          lockService: const _FakeLockService(),
          onPaymentSuccess: (_, _, _) {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('card_number')),
      '4111111111111111',
    );
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry')), '12/39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_card_toggle')));
    await tester.pump();

    await tester.tap(find.byType(PrimaryActionButton));
    await tester.pumpAndSettle();

    expect(verify.lastSaveCard, isFalse);
  });

  testWidgets(
    'declined verify without a server txn id falls back to booking-{id}',
    (tester) async {
      String? failedTxnId;
      await tester.pumpWidget(
        _wrap(
          CardPaymentScreen(
            checkoutId: 'chk_1',
            referenceId: 'ref_1',
            entityKindForVerify: 'booking',
            entityId: 'b1',
            paymentMode: 'TEST',
            channel: const _FakeChannel(),
            verifyService: _DecliningVerifyService(),
            lockService: const _FakeLockService(),
            onPaymentFailed: (_, txnId) => failedTxnId = txnId,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('card_number')),
        '4111111111111111',
      );
      await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
      await tester.enterText(find.byKey(const Key('expiry')), '12/39');
      await tester.enterText(find.byKey(const Key('cvv')), '123');
      await tester.pump();

      await tester.tap(find.byType(PrimaryActionButton));
      await tester.pumpAndSettle();

      expect(failedTxnId, 'booking-b1');
    },
  );

  testWidgets('expired hold blocks the charge and shows an error', (
    tester,
  ) async {
    final channel = _RecordingChannel();
    await tester.pumpWidget(
      _wrap(
        CardPaymentScreen(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
          channel: channel,
          lockService: const _FakeLockService(locked: false),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('card_number')),
      '4111111111111111',
    );
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry')), '12/39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    await tester.tap(find.byType(PrimaryActionButton));
    await tester.pumpAndSettle();

    expect(channel.submitCalled, isFalse);
    expect(
      find.text('This slot is no longer available. Please start again.'),
      findsOneWidget,
    );
  });
}
