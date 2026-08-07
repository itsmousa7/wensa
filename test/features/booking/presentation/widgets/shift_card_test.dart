import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/slot_availability.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/shift_card.dart';

void main() {
  const shift = FarmShift(
    placeId: 'p1',
    shiftType: FarmShiftType.day,
    startsTime: '08:00:00',
    endsTime: '18:00:00',
    priceIqd: 100000,
    isAvailable: false,
  );

  Widget buildCard(
      {required SlotAvailability availability, required VoidCallback onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: ShiftCard(
          shift: shift,
          isSelected: false,
          availability: availability,
          onTap: onTap,
        ),
      ),
    );
  }

  group('ShiftCard booked state', () {
    testWidgets('shows "Booked" chip when booked', (tester) async {
      await tester.pumpWidget(
          buildCard(availability: SlotAvailability.booked, onTap: () {}));
      expect(find.text('Booked'), findsOneWidget);
    });

    testWidgets('does not show "Booked" chip when available', (tester) async {
      await tester.pumpWidget(
          buildCard(availability: SlotAvailability.available, onTap: () {}));
      expect(find.text('Booked'), findsNothing);
    });

    testWidgets('does not call onTap when booked', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(
          availability: SlotAvailability.booked,
          onTap: () => tapped = true));
      await tester.tap(find.byType(ShiftCard));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('calls onTap when available', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(
          availability: SlotAvailability.available,
          onTap: () => tapped = true));
      await tester.tap(find.byType(ShiftCard));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('ShiftCard price override', () {
    const overriddenShift = FarmShift(
      placeId: 'p1',
      shiftType: FarmShiftType.day,
      startsTime: '08:00:00',
      endsTime: '18:00:00',
      priceIqd: 300000,
      standardPriceIqd: 200000,
      isAvailable: true,
    );

    Widget buildOverriddenCard() {
      return MaterialApp(
        home: Scaffold(
          body: ShiftCard(
            shift: overriddenShift,
            isSelected: false,
            availability: SlotAvailability.available,
            onTap: () {},
          ),
        ),
      );
    }

    testWidgets('shows the struck-through standard price and a badge',
        (tester) async {
      await tester.pumpWidget(buildOverriddenCard());
      expect(find.text('300,000'), findsOneWidget);
      expect(find.text('200,000'), findsOneWidget);
      expect(find.text('Special price'), findsOneWidget);
      final standardPriceText =
          tester.widget<Text>(find.text('200,000'));
      expect(
        standardPriceText.style?.decoration,
        TextDecoration.lineThrough,
      );
    });

    testWidgets('shows no strikethrough or badge when there is no override',
        (tester) async {
      const shift = FarmShift(
        placeId: 'p1',
        shiftType: FarmShiftType.day,
        startsTime: '08:00:00',
        endsTime: '18:00:00',
        priceIqd: 200000,
        isAvailable: true,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShiftCard(
            shift: shift,
            isSelected: false,
            availability: SlotAvailability.available,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('Special price'), findsNothing);
    });
  });

  group('ShiftCard override weekday hint', () {
    testWidgets('appends the weekday list to the badge when overrideWeekdays is set',
        (tester) async {
      const shift = FarmShift(
        placeId: 'p1',
        shiftType: FarmShiftType.day,
        startsTime: '08:00:00',
        endsTime: '18:00:00',
        priceIqd: 300000,
        standardPriceIqd: 200000,
        overrideWeekdays: [4, 5],
        isAvailable: true,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShiftCard(
            shift: shift,
            isSelected: false,
            availability: SlotAvailability.available,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('Special price · Thu & Fri'), findsOneWidget);
    });

    testWidgets('badge shows plain "Special price" when overrideWeekdays is null',
        (tester) async {
      const shift = FarmShift(
        placeId: 'p1',
        shiftType: FarmShiftType.day,
        startsTime: '08:00:00',
        endsTime: '18:00:00',
        priceIqd: 300000,
        standardPriceIqd: 200000,
        isAvailable: true,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShiftCard(
            shift: shift,
            isSelected: false,
            availability: SlotAvailability.available,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('Special price'), findsOneWidget);
      expect(find.text('Special price · Thu & Fri'), findsNothing);
    });
  });
}
