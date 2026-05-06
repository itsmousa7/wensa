import 'package:flutter/material.dart';
import 'package:future_riverpod/features/wayl_payment/presentation/screens/wayl_webview_screen.dart';

class PaymentWebViewPage {
  /// Pushes the Wayl checkout WebView onto the navigator.
  ///
  /// [referenceId] is the booking ID used when the Wayl link was created —
  /// it is polled every 3 s to detect payment completion automatically.
  ///
  /// [redirectionUrl] is the URL that Wayl redirects to after checkout;
  /// if provided, payment completion is also detected via URL interception.
  static Future<void> push(
    BuildContext context,
    String paymentUrl, {
    required String referenceId,
    String? redirectionUrl,
    void Function(String referenceId, String orderId)? onPaymentSuccess,
    void Function()? onPaymentFailed,
    void Function()? onPaymentCancelled,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WaylWebViewScreen(
          paymentUrl: paymentUrl,
          referenceId: referenceId,
          redirectionUrl: redirectionUrl,
          onPaymentSuccess: onPaymentSuccess,
          onPaymentFailed: onPaymentFailed,
          onPaymentCancelled: onPaymentCancelled,
        ),
      ),
    );
  }
}
