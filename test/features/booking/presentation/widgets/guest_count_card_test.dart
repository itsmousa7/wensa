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

  FixedExtentScrollController wheelController(WidgetTester tester) =>
      tester.widget<ListWheelScrollView>(find.byType(ListWheelScrollView))
          .controller as FixedExtentScrollController;

  testWidgets('the wheel opens centred on the current guest count',
      (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 12,
      onGuestCountChanged: (_) {},
    )));
    expect(wheelController(tester).selectedItem, 12);
  });

  testWidgets('picking a value on the wheel reports it', (tester) async {
    int? changedTo;
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 12,
      onGuestCountChanged: (v) => changedTo = v,
    )));
    wheelController(tester).jumpToItem(15);
    await tester.pumpAndSettle();
    expect(changedTo, 15);
  });

  testWidgets('dragging the wheel forward raises the count', (tester) async {
    int? changedTo;
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 10,
      extraPersonFeeIqd: 5000,
      guestCount: 12,
      onGuestCountChanged: (v) => changedTo = v,
    )));
    await tester.drag(find.byType(ListWheelScrollView), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(changedTo, greaterThan(12));
  });

  testWidgets('the wheel cannot go below zero guests', (tester) async {
    int? changedTo;
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 5,
      extraPersonFeeIqd: 5000,
      guestCount: 0,
      onGuestCountChanged: (v) => changedTo = v,
    )));
    await tester.drag(find.byType(ListWheelScrollView), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(wheelController(tester).selectedItem, 0);
    expect(changedTo, isNull);
  });

  testWidgets('the wheel stops at maxGuests', (tester) async {
    await tester.pumpWidget(wrap(GuestCountCard(
      includedPersons: 5,
      extraPersonFeeIqd: 5000,
      guestCount: 20,
      maxGuests: 20,
      onGuestCountChanged: (_) {},
    )));
    await tester.drag(find.byType(ListWheelScrollView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(wheelController(tester).selectedItem, 20);
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
