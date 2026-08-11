import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders paymentMethodSlot when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        BookingSummaryCard(
          title: 'Summary',
          rows: const [],
          paymentMethodSlot: const Text('PAYMENT_SLOT_MARKER'),
          actionLabel: 'Go',
          onAction: () {},
          isLoading: false,
        ),
      ),
    );
    expect(find.text('PAYMENT_SLOT_MARKER'), findsOneWidget);
  });

  testWidgets('renders nothing extra when paymentMethodSlot is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BookingSummaryCard(
          title: 'Summary',
          rows: const [],
          actionLabel: 'Go',
          onAction: () {},
          isLoading: false,
        ),
      ),
    );
    expect(find.text('PAYMENT_SLOT_MARKER'), findsNothing);
  });

  testWidgets('disables the action button when onAction is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BookingSummaryCard(
          title: 'Summary',
          rows: const [],
          actionLabel: 'Go',
          onAction: null,
          isLoading: false,
        ),
      ),
    );
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });
}
