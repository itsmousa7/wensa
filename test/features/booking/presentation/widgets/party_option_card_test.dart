import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/party_option_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('guest stepper is hidden when off, shown when on', (tester) async {
    await tester.pumpWidget(wrap(PartyOptionCard(
      includedPersons: 10,
      flatFeeIqd: 20000,
      extraPersonFeeIqd: 5000,
      isOn: false,
      guestCount: 10,
      onToggle: (_) {},
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('10'), findsNothing);

    await tester.pumpWidget(wrap(PartyOptionCard(
      includedPersons: 10,
      flatFeeIqd: 20000,
      extraPersonFeeIqd: 5000,
      isOn: true,
      guestCount: 10,
      onToggle: (_) {},
      onGuestCountChanged: (_) {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);
    expect(
      find.text('20,000 IQD party fee · No extra charge up to 10 guests'),
      findsOneWidget,
    );
  });

  testWidgets('shows overage fee and tapping + increments the count', (tester) async {
    int? changedTo;
    await tester.pumpWidget(wrap(PartyOptionCard(
      includedPersons: 10,
      flatFeeIqd: 20000,
      extraPersonFeeIqd: 5000,
      isOn: true,
      guestCount: 12,
      onToggle: (_) {},
      onGuestCountChanged: (v) => changedTo = v,
    )));
    await tester.pumpAndSettle();
    expect(
      find.text('20,000 IQD party fee · +10,000 IQD for 2 extra guest(s)'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(changedTo, 13);
  });

  testWidgets('minus button is disabled when guestCount is 1', (tester) async {
    await tester.pumpWidget(wrap(PartyOptionCard(
      includedPersons: 5,
      flatFeeIqd: 20000,
      extraPersonFeeIqd: 5000,
      isOn: true,
      guestCount: 1,
      onToggle: (_) {},
      onGuestCountChanged: (_) {},
    )));
    await tester.pumpAndSettle();
    final minusButton = tester.widget<InkWell>(find.ancestor(
      of: find.byIcon(Icons.remove_rounded),
      matching: find.byType(InkWell),
    ));
    expect(minusButton.onTap, isNull);
  });
}
