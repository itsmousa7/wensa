import 'package:flutter/widgets.dart';

/// Feature-local bilingual copy for the HyperPay payment flow.
///
/// Deliberately NOT wired to the app's global l10n: this feature is meant to
/// stay drop-in portable, so every string it shows lives here. Same inline
/// en/ar pattern the rest of the app uses, just hoisted out of the widgets.
class PaymentStrings {
  const PaymentStrings.forLocale(this.isAr);

  /// Reads the active locale off [context] (`ar` → Arabic, anything else →
  /// English).
  factory PaymentStrings.of(BuildContext context) => PaymentStrings.forLocale(
    Localizations.localeOf(context).languageCode == 'ar',
  );

  final bool isAr;

  String _pick(String ar, String en) => isAr ? ar : en;

  // ── Sheet chrome ──────────────────────────────────────────────────────
  String get payment => _pick('الدفع', 'Payment');
  String get pay => _pick('ادفع', 'Pay');
  String get useNewCard => _pick('استخدام بطاقة جديدة', 'Use a new card');
  String get saveCardForFuturePayments => _pick(
    'احفظ هذه البطاقة للمدفوعات القادمة',
    'Save this card for future payments',
  );

  // ── Card form ─────────────────────────────────────────────────────────
  String get invalidCardNumber =>
      _pick('رقم البطاقة غير صحيح', 'Invalid card number');
  String get invalidExpiryDate =>
      _pick('تاريخ الانتهاء غير صحيح', 'Invalid expiry date');
  String get invalidCvv => _pick('رمز CVV غير صحيح', 'Invalid CVV');

  // ── Failures ──────────────────────────────────────────────────────────
  String get slotNoLongerAvailable => _pick(
    'هذا الموعد لم يعد متاحاً. يرجى البدء من جديد.',
    'This slot is no longer available. Please start again.',
  );
  String get couldNotConfirmPayment => _pick(
    'تعذّر تأكيد الدفع. تحقق من الاتصال واضغط ادفع مرة أخرى.',
    'Could not confirm payment. Check your connection and tap Pay again.',
  );
  String get couldNotCompletePayment => _pick(
    'تعذّر إتمام الدفع. تحقق من الاتصال وحاول مرة أخرى.',
    'Could not complete payment. Check your connection and try again.',
  );
  String get paymentFailedTryAgain => _pick(
    'فشلت عملية الدفع. يرجى المحاولة مرة أخرى.',
    'Payment failed. Please try again.',
  );

  /// Inline (sheet) transaction-id label — sentence case.
  String get transactionId => _pick('رقم العملية', 'Transaction ID');

  // ── Saved cards ───────────────────────────────────────────────────────
  /// Prefixed to the expiry, e.g. `تنتهي في 12/27` / `Expires 12/27`.
  String get expiresPrefix => _pick('تنتهي في ', 'Expires ');
  String get savedCardsTitle => _pick('البطاقات المحفوظة', 'Saved Cards');
  String get couldNotLoadSavedCards => _pick(
    'تعذر تحميل البطاقات المحفوظة.',
    'Could not load your saved cards.',
  );
  String get noSavedCardsYet =>
      _pick('لا توجد بطاقات محفوظة', 'No saved cards yet');
  String get noSavedCardsHint => _pick(
    'يمكنك حفظ بطاقتك أثناء الدفع لاستخدامها لاحقًا.',
    'You can save a card during checkout to use it for faster payments.',
  );
  String get couldNotRemoveCard => _pick(
    'تعذر حذف البطاقة. حاول مرة أخرى.',
    'Could not remove the card. Please try again.',
  );
  String get removeCardTitle => _pick('حذف البطاقة؟', 'Remove this card?');
  String removeCardBody(String displayName) => _pick(
    '$displayName ستُحذف. يمكنك حفظها مجددًا في عملية دفع لاحقة.',
    '$displayName will be removed. You can save it again during a future payment.',
  );
  String get cancel => _pick('إلغاء', 'Cancel');
  String get remove => _pick('حذف', 'Remove');

  // ── Result page ───────────────────────────────────────────────────────
  String get thankYou => _pick('شكراً لك!', 'Thank you!');
  String get paymentFailedTitle => _pick('فشلت عملية الدفع', 'Payment failed');
  String get bookingConfirmed => _pick(
    'تم تأكيد حجزك بنجاح',
    'Your booking has been confirmed successfully',
  );
  String get paymentCouldNotComplete => _pick(
    'تعذّر إتمام عملية الدفع. يرجى المحاولة مرة أخرى.',
    'Your payment could not be completed. Please try again.',
  );
  String get takingYouToBooking => _pick(
    'جارٍ نقلك إلى حجزك · اضغط للتخطي',
    'Taking you to your booking · tap to skip',
  );
  String get returningToBooking => _pick(
    'العودة إلى الحجز · اضغط للتخطي',
    'Returning to booking · tap to skip',
  );
  String get tapAnywhereToContinue =>
      _pick('اضغط في أي مكان للمتابعة', 'Tap anywhere to continue');
  String get dateAndTime => _pick('التاريخ والوقت', 'DATE & TIME');

  /// Result-page transaction-id label — all caps in English to match the
  /// panel's other column headers.
  String get transactionIdCaps => _pick('رقم العملية', 'TRANSACTION ID');
  String get copied => _pick('تم النسخ', 'Copied');
}
