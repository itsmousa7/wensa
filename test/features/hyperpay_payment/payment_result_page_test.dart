import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/hyperpay_payment/hyperpay_payment.dart';

Widget _host(PaymentResultPage page) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => page)),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

/// Opens [page] and pumps just past the entrance animation — deliberately not
/// pumpAndSettle, which would fast-forward through the countdown and pop the
/// page before the test can assert on it.
Future<void> _open(WidgetTester tester, PaymentResultPage page) async {
  await tester.pumpWidget(_host(page));
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
}

void main() {
  testWidgets('success shows thank-you card with the transaction id', (
    tester,
  ) async {
    await _open(
      tester,
      const PaymentResultPage(
        success: true,
        merchantTransactionId: 'booking-xyz',
        countdown: Duration(seconds: 5),
      ),
    );

    expect(find.text('Thank you!'), findsOneWidget);
    expect(find.byKey(const Key('payment_result_txn_id')), findsOneWidget);
    expect(find.text('booking-xyz'), findsOneWidget);
  });

  testWidgets('failure shows HyperPay description', (tester) async {
    await _open(
      tester,
      const PaymentResultPage(
        success: false,
        message: 'transaction declined by authorization system',
      ),
    );

    expect(find.text('Payment failed'), findsOneWidget);
    expect(
      find.text('transaction declined by authorization system'),
      findsOneWidget,
    );
  });

  testWidgets('failure without description falls back to generic copy', (
    tester,
  ) async {
    await _open(tester, const PaymentResultPage(success: false));

    expect(
      find.text('Your payment could not be completed. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('transaction id is shown on both outcomes and copies on tap', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _open(
      tester,
      const PaymentResultPage(
        success: false,
        message: 'declined',
        merchantTransactionId: 'booking-abc123',
      ),
    );

    expect(find.byKey(const Key('payment_result_txn_id')), findsOneWidget);
    expect(find.text('booking-abc123'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payment_result_txn_copy')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(copied, ['booking-abc123']);
    expect(find.text('Copied'), findsOneWidget);
    // Page must still be open — copying is not the skip gesture.
    expect(find.text('Payment failed'), findsOneWidget);

    // The badge reverts after a couple of seconds (plus switcher transition).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Copied'), findsNothing);
  });

  testWidgets('renders Arabic strings under the ar locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('en'), Locale('ar')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: PaymentResultPage(
          success: true,
          merchantTransactionId: 'booking-abc',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('شكراً لك!'), findsOneWidget);
    expect(find.text('تم تأكيد حجزك بنجاح'), findsOneWidget);
    expect(find.text('التاريخ والوقت'), findsOneWidget);
    expect(find.text('رقم العملية'), findsOneWidget);
    expect(find.text('اضغط في أي مكان للمتابعة'), findsOneWidget);
  });

  testWidgets('no transaction row when merchant txn id is absent', (
    tester,
  ) async {
    await _open(tester, const PaymentResultPage(success: true));

    expect(find.byKey(const Key('payment_result_txn_id')), findsNothing);
  });

  testWidgets('countdown elapsing pops the page and fires onDone', (
    tester,
  ) async {
    var done = 0;
    await _open(
      tester,
      PaymentResultPage(
        success: true,
        countdown: const Duration(seconds: 2),
        onDone: () => done++,
      ),
    );

    expect(done, 0);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(find.text('Thank you!'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('tapping the countdown ring skips the wait', (tester) async {
    var done = 0;
    await _open(
      tester,
      PaymentResultPage(
        success: false,
        message: 'declined',
        countdown: const Duration(seconds: 30),
        onDone: () => done++,
      ),
    );

    await tester.tap(find.byKey(const Key('payment_result_countdown')));
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(find.text('Payment failed'), findsNothing);
  });
}
