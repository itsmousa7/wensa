import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:intl/intl.dart';

import '../payment_strings.dart';
import 'payment_result_palette.dart';

/// Frosted glass panel with the date-time plus the HyperPay transaction id
/// (copyable), shown on both outcomes.
class PaymentResultDetailsPanel extends StatelessWidget {
  const PaymentResultDetailsPanel({
    super.key,
    required this.merchantTransactionId,
    required this.palette,
  });

  final String? merchantTransactionId;
  final PaymentResultPalette palette;

  static TextStyle labelStyle(PaymentResultPalette palette) => TextStyle(
    color: palette.ink.withValues(alpha: 0.55),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
  );

  static TextStyle valueStyle(PaymentResultPalette palette) =>
      TextStyle(color: palette.ink, fontSize: 15, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final s = PaymentStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final dateTime =
        '${DateFormat('d MMM yyyy', locale).format(now)}'
        ' • ${DateFormat('h:mm a', locale).format(now)}';
    final txnId = merchantTransactionId?.trim();

    // Each detail gets its own full-width row (long ids don't fit two-up),
    // separated by hairline dividers.
    Widget item(String label, String value, {Key? key}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle(palette)),
          const SizedBox(height: 4),
          Text(value, key: key, style: valueStyle(palette)),
        ],
      );
    }

    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Container(height: 1, color: palette.ink.withValues(alpha: 0.1)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.mlg,
      ),
      decoration: BoxDecoration(
        color: palette.panelFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          item(s.dateAndTime, dateTime),
          if (txnId?.isNotEmpty == true) ...[
            divider,
            _CopyableTxnRow(txnId: txnId!, palette: palette),
          ],
        ],
      ),
    );
  }
}

/// Transaction-id row: tapping anywhere on it copies the id to the clipboard
/// and briefly swaps the copy glyph for a "Copied" check.
class _CopyableTxnRow extends StatefulWidget {
  const _CopyableTxnRow({required this.txnId, required this.palette});

  final String txnId;
  final PaymentResultPalette palette;

  @override
  State<_CopyableTxnRow> createState() => _CopyableTxnRowState();
}

class _CopyableTxnRowState extends State<_CopyableTxnRow> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.txnId));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = PaymentStrings.of(context);

    return GestureDetector(
      key: const Key('payment_result_txn_copy'),
      behavior: HitTestBehavior.opaque,
      onTap: _copy,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.transactionIdCaps,
                  style: PaymentResultDetailsPanel.labelStyle(widget.palette),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.txnId,
                  key: const Key('payment_result_txn_id'),
                  style: PaymentResultDetailsPanel.valueStyle(widget.palette),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _copied
                ? Row(
                    key: const ValueKey('copied'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: widget.palette.ink,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.copied,
                        style: TextStyle(
                          color: widget.palette.ink.withValues(alpha: 0.85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    Icons.copy_rounded,
                    key: const ValueKey('copy'),
                    color: widget.palette.ink.withValues(alpha: 0.7),
                    size: 18,
                  ),
          ),
        ],
      ),
    );
  }
}
