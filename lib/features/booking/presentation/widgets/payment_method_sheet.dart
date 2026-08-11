import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart'
    show bookingsRefreshProvider;
import 'package:future_riverpod/features/discounts/presentation/providers/user_purchase_history_provider.dart';
import 'package:go_router/go_router.dart';

/// Shared tail for a cash-confirmed booking/membership: the server already
/// confirmed it (no webview needed), so just refresh caches and land on the
/// ticket page. [routeId] is the raw booking id, or `m_<membershipId>` for a
/// membership — same id shape `context.go('/bookings/$routeId')` expects
/// elsewhere in this feature.
void goToCashBookingSuccess({
  required BuildContext context,
  required WidgetRef ref,
  required String routeId,
  required VoidCallback resetSubmitState,
}) {
  resetSubmitState();
  ref.read(bookingsRefreshProvider.notifier).bump();
  ref.invalidate(userPurchaseHistoryProvider);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking confirmed! Pay with cash at the venue.'),
        backgroundColor: Colors.green,
      ),
    );
    context.go('/bookings/$routeId');
  }
}
