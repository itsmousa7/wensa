import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';

// ---------------------------------------------------------------------------
// Data model for a single detail row
// ---------------------------------------------------------------------------

/// One labelled row inside [BookingSummaryCard].
class BookingSummaryRow {
  const BookingSummaryRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;

  /// Plain-text value. Ignored when [valueWidget] is provided.
  final String? value;

  /// Widget value (e.g. a BilingualLabel). Takes precedence over [value].
  final Widget? valueWidget;
}

// ---------------------------------------------------------------------------
// BookingSummaryCard
// ---------------------------------------------------------------------------

/// Polished booking summary card shared across all booking sections.
///
/// Shows a primary-colored header, detail rows, an optional total-amount
/// highlight, and a primary-colored action button.
class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({
    super.key,
    required this.title,
    this.badgeText,
    required this.rows,
    this.totalLabel,
    this.totalValue,
    this.subtotalLabel,
    this.subtotalValue,
    this.discountLabel,
    this.discountValue,
    this.extraSlot,
    required this.actionLabel,
    required this.onAction,
    required this.isLoading,
  });

  /// Header title, e.g. "Booking Summary" / "ملخص الحجز".
  final String title;

  /// Optional pill badge in the header, e.g. "2 hours" / "Day".
  final String? badgeText;

  /// Detail rows shown in the card body.
  final List<BookingSummaryRow> rows;

  /// Label for the total-amount highlight row (omit for free bookings).
  final String? totalLabel;

  /// Formatted total value, e.g. "IQD 50,000" (omit for free bookings).
  final String? totalValue;

  /// Optional pre-discount subtotal text (e.g. "IQD 40,000"). When set
  /// alongside [discountValue], the total row renders with a struck-through
  /// subtotal + a discount row above it.
  final String? subtotalLabel;
  final String? subtotalValue;

  /// Optional discount line (e.g. label="10% OFF", value="−IQD 4,000").
  final String? discountLabel;
  final String? discountValue;

  /// Optional slot rendered just above the action button (e.g. the
  /// promo-code field).
  final Widget? extraSlot;

  /// Text on the action button.
  final String actionLabel;

  /// Called when the action button is tapped; null disables the button.
  final VoidCallback? onAction;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Gradient header ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (badgeText != null) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Detail rows with dividers
                for (var i = 0; i < rows.length; i++) ...[
                  _DetailRow(row: rows[i]),
                  if (i < rows.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                ],

                // Subtotal + discount + total stack
                if (totalValue != null) ...[
                  const SizedBox(height: 16),
                  if (discountValue != null && subtotalValue != null) ...[
                    _SummaryLineRow(
                      label: subtotalLabel ?? 'Subtotal',
                      value: subtotalValue!,
                      strikethrough: true,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 6),
                    _SummaryLineRow(
                      label: discountLabel ?? 'Discount',
                      value: discountValue!,
                      color: const Color(0xFFE53935),
                      bold: true,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_rounded,
                            size: 20, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          totalLabel ?? 'Total Amount',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          totalValue!,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (extraSlot != null) ...[
                  const SizedBox(height: 14),
                  extraSlot!,
                ],

                const SizedBox(height: 18),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isLoading
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isLoading ? null : onAction,
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  actionLabel,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                    fontFamily: AppTypography.buttonFontFamily(
                                        isAr ? 'ar' : 'en'),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail row
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row});
  final BookingSummaryRow row;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(row.icon, size: 16, color: colorScheme.outline),
        const SizedBox(width: 8),
        Text(
          row.label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colorScheme.outline),
        ),
        const Spacer(),
        row.valueWidget ??
            Text(
              row.value ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.outline,
                  ),
            ),
      ],
    );
  }
}

class _SummaryLineRow extends StatelessWidget {
  const _SummaryLineRow({
    required this.label,
    required this.value,
    this.strikethrough = false,
    this.bold = false,
    this.color,
  });
  final String label;
  final String value;
  final bool strikethrough;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final style = base.copyWith(
      color: color,
      decoration: strikethrough ? TextDecoration.lineThrough : null,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}
