import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';

/// Standalone "Payment Method" card, placed above the booking summary card
/// (or inline in a checkout sheet) instead of a modal dialog. Purely
/// presentational — the caller owns the selected value.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.cashEnabled,
    required this.selected,
    required this.onChanged,
  });

  /// Whether the Cash row is shown at all — false when the merchant/event
  /// has cash off, in which case E-Payment is the only option offered.
  final bool cashEnabled;

  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onChanged;

  /// Key carried by the inner filled dot of the *selected* row's radio
  /// indicator. Only present on the selected row, so tests (and callers) can
  /// assert which method is currently picked.
  static const radioFillKey = ValueKey('payment-method-radio-fill');

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'طريقة الدفع' : 'Payment Method',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (cashEnabled) ...[
            _SelectorRow(
              icon: Icons.payments_rounded,
              iconBg: cs.primary,
              title: isAr ? 'نقداً' : 'Cash',
              subtitle: isAr ? 'ادفع عند الوصول' : 'Pay at the venue',
              isSelected: selected == PaymentMethod.cash,
              onTap: () => onChanged(PaymentMethod.cash),
            ),
            const _DashedDivider(),
          ],
          _SelectorRow(
            icon: Icons.credit_card_rounded,
            iconBg: cs.primary,
            title: isAr ? 'دفع الكتروني' : 'E-Payment',
            subtitle: isAr ? 'ادفع الآن عبر الإنترنت' : 'Pay online now',
            isSelected: selected == PaymentMethod.hyperpay,
            onTap: () => onChanged(PaymentMethod.hyperpay),
          ),
        ],
      ),
    );
  }
}

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            _RadioDot(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? cs.primary : cs.outline,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                key: PaymentMethodSelector.radioFillKey,
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary,
                ),
              ),
            )
          : null,
    );
  }
}

/// Flutter's stock [Divider] is solid, so this is a small one-off dashed
/// line to match the reference design's separator between rows.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 1,
        child: CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedLinePainter(color: color),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashGap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      // Clamp so the final dash stops at the edge instead of overshooting.
      final end = math.min(x + dashWidth, size.width);
      canvas.drawLine(Offset(x, 0), Offset(end, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
