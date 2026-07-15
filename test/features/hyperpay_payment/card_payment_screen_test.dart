import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/hyperpay_payment/presentation/screens/card_payment_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('PAY is disabled until the form is valid', (tester) async {
    await tester.pumpWidget(_wrap(const CardPaymentScreen(
      checkoutId: 'chk_1',
      referenceId: 'ref_1',
      entityKindForVerify: 'booking',
      entityId: 'b1',
      paymentMode: 'TEST',
    )));

    final payButton = find.widgetWithText(FilledButton, 'Pay');
    expect(tester.widget<FilledButton>(payButton).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('card_number')), '4111111111111111');
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry_month')), '12');
    await tester.enterText(find.byKey(const Key('expiry_year')), '39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    expect(tester.widget<FilledButton>(payButton).onPressed, isNotNull);
  });

  testWidgets('invalid Luhn number keeps PAY disabled', (tester) async {
    await tester.pumpWidget(_wrap(const CardPaymentScreen(
      checkoutId: 'chk_1',
      referenceId: 'ref_1',
      entityKindForVerify: 'booking',
      entityId: 'b1',
      paymentMode: 'TEST',
    )));

    await tester.enterText(find.byKey(const Key('card_number')), '4111111111111112');
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry_month')), '12');
    await tester.enterText(find.byKey(const Key('expiry_year')), '39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    final payButton = find.widgetWithText(FilledButton, 'Pay');
    expect(tester.widget<FilledButton>(payButton).onPressed, isNull);
  });
}
