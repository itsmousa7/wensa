import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/booking_summary_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

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
