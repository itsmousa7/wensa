import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_visual_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  // On a Liquid-Glass-capable host the field renders through
  // LiquidGlassContainer, whose PlatformViewGuard arms a 500ms timer. Drain it
  // so the binding doesn't fail the test on a pending timer at teardown.
  Future<void> pumpCard(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(wrap(child));
    await tester.pump(const Duration(milliseconds: 600));
  }

  const txnId = 'booking-8f1c2d3e-4a5b-6c7d-8e9f';

  TicketVisualCard card({
    String? transactionId = txnId,
    bool shareMode = false,
  }) => TicketVisualCard(
    qrToken: '',
    displayName: 'Farm',
    isArabic: false,
    statusBadge: const SizedBox.shrink(),
    cells: const [TicketInfoCell(label: 'Date', value: '23 Aug 2026')],
    transactionId: transactionId,
    shareMode: shareMode,
  );

  testWidgets('renders the transaction id under a labelled field', (
    tester,
  ) async {
    await pumpCard(tester, card());
    expect(find.text('Transaction ID'), findsOneWidget);
    expect(find.text(txnId), findsOneWidget);
  });

  testWidgets('omits the field when there is no transaction id', (
    tester,
  ) async {
    await pumpCard(tester, card(transactionId: null));
    expect(find.text('Transaction ID'), findsNothing);
  });

  testWidgets('omits the field in share mode — it is copy-only UI', (
    tester,
  ) async {
    await pumpCard(tester, card(shareMode: true));
    expect(find.text('Transaction ID'), findsNothing);
    expect(find.text(txnId), findsNothing);
  });

  testWidgets('the copy button puts the full id on the clipboard', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
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

    await pumpCard(tester, card());
    await tester.tap(find.byIcon(Icons.content_copy_rounded));
    await tester.pump();

    expect(copied, txnId);
  });

  testWidgets('shows the Arabic label under an Arabic locale', (tester) async {
    await pumpCard(
      tester,
      TicketVisualCard(
        qrToken: '',
        displayName: 'مزرعة',
        isArabic: true,
        statusBadge: const SizedBox.shrink(),
        cells: const [TicketInfoCell(label: 'التاريخ', value: '23 Aug 2026')],
        transactionId: txnId,
      ),
    );
    expect(find.text('رقم العملية'), findsOneWidget);
    expect(find.text(txnId), findsOneWidget);
  });
}
