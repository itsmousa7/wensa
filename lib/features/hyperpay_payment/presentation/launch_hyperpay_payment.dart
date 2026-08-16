import 'package:flutter/material.dart';

import 'pages/hyperpay_payment_page.dart';
import 'screens/payment_result_page.dart';

/// Why a payment run ended without money changing hands.
enum PaymentAbort {
  /// HyperPay returned a terminal decline.
  declined,

  /// The user closed the sheet (X, drag, system back) before an outcome.
  cancelled,
}

/// Opens the HyperPay payment sheet and owns the whole outcome dance that
/// every booking flow used to hand-roll: pushing the result page on success,
/// pushing it on a decline, and showing the cancel snackbar — each behind a
/// `context.mounted` guard, because the caller's `await` gaps can outlive the
/// widget.
///
/// The caller supplies only the domain half:
/// * [onConfirmed] — confirm the entity server-side for [orderId] and return
///   the navigation to run once the user dismisses the result page (or null
///   to stay put). Runs before the result page is shown.
/// * [onAborted] — release the hold for the given [PaymentAbort] reason.
///
/// Deliberately depends on nothing but Flutter and this feature, so the whole
/// folder stays drop-in portable.
Future<void> launchHyperpayPayment(
  BuildContext context, {
  required String checkoutId,
  required String referenceId,
  required String entityKind, // booking | concert_group | membership
  required String entityId,
  required String paymentMode,
  required Future<VoidCallback?> Function(String orderId) onConfirmed,
  required Future<void> Function(PaymentAbort reason) onAborted,
  String cancelledMessage = 'Payment cancelled.',
}) {
  return HyperpayPaymentPage.push(
    context,
    checkoutId: checkoutId,
    referenceId: referenceId,
    entityKindForVerify: entityKind,
    entityId: entityId,
    paymentMode: paymentMode,
    onPaymentSuccess: (_, orderId, merchantTxnId) async {
      final onDone = await onConfirmed(orderId);
      if (!context.mounted) return;
      PaymentResultPage.show(
        context,
        success: true,
        merchantTransactionId: merchantTxnId,
        onDone: () {
          if (!context.mounted) return;
          onDone?.call();
        },
      );
    },
    onPaymentFailed: (message, merchantTxnId) async {
      await onAborted(PaymentAbort.declined);
      if (!context.mounted) return;
      PaymentResultPage.show(
        context,
        success: false,
        message: message,
        merchantTransactionId: merchantTxnId,
      );
    },
    onPaymentCancelled: () async {
      await onAborted(PaymentAbort.cancelled);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cancelledMessage)));
    },
  );
}
