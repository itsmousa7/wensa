import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/core/share/share_link.dart';

void main() {
  test('placeShareUrl builds a placeId query url', () {
    expect(placeShareUrl('abc'), 'https://wensa.app/place?placeId=abc');
  });

  test('eventShareUrl builds an eventId query url', () {
    expect(eventShareUrl('e1'), 'https://wensa.app/event?eventId=e1');
  });

  test('placeShareCaption (en) includes name and url', () {
    final c = placeShareCaption(name: 'Cafe X', id: 'abc', isAr: false);
    expect(c, 'Check out Cafe X on Wensa!\nhttps://wensa.app/place?placeId=abc');
  });

  test('placeShareCaption (ar) includes name and url', () {
    final c = placeShareCaption(name: 'مقهى', id: 'abc', isAr: true);
    expect(c, contains('مقهى'));
    expect(c, contains('https://wensa.app/place?placeId=abc'));
  });

  test('eventShareCaption (en) includes name and url', () {
    final c = eventShareCaption(name: 'Show', id: 'e1', isAr: false);
    expect(c, 'Check out Show on Wensa!\nhttps://wensa.app/event?eventId=e1');
  });

  test('ticketShareCaption (en) includes name', () {
    expect(ticketShareCaption(name: 'Arena', isAr: false), contains('Arena'));
  });
}
