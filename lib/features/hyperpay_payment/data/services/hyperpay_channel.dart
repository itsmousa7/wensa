import 'package:flutter/services.dart';

import '../../domain/card_validators.dart';

enum HyperpayFailureKind { cancelled, invalidCard, failed }

class HyperpayPaymentException implements Exception {
  const HyperpayPaymentException(this.kind, this.message);

  final HyperpayFailureKind kind;
  final String message;

  @override
  String toString() => 'HyperpayPaymentException(${kind.name}): $message';
}

/// Bridge to the native HyperPay mSDK.
///
/// Native contract (Android MainActivity.kt / iOS SceneDelegate.swift):
/// method `submitCardPayment` returns "SYNC" (no 3DS) or "success" (3DS
/// challenge completed and redirected back), or throws PlatformException
/// with code `cancelled` | `invalid_card` | `transaction_failed`.
class HyperpayChannel {
  const HyperpayChannel();

  static const _channel = MethodChannel('app.wensa.mobile/hyperpay');

  Future<void> submitCardPayment({
    required String checkoutId,
    required String brand,
    required String cardNumber,
    required String holderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String mode,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('submitCardPayment', {
        'checkoutid': checkoutId,
        'brand': brand,
        'card_number': cardNumber,
        'holder_name': holderName,
        'month': expiryMonth,
        'year': normalizeYear(expiryYear),
        'cvv': cvv,
        'mode': mode,
      });
      if (result != 'success' && result != 'SYNC') {
        throw HyperpayPaymentException(
          HyperpayFailureKind.failed,
          'Unexpected payment result: $result',
        );
      }
    } on PlatformException catch (e) {
      final kind = switch (e.code) {
        'cancelled' => HyperpayFailureKind.cancelled,
        'invalid_card' => HyperpayFailureKind.invalidCard,
        _ => HyperpayFailureKind.failed,
      };
      throw HyperpayPaymentException(kind, e.message ?? 'Payment failed');
    }
  }
}
