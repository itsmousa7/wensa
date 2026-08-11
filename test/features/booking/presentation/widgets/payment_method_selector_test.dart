import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/payment_method_selector.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows both rows when cashEnabled is true', (tester) async {
    await tester.pumpWidget(
      wrap(
        PaymentMethodSelector(
          cashEnabled: true,
          selected: null,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('E-Payment'), findsOneWidget);
  });

  testWidgets('hides the Cash row when cashEnabled is false', (tester) async {
    await tester.pumpWidget(
      wrap(
        PaymentMethodSelector(
          cashEnabled: false,
          selected: null,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Cash'), findsNothing);
    expect(find.text('E-Payment'), findsOneWidget);
  });

  testWidgets('tapping Cash calls onChanged with PaymentMethod.cash', (
    tester,
  ) async {
    PaymentMethod? picked;
    await tester.pumpWidget(
      wrap(
        PaymentMethodSelector(
          cashEnabled: true,
          selected: null,
          onChanged: (m) => picked = m,
        ),
      ),
    );
    await tester.tap(find.text('Cash'));
    await tester.pump();
    expect(picked, PaymentMethod.cash);
  });

  testWidgets('tapping E-Payment calls onChanged with PaymentMethod.wayl', (
    tester,
  ) async {
    PaymentMethod? picked;
    await tester.pumpWidget(
      wrap(
        PaymentMethodSelector(
          cashEnabled: true,
          selected: null,
          onChanged: (m) => picked = m,
        ),
      ),
    );
    await tester.tap(find.text('E-Payment'));
    await tester.pump();
    expect(picked, PaymentMethod.wayl);
  });
}
