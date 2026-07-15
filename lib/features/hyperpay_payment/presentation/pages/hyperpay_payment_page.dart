import 'package:flutter/material.dart';

import '../screens/card_payment_screen.dart';

/// Drop-in replacement for the old PaymentWebViewPage: pushes the HyperPay
/// card form and forwards the same success/failed/cancelled callbacks.
class HyperpayPaymentPage {
  static Future<void> push(
    BuildContext context, {
    required String checkoutId,
    required String referenceId,
    required String entityKindForVerify,
    required String entityId,
    required String paymentMode,
    void Function(String referenceId, String orderId)? onPaymentSuccess,
    void Function()? onPaymentFailed,
    void Function()? onPaymentCancelled,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CardPaymentScreen(
          checkoutId: checkoutId,
          referenceId: referenceId,
          entityKindForVerify: entityKindForVerify,
          entityId: entityId,
          paymentMode: paymentMode,
          onPaymentSuccess: onPaymentSuccess,
          onPaymentFailed: onPaymentFailed,
          onPaymentCancelled: onPaymentCancelled,
        ),
      ),
    );
  }
}
