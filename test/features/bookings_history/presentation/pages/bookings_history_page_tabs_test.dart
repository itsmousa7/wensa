import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/bookings_history/presentation/pages/bookings_history_page.dart';

void main() {
  test('kBookingHistoryTabsEn has 6 entries with semantic category names', () {
    expect(kBookingHistoryTabsEn.length, 6);
    expect(kBookingHistoryTabsEn[0], 'All');
    expect(kBookingHistoryTabsEn[1], 'Sports');
    expect(kBookingHistoryTabsEn[2], 'Farm');
    expect(kBookingHistoryTabsEn[3], 'Concert');
    expect(kBookingHistoryTabsEn[4], 'Restaurant');
    expect(kBookingHistoryTabsEn[5], 'Memberships');
  });
}
