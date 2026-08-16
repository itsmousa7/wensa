import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/hyperpay_payment/hyperpay_payment.dart';

class _FakeSavedCards extends SavedCards {
  _FakeSavedCards(this.cards);
  final List<SavedCard> cards;
  @override
  Future<List<SavedCard>> build() async => cards;
}

class _FakeTokenService extends HyperpayTokenService {
  _FakeTokenService({required this.paid, this.description});
  final bool paid;
  final String? description;
  String? lastTokenId;
  @override
  Future<({bool paid, String? description, String? merchantTransactionId})>
  chargeSavedCard({
    required String tokenId,
    required String kind,
    required String id,
    required String referenceId,
  }) async {
    lastTokenId = tokenId;
    return (
      paid: paid,
      description: description,
      merchantTransactionId: 'mit-test123',
    );
  }
}

const _visa = SavedCard(
  id: 'card-1',
  brand: 'VISA',
  last4: '1111',
  expMonth: '12',
  expYear: '2039',
);

Widget _wrap(Widget sheet, {List<SavedCard> cards = const [_visa]}) {
  return ProviderScope(
    overrides: [savedCardsProvider.overrideWith(() => _FakeSavedCards(cards))],
    child: MaterialApp(home: Scaffold(body: sheet)),
  );
}

void main() {
  testWidgets('lists saved cards and pays with one tap', (tester) async {
    final tokenService = _FakeTokenService(paid: true);
    String? successRef;
    await tester.pumpWidget(
      _wrap(
        PaymentMethodSheet(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
          tokenService: tokenService,
          onPaymentSuccess: (ref, _, _) => successRef = ref,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visa •••• 1111'), findsOneWidget);

    await tester.tap(find.byKey(const Key('saved_card_card-1')));
    await tester.pumpAndSettle();

    expect(tokenService.lastTokenId, 'card-1');
    expect(successRef, 'ref_1');
  });

  testWidgets('declined charge shows the error and keeps the sheet open', (
    tester,
  ) async {
    final tokenService = _FakeTokenService(
      paid: false,
      description: 'Card declined',
    );
    var failed = false;
    await tester.pumpWidget(
      _wrap(
        PaymentMethodSheet(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
          tokenService: tokenService,
          onPaymentFailed: (_, _) => failed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saved_card_card-1')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Card declined'), findsOneWidget);
    expect(find.textContaining('mit-test123'), findsOneWidget);
    expect(failed, isFalse); // user can retry or switch card
  });

  testWidgets('"Use a new card" switches to the card form', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PaymentMethodSheet(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('use_new_card')));
    await tester.pumpAndSettle();

    expect(find.byType(CardPaymentScreen), findsOneWidget);
  });

  testWidgets('no saved cards goes straight to the card form', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PaymentMethodSheet(
          checkoutId: 'chk_1',
          referenceId: 'ref_1',
          entityKindForVerify: 'booking',
          entityId: 'b1',
          paymentMode: 'TEST',
        ),
        cards: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CardPaymentScreen), findsOneWidget);
  });
}
