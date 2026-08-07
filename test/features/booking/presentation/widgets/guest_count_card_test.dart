import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/guest_count_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the "how many people" label and the guest count',
      (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 10,
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('How many people are going?'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('No extra charge up to 10 guests'), findsOneWidget);
  });

  testWidgets('shows the overage fee once guestCount exceeds includedPersons',
      (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 12,
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('+10,000 IQD for 2 extra guest(s)'), findsOneWidget);
  });

  testWidgets('tapping + increments the count', (tester) async {
    int? changedTo;
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 12,
      onGuestCountChanged: (v) => changedTo = v,
    )));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(changedTo, 13);
  });

  testWidgets('minus button is disabled when guestCount is 0', (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 5,
      extraPersonFeeIqd: 5000,
      guestCount: 0,
      onGuestCountChanged: (_) {},
    )));
    final minusButton = tester.widget<InkWell>(find.ancestor(
      of: find.byIcon(Icons.remove_rounded),
      matching: find.byType(InkWell),
    ));
    expect(minusButton.onTap, isNull);
  });

  testWidgets('minus button is enabled when guestCount is 1', (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 5,
      extraPersonFeeIqd: 5000,
      guestCount: 1,
      onGuestCountChanged: (_) {},
    )));
    final minusButton = tester.widget<InkWell>(find.ancestor(
      of: find.byIcon(Icons.remove_rounded),
      matching: find.byType(InkWell),
    ));
    expect(minusButton.onTap, isNotNull);
  });

  testWidgets('does not show the required prompt at guestCount 0 until showError is set',
      (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 0,
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('Please enter the number of guests'), findsNothing);
    expect(find.text('No extra charge up to 10 guests'), findsOneWidget);
  });

  testWidgets('shows a required prompt when guestCount is 0 and showError is true',
      (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 0,
      showError: true,
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('Please enter the number of guests'), findsOneWidget);
  });

  testWidgets('showError has no effect once guestCount is above 0',
      (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 3,
      showError: true,
      onGuestCountChanged: (_) {},
    )));
    expect(find.text('Please enter the number of guests'), findsNothing);
    expect(find.text('No extra charge up to 10 guests'), findsOneWidget);
  });
}
