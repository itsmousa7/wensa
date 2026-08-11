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
    const rows = [
      BookingSummaryRow(icon: Icons.event, label: 'Date', value: 'Today'),
      BookingSummaryRow(icon: Icons.timer, label: 'Duration', value: '2h'),
    ];

    Widget card({Widget? slot}) => wrap(
      BookingSummaryCard(
        title: 'Summary',
        rows: rows,
        paymentMethodSlot: slot,
        actionLabel: 'Go',
        onAction: () {},
        isLoading: false,
      ),
    );

    await tester.pumpWidget(card(slot: const Text('PAYMENT_SLOT_MARKER')));
    final withSlot = tester.widgetList<Divider>(find.byType(Divider)).length;
    expect(find.text('PAYMENT_SLOT_MARKER'), findsOneWidget);

    await tester.pumpWidget(card());
    final withoutSlot = tester.widgetList<Divider>(find.byType(Divider)).length;

    expect(find.text('PAYMENT_SLOT_MARKER'), findsNothing);
    // The slot brings its own leading divider, and nothing else.
    expect(withoutSlot, withSlot - 1);
  });

  testWidgets('omits the leading divider when rows is empty', (tester) async {
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
    expect(find.byType(Divider), findsNothing);
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
    final inkWell = tester.widget<InkWell>(
      find
          .descendant(
            of: find.byType(BookingSummaryCard),
            matching: find.byType(InkWell),
          )
          .last,
    );
    expect(inkWell.onTap, isNull);
  });

  testWidgets('action label stays legible while disabled', (tester) async {
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
    final label = tester.widget<Text>(find.text('Go'));
    final scheme = Theme.of(
      tester.element(find.byType(BookingSummaryCard)),
    ).colorScheme;
    // White-on-grey would be invisible; the disabled label uses the
    // on-surface-variant colour instead.
    expect(label.style?.color, scheme.onSurfaceVariant);
    expect(label.style?.color, isNot(Colors.white));
  });
}
