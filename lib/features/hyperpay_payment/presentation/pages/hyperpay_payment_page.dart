import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

import '../screens/payment_method_sheet.dart';

/// Drop-in replacement for the old PaymentWebViewPage: shows the HyperPay
/// payment sheet (saved cards + new-card form) as a modal bottom sheet and
/// forwards the same success/failed/cancelled callbacks.
class HyperpayPaymentPage {
  static Future<void> push(
    BuildContext context, {
    required String checkoutId,
    required String referenceId,
    required String entityKindForVerify,
    required String entityId,
    required String paymentMode,
    void Function(
      String referenceId,
      String orderId,
      String? merchantTransactionId,
    )?
    onPaymentSuccess,
    void Function(String? message, String? merchantTransactionId)?
    onPaymentFailed,
    void Function()? onPaymentCancelled,
  }) {
    // Drag and tap-outside dismissal are disabled: both bypass the route's
    // widget tree (BottomSheet.onClosing calls Navigator.pop directly, which
    // PopScope cannot intercept — see PaymentMethodSheet/CardPaymentScreen),
    // so a mid-charge swipe or stray tap could close the sheet while the
    // charge is still in flight, firing onPaymentCancelled (and releasing
    // the booking hold) even though the card may end up charged. The X
    // button is the only close affordance, and it disables itself while a
    // charge is in flight.
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXL),
        ),
      ),
      builder: (_) => PaymentMethodSheet(
        checkoutId: checkoutId,
        referenceId: referenceId,
        entityKindForVerify: entityKindForVerify,
        entityId: entityId,
        paymentMode: paymentMode,
        onPaymentSuccess: onPaymentSuccess,
        onPaymentFailed: onPaymentFailed,
        onPaymentCancelled: onPaymentCancelled,
      ),
    );
  }
}
