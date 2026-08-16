import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

import '../../data/services/hyperpay_token_service.dart';
import '../../domain/models/saved_card.dart';
import '../domain/merchant_txn_id.dart';
import '../payment_strings.dart';
import '../providers/saved_cards_provider.dart';
import '../widgets/payment_sheet_shell.dart';
import '../widgets/saved_card_tile.dart';
import '../widgets/use_new_card_button.dart';
import 'card_payment_screen.dart';

/// Payment bottom-sheet content: shows the user's saved cards for one-tap
/// payment, plus a "Use a new card" path that falls through to the existing
/// [CardPaymentScreen] form. Users with no saved cards go straight to the
/// form. One-way navigation: once the form is shown there is no way back to
/// the chooser (closing the form keeps the existing cancel semantics).
class PaymentMethodSheet extends ConsumerStatefulWidget {
  const PaymentMethodSheet({
    super.key,
    required this.checkoutId,
    required this.referenceId,
    required this.entityKindForVerify,
    required this.entityId,
    required this.paymentMode,
    this.tokenService = const HyperpayTokenService(),
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.onPaymentCancelled,
  });

  final String checkoutId;
  final String referenceId;
  final String entityKindForVerify;
  final String entityId;
  final String paymentMode;
  final HyperpayTokenService tokenService;

  /// [merchantTransactionId] is the HyperPay-side transaction id (shown to
  /// the user for support lookups) when available.
  final void Function(
    String referenceId,
    String orderId,
    String? merchantTransactionId,
  )?
  onPaymentSuccess;

  /// Fired on a terminal decline; carries HyperPay's result description
  /// when available.
  final void Function(String? message, String? merchantTransactionId)?
  onPaymentFailed;
  final void Function()? onPaymentCancelled;

  @override
  ConsumerState<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends ConsumerState<PaymentMethodSheet> {
  bool _useNewCard = false;
  bool _resultHandled = false;
  String? _chargingCardId;
  String? _errorText;

  /// Shown when the edge function doesn't echo a transaction id back. The
  /// authoritative id — the random `mit-…` generated per saved-card charge —
  /// replaces this once the server returns it.
  String get _merchantTxnFallback => merchantTxnFallback(
    kind: widget.entityKindForVerify,
    id: widget.entityId,
  );

  @override
  void dispose() {
    // Leaving the sheet without an outcome (X, system back, OS pop) counts
    // as a user cancel so the parent releases the pending booking row. When
    // the card form is shown it owns this via its own dispose — the wrapped
    // callbacks below mark _resultHandled so we never double-fire.
    if (!_resultHandled) {
      _resultHandled = true;
      widget.onPaymentCancelled?.call();
    }
    super.dispose();
  }

  Future<void> _payWithCard(SavedCard card) async {
    setState(() {
      _chargingCardId = card.id;
      _errorText = null;
    });
    try {
      final result = await widget.tokenService.chargeSavedCard(
        tokenId: card.id,
        kind: widget.entityKindForVerify,
        id: widget.entityId,
        referenceId: widget.referenceId,
      );
      final merchantTxnId =
          result.merchantTransactionId ?? _merchantTxnFallback;
      if (result.paid) {
        _resultHandled = true;
        // Pop before the callback — see CardPaymentScreen._pay(): a callback
        // that synchronously pushes PaymentResultPage would otherwise have
        // its page removed by this pop instead of the sheet.
        if (mounted) Navigator.of(context).pop();
        widget.onPaymentSuccess?.call(
          widget.referenceId,
          widget.checkoutId,
          merchantTxnId,
        );
        return;
      }
      // Declined: keep the sheet open so the user can try another card or
      // switch to a new one. The pending row stays held until they close.
      // The transaction id is appended so it's visible even on inline
      // declines that never reach the result page.
      // The sheet is drag-dismissible mid-charge, so every setState after an
      // await needs a mounted guard.
      if (!mounted) return;
      final s = PaymentStrings.of(context);
      setState(() {
        final description = result.description ?? s.paymentFailedTryAgain;
        _errorText =
            '$description\n${s.transactionId}: '
            '$merchantTxnId';
      });
    } catch (_) {
      if (!mounted) return;
      final s = PaymentStrings.of(context);
      setState(() {
        _errorText = s.couldNotCompletePayment;
      });
    } finally {
      if (mounted) setState(() => _chargingCardId = null);
    }
  }

  void _handleClose() {
    if (!_resultHandled) {
      _resultHandled = true;
      widget.onPaymentCancelled?.call();
    }
    Navigator.pop(context);
  }

  Widget _cardForm() => CardPaymentScreen(
    checkoutId: widget.checkoutId,
    referenceId: widget.referenceId,
    entityKindForVerify: widget.entityKindForVerify,
    entityId: widget.entityId,
    paymentMode: widget.paymentMode,
    onPaymentSuccess: (ref_, orderId, merchantTxnId) {
      _resultHandled = true;
      widget.onPaymentSuccess?.call(ref_, orderId, merchantTxnId);
    },
    onPaymentFailed: (message, merchantTxnId) {
      _resultHandled = true;
      widget.onPaymentFailed?.call(message, merchantTxnId);
    },
    onPaymentCancelled: () {
      _resultHandled = true;
      widget.onPaymentCancelled?.call();
    },
  );

  @override
  Widget build(BuildContext context) {
    if (_useNewCard) return _cardForm();

    final theme = Theme.of(context);
    final cardsAsync = ref.watch(savedCardsProvider);

    return cardsAsync.when(
      // Card fetch failed (offline etc.) — don't block payment on it.
      error: (_, _) => _cardForm(),
      loading: () => Material(
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXL),
        ),
        child: const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      data: (cards) {
        if (cards.isEmpty) return _cardForm();

        final charging = _chargingCardId != null;
        return PaymentSheetShell(
          onClose: charging ? null : _handleClose,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final card in cards) ...[
                SavedCardTile(
                  card: card,
                  trailing: _chargingCardId == card.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  enabled: !charging,
                  onTap: () => _payWithCard(card),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: 4.0),
              UseNewCardButton(
                enabled: !charging,
                onTap: () => setState(() => _useNewCard = true),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                // Selectable so the appended transaction id can be copied.
                SelectableText(
                  _errorText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}
