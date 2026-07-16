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
    )? onPaymentSuccess,
    void Function(String? message, String? merchantTransactionId)?
        onPaymentFailed,
    void Function()? onPaymentCancelled,
  }) {
    // Drag-down (and tap-outside) dismissal is allowed: leaving the sheet
    // without an outcome fires onPaymentCancelled via the content's dispose,
    // same as the X button.
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
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
