import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/core/widgets/glass_back_button.dart';

import '../../data/services/hyperpay_channel.dart';
import '../../data/services/hyperpay_verify_service.dart';
import '../../domain/card_validators.dart';

/// Wensa-styled HyperPay card form. Field keys (used by widget tests):
/// card_number, holder_name, expiry_month, expiry_year, cvv.
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
  final void Function(String referenceId, String orderId)? onPaymentSuccess;
  final void Function()? onPaymentFailed;
  final void Function()? onPaymentCancelled;

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _processing = false;
  bool _resultHandled = false;
  bool _verifyPending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _numberController,
      _holderController,
      _monthController,
      _yearController,
      _cvvController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final controller in [
      _numberController,
      _holderController,
      _monthController,
      _yearController,
      _cvvController,
    ]) {
      controller.dispose();
    }
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

  String get _number => _numberController.text;
  String get _holder => _holderController.text;
  String get _month => _monthController.text;
  String get _year => _yearController.text;
  String get _cvv => _cvvController.text;

  bool get _formValid =>
      luhnCheck(_number) &&
      detectBrand(_number) != null &&
      _holder.trim().isNotEmpty &&
      isValidExpiry(_month, _year) &&
      isValidCvv(_cvv);

  Future<void> _pay() async {
    setState(() {
      _processing = true;
      _errorText = null;
    });

    try {
      if (!_verifyPending) {
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
      final paid = await widget.verifyService.verify(
        checkoutId: widget.checkoutId,
        kind: widget.entityKindForVerify,
        id: widget.entityId,
        referenceId: widget.referenceId,
      );
      _verifyPending = false;

      if (paid) {
        _resultHandled = true;
        widget.onPaymentSuccess?.call(widget.referenceId, widget.checkoutId);
        if (mounted) Navigator.of(context).pop();
      } else {
        _resultHandled = true;
        widget.onPaymentFailed?.call();
        if (mounted) Navigator.of(context).pop();
      }
    } on HyperpayPaymentException catch (e) {
      if (e.kind != HyperpayFailureKind.cancelled) {
        _errorText = e.message;
      }
    } catch (_) {
      // Verify (or another) network error. Keep _verifyPending set so the
      // next Pay tap retries only the verify step, not the channel call.
      _errorText =
          'Could not confirm payment — check your connection and tap Pay again.';
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

  InputDecoration _decoration(BuildContext context, String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainer,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLG,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusLG,
        borderSide: BorderSide(color: theme.colorScheme.secondary),
      ),
      border: InputBorder.none,
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = detectBrand(_number);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: GlassBackButton.appBarLeadingWidth,
        leading: GlassBackButton.appBarLeading(onPressed: _handleBack),
        title: Text(
          'Payment',
          style: TextStyle(color: theme.colorScheme.outline),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('card_number'),
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                      decoration: _decoration(context, 'Card number'),
                    ),
                  ),
                  if (brand != null)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Text(
                        brand == 'VISA' ? 'VISA' : 'Mastercard',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('holder_name'),
                controller: _holderController,
                textCapitalization: TextCapitalization.characters,
                decoration: _decoration(context, 'Cardholder name'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('expiry_month'),
                      controller: _monthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: _decoration(context, 'MM'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      key: const Key('expiry_year'),
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: _decoration(context, 'YY'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      key: const Key('cvv'),
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: _decoration(context, 'CVV'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _formValid && !_processing ? _pay : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusLG,
                  ),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Pay'),
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
        ),
      ),
    );
  }
}
