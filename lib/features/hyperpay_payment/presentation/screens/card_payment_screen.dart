import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/core/widgets/primary_action_button.dart';

import '../../data/services/booking_lock_service.dart';
import '../../data/services/hyperpay_channel.dart';
import '../../data/services/hyperpay_verify_service.dart';
import '../../domain/card_validators.dart';
import '../domain/merchant_txn_id.dart';
import '../payment_strings.dart';
import '../widgets/card_brand_icon.dart';
import '../widgets/payment_sheet_shell.dart';

/// Wensa-styled HyperPay card form, shown as a modal bottom sheet. Field
/// order: card number, expiry, CVV, cardholder name (auto-advances focus
/// once each field is valid). Field keys (used by widget tests):
/// card_number, expiry, cvv, holder_name.
class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({
    super.key,
    required this.checkoutId,
    required this.referenceId,
    required this.entityKindForVerify,
    required this.entityId,
    required this.paymentMode,
    this.channel = const HyperpayChannel(),
    this.verifyService = const HyperpayVerifyService(),
    this.lockService = const BookingLockService(),
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.onPaymentCancelled,
  });

  final String checkoutId;
  final String referenceId;
  final String entityKindForVerify;
  final String entityId;
  final String paymentMode;
  final HyperpayChannel channel;
  final HyperpayVerifyService verifyService;
  final BookingLockService lockService;

  /// [merchantTransactionId] is the HyperPay-side transaction id (shown to
  /// the user for support lookups) when the verify step returned one.
  final void Function(
    String referenceId,
    String orderId,
    String? merchantTransactionId,
  )?
  onPaymentSuccess;

  /// Fired on a terminal decline; [message] is HyperPay's result description
  /// when the verify step returned one.
  final void Function(String? message, String? merchantTransactionId)?
  onPaymentFailed;
  final void Function()? onPaymentCancelled;

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();
  final _holderFocus = FocusNode();

  bool _processing = false;
  bool _resultHandled = false;
  bool _verifyPending = false;
  bool _saveCard = true;
  String? _errorText;

  String? _numberError;
  String? _expiryError;
  String? _cvvError;
  String? _holderError;

  int _prevNumberLen = 0;
  int _prevExpiryLen = 0;
  int _prevCvvLen = 0;

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_onNumberChanged);
    _expiryController.addListener(_onExpiryChanged);
    _cvvController.addListener(_onCvvChanged);
    _holderController.addListener(_onFieldChanged);
    _holderFocus.addListener(_onHolderFocusChanged);
  }

  void _onFieldChanged() => setState(() {});

  PaymentStrings get _s => PaymentStrings.of(context);

  void _onNumberChanged() {
    final len = _number.length;
    String? error;
    if (len == 16 && !(luhnCheck(_number) && detectBrand(_number) != null)) {
      error = _s.invalidCardNumber;
    }
    final shouldAdvance = len == 16 && error == null && _prevNumberLen < 16;
    setState(() {
      _numberError = error;
      _prevNumberLen = len;
    });
    if (shouldAdvance) FocusScope.of(context).requestFocus(_expiryFocus);
  }

  void _onExpiryChanged() {
    final len = _expiryController.text.length;
    String? error;
    if (len == 5 && !isValidExpiry(_month, _year)) {
      error = _s.invalidExpiryDate;
    }
    final shouldAdvance = len == 5 && error == null && _prevExpiryLen < 5;
    setState(() {
      _expiryError = error;
      _prevExpiryLen = len;
    });
    if (shouldAdvance) FocusScope.of(context).requestFocus(_cvvFocus);
  }

  void _onCvvChanged() {
    final len = _cvv.length;
    String? error;
    if (len == 3 && !isValidCvv(_cvv)) {
      error = _s.invalidCvv;
    }
    final shouldAdvance = len == 3 && error == null && _prevCvvLen < 3;
    setState(() {
      _cvvError = error;
      _prevCvvLen = len;
    });
    if (shouldAdvance) FocusScope.of(context).requestFocus(_holderFocus);
  }

  void _onHolderFocusChanged() {
    if (_holderFocus.hasFocus) {
      setState(() => _holderError = null);
      return;
    }
    if (_holder.trim().isEmpty) return;
    setState(() {
      _holderError = isValidHolderName(_holder) ? null : _s.invalidHolderName;
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _numberController,
      _holderController,
      _expiryController,
      _cvvController,
    ]) {
      controller.dispose();
    }
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    _holderFocus.dispose();
    // If we leave the screen without success/failure (X button, system back,
    // gesture, OS pop), treat it as a user cancel so the parent can release
    // any pending booking row server-side. Guarded by `_resultHandled` to
    // avoid double-firing alongside success/failure.
    if (!_resultHandled) {
      _resultHandled = true;
      widget.onPaymentCancelled?.call();
    }
    super.dispose();
  }

  String get _number => _numberController.text.replaceAll(' ', '');
  String get _holder => _holderController.text;
  List<String> get _expiryParts => _expiryController.text.split('/');
  String get _month => _expiryParts.first;
  String get _year => _expiryParts.length > 1 ? _expiryParts[1] : '';
  String get _cvv => _cvvController.text;

  /// Shown when the verify response doesn't echo a transaction id back — the
  /// result page must always be able to show one for support.
  String get _merchantTxnFallback => merchantTxnFallback(
    kind: widget.entityKindForVerify,
    id: widget.entityId,
  );

  bool get _formValid =>
      luhnCheck(_number) &&
      detectBrand(_number) != null &&
      isValidHolderName(_holder) &&
      isValidExpiry(_month, _year) &&
      isValidCvv(_cvv);

  Future<void> _pay() async {
    setState(() {
      _processing = true;
      _errorText = null;
    });

    try {
      if (!_verifyPending) {
        // Re-validate + extend the hold right before charging. Single-row
        // holds last only 60 seconds — without this, card entry + 3DS can
        // easily outlast the hold, charging the user for a slot that's
        // already gone (confirm_payment only flips rows still 'pending').
        final locked = await widget.lockService.lockForPayment(
          kind: widget.entityKindForVerify,
          id: widget.entityId,
        );
        if (!locked) {
          throw HyperpayPaymentException(
            HyperpayFailureKind.failed,
            _s.slotNoLongerAvailable,
          );
        }

        await widget.channel.submitCardPayment(
          checkoutId: widget.checkoutId,
          brand: detectBrand(_number)!,
          cardNumber: _number,
          holderName: _holder,
          expiryMonth: _month,
          expiryYear: _year,
          cvv: _cvv,
          mode: widget.paymentMode,
        );
      }

      _verifyPending = true;
      final result = await widget.verifyService.verify(
        checkoutId: widget.checkoutId,
        kind: widget.entityKindForVerify,
        id: widget.entityId,
        referenceId: widget.referenceId,
        saveCard: _saveCard,
      );
      _verifyPending = false;

      final merchantTxnId =
          result.merchantTransactionId ?? _merchantTxnFallback;
      _resultHandled = true;
      // Pop BEFORE invoking the outcome callback. Callbacks may synchronously
      // push PaymentResultPage onto the same (root) navigator; a pop() issued
      // after that push removes the result page instead of this sheet — the
      // user sees the payment UI close with no result page. (Only bit some
      // callers: callbacks that await something first yield long enough for
      // the pop to land before their push.)
      if (mounted) Navigator.of(context).pop();
      if (result.paid) {
        widget.onPaymentSuccess?.call(
          widget.referenceId,
          widget.checkoutId,
          merchantTxnId,
        );
      } else {
        widget.onPaymentFailed?.call(result.description, merchantTxnId);
      }
    } on HyperpayPaymentException catch (e) {
      if (e.kind != HyperpayFailureKind.cancelled && mounted) {
        setState(() => _errorText = e.message);
      }
    } catch (_) {
      // Verify (or another) network error. Keep _verifyPending set so the
      // next Pay tap retries only the verify step, not the channel call.
      if (mounted) {
        setState(() => _errorText = _s.couldNotConfirmPayment);
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _handleBack() {
    if (!_resultHandled) {
      _resultHandled = true;
      widget.onPaymentCancelled?.call();
    }
    Navigator.pop(context);
  }

  InputDecoration _decoration(
    BuildContext context,
    String hint, {
    String? errorText,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    // The dark theme maps surfaceContainer to the same color as surface,
    // which makes filled fields invisible on the sheet — use the highest
    // container tone there instead.
    final fill = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainer;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fill,
      // Muted so placeholders read as hints, not entered text.
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 24,
        maxWidth: 56,
        maxHeight: 32,
      ),
      errorText: errorText,
      errorStyle: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLG,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLG,
        borderSide: BorderSide(color: theme.colorScheme.secondary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLG,
        borderSide: const BorderSide(
          color: AppColors.danger,
          width: AppSpacing.borderMedium,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLG,
        borderSide: const BorderSide(
          color: AppColors.danger,
          width: AppSpacing.borderMedium,
        ),
      ),
      border: InputBorder.none,
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }

  /// Generic card glyph until the brand is detected, then the matching
  /// Visa/Mastercard mark. The glyph is muted to the hint color so it reads
  /// as part of the placeholder state.
  Widget _cardIcon(String? brand) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: CardBrandIcon(brand: brand, width: 32, mutedPlaceholder: true),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = detectBrand(_number);
    // Card fields are forced LTR below regardless of locale — card numbers,
    // expiry and CVV are Latin-digit formats and must not mirror under Arabic.
    final s = _s;
    // Explicit onSurface color: the app's dark textTheme is baked with
    // light-mode colors, so default-styled text renders dark-on-dark.
    final fieldStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return PaymentSheetShell(
      onClose: _handleBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('card_number'),
                  style: fieldStyle,
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  decoration: _decoration(
                    context,
                    '4111 1111 1111 1111',
                    errorText: _numberError,
                    suffixIcon: _cardIcon(brand),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('expiry'),
                        style: fieldStyle,
                        controller: _expiryController,
                        focusNode: _expiryFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateFormatter(),
                        ],
                        decoration: _decoration(
                          context,
                          '12/31',
                          errorText: _expiryError,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        key: const Key('cvv'),
                        style: fieldStyle,
                        controller: _cvvController,
                        focusNode: _cvvFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: _decoration(
                          context,
                          'CVV',
                          errorText: _cvvError,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('holder_name'),
                  style: fieldStyle,
                  controller: _holderController,
                  focusNode: _holderFocus,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  decoration: _decoration(
                    context,
                    s.cardHolderName,
                    errorText: _holderError,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Save-card opt-in: the checkout already carries the CIT
          // registration; checking this asks verify-payment to persist
          // the token for one-tap payments.
          InkWell(
            key: const Key('save_card_toggle'),
            borderRadius: AppSpacing.borderRadiusLG,
            onTap: _processing
                ? null
                : () => setState(() => _saveCard = !_saveCard),
            child: Row(
              children: [
                Checkbox(
                  value: _saveCard,
                  onChanged: _processing
                      ? null
                      : (v) => setState(() => _saveCard = v ?? false),
                ),
                Expanded(
                  child: Text(s.saveCardForFuturePayments, style: fieldStyle),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryActionButton(
            label: s.pay,
            isLoading: _processing,
            onTap: _formValid && !_processing ? _pay : null,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Formats digit input into groups of 4 (e.g. `4111 1111 1111 1111`).
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formats digit input into `MM/YY`, inserting the slash automatically.
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
