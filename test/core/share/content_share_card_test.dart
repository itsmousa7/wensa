import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/core/share/content_share_card.dart';

void main() {
  testWidgets('ContentShareCard renders name, subtitle and footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentShareCard(
            name: 'Cafe X',
            subtitle: 'Karrada, Baghdad',
            isAr: false,
            footerText: 'Discover on Wensa',
          ),
        ),
      ),
    );
    expect(find.text('Cafe X'), findsWidgets);
    expect(find.text('Karrada, Baghdad'), findsOneWidget);
    expect(find.text('Discover on Wensa'), findsOneWidget);
    expect(find.text('WENSA'), findsOneWidget);
  });
}
