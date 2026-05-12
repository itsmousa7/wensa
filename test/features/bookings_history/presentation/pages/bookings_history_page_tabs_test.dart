import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/bookings_history/presentation/pages/bookings_history_page.dart';

void main() {
  test('kBookingHistoryTabs has 6 entries with semantic category names', () {
    expect(kBookingHistoryTabs.length, 6);
    expect(kBookingHistoryTabs[0], 'All');
    expect(kBookingHistoryTabs[1], 'Sports');
    expect(kBookingHistoryTabs[2], 'Farm');
    expect(kBookingHistoryTabs[3], 'Concert');
    expect(kBookingHistoryTabs[4], 'Restaurant');
    expect(kBookingHistoryTabs[5], 'Memberships');
  });
}
