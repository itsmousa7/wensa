import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/party_option_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders label and reflects isOn in the switch value', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(PartyOptionCard(flatFeeIqd: 20000, isOn: false, onToggle: (_) {})),
    );
    expect(find.text('Making a party?'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.pumpWidget(
      wrap(PartyOptionCard(flatFeeIqd: 20000, isOn: true, onToggle: (_) {})),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('shows the flat fee helper text when flatFeeIqd > 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(PartyOptionCard(flatFeeIqd: 20000, isOn: true, onToggle: (_) {})),
    );
    expect(find.text('20,000 IQD Extra Guests Fee'), findsOneWidget);
  });

  testWidgets('hides the helper text when flatFeeIqd is 0', (tester) async {
    await tester.pumpWidget(
      wrap(PartyOptionCard(flatFeeIqd: 0, isOn: true, onToggle: (_) {})),
    );
    expect(find.text('20,000 IQD Extra Guests Fee'), findsNothing);
  });

  testWidgets('tapping the switch calls onToggle with the flipped value', (
    tester,
  ) async {
    bool? toggledTo;
    await tester.pumpWidget(
      wrap(
        PartyOptionCard(
          flatFeeIqd: 20000,
          isOn: false,
          onToggle: (v) => toggledTo = v,
        ),
      ),
    );
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(toggledTo, isTrue);
  });
}
