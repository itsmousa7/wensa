import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

import '../../data/services/hyperpay_token_service.dart';
import '../../domain/models/saved_card.dart';
import '../providers/saved_cards_provider.dart';
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
  )? onPaymentSuccess;

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

  /// Mirrors create-booking's merchantTransactionId formula so a transaction
  /// id can always be shown even when the edge function doesn't echo one
  /// back (e.g. not yet redeployed). The authoritative id — the random
  /// `mit-…` generated per saved-card charge — replaces this once the
  /// server returns it.
  String get _merchantTxnFallback {
    final id = widget.entityKindForVerify == 'concert_group'
        ? 'booking-venue-${widget.entityId}'
        : 'booking-${widget.entityId}';
    return id.length > 32 ? id.substring(0, 32) : id;
  }

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
      final isAr =
          mounted && Localizations.localeOf(context).languageCode == 'ar';
      setState(() {
        final description = result.description ??
            (isAr
                ? 'فشلت عملية الدفع. يرجى المحاولة مرة أخرى.'
                : 'Payment failed. Please try again.');
        _errorText =
            '$description\n${isAr ? 'رقم العملية' : 'Transaction ID'}: '
            '$merchantTxnId';
      });
    } catch (_) {
      setState(() {
        _errorText =
            'Could not complete payment — check your connection and try again.';
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

  Widget _brandIcon(String? brand) {
    final asset = switch (brand) {
      'VISA' => 'assets/icons/visa.svg',
      'MASTER' => 'assets/icons/mastercard.svg',
      _ => null,
    };
    if (asset == null) return const Icon(Icons.credit_card, size: 28);
    // Square box for Mastercard — its SVG viewBox is square with the card
    // artwork only ~⅔ of the height, so a 36×24 box shrinks it vs Visa.
    // Mirrors SavedCardsPage._brandIcon.
    return SizedBox(
      width: 36,
      height: brand == 'MASTER' ? 36 : 24,
      child: SvgPicture.asset(asset, fit: BoxFit.contain),
    );
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
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        return Material(
          color: theme.colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXL),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: AppSpacing.borderRadiusXS,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isAr ? 'الدفع' : 'Payment',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: charging ? null : _handleClose,
                    ),
                  ],
                ),
                for (final card in cards) ...[
                  ListTile(
                    key: Key('saved_card_${card.id}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusLG,
                    ),
                    // Dark theme's surfaceContainer matches the sheet surface
                    // (tiles vanish) — use the highest container tone there.
                    tileColor: theme.brightness == Brightness.dark
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.surfaceContainer,
                    leading: _brandIcon(card.brand),
                    // Card name/masked number stays LTR — it embeds Latin
                    // digits that must not mirror under Arabic.
                    // Explicit onSurface colors: the app's dark textTheme is
                    // baked with light-mode colors, so relying on the default
                    // style renders dark-on-dark here.
                    title: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        card.displayName,
                        textAlign: isAr ? TextAlign.right : TextAlign.left,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    subtitle: card.expiryLabel == null
                        ? null
                        : Text(
                            isAr
                                ? 'تنتهي في ${card.expiryLabel}'
                                : 'Expires ${card.expiryLabel}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
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
                _UseNewCardButton(
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
          ),
        );
      },
    );
  }
}

/// "Use a new card" affordance: a dashed-outline tile with a tinted plus
/// badge, styled to read as an add-new-item action rather than another
/// payment option in the list.
class _UseNewCardButton extends StatelessWidget {
  const _UseNewCardButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('use_new_card'),
          onTap: enabled ? onTap : null,
          borderRadius: AppSpacing.borderRadiusLG,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: cs.primary.withValues(alpha: 0.4),
              radius: AppSpacing.radiusLG,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'استخدام بطاقة جديدة'
                          : 'Use a new card',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: cs.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded dashed-rectangle outline, painted once per layout pass.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;
  static const double strokeWidth = 1.4;
  static const double dashWidth = 6;
  static const double dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
