// lib/features/bookings_history/presentation/widgets/ticket_visual_card.dart
//
// Reusable ticket visual (info section, tear line, QR), used both on the ticket
// detail screen and inside the shareable ticket image.
import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_riverpod/core/share/branded_header.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/qr_block.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

const double _kTopHeight = 270.0;
const double _kTearHalf = 14.0;
const double _kNotchRadius = 14.0;

class TicketInfoCell {
  const TicketInfoCell({required this.label, required this.value, this.forceLtr = true});
  final String label;
  final String value;
  final bool forceLtr;
}

/// The ticket card visual. Stateful only to measure the top section so the
/// tear-line notch lines up at the right Y.
class TicketVisualCard extends StatefulWidget {
  const TicketVisualCard({
    super.key,
    required this.qrToken,
    required this.displayName,
    required this.isArabic,
    required this.statusBadge,
    required this.cells,
    this.transactionId,
    this.shareMode = false,
  });

  final String qrToken;
  final String displayName;
  final bool isArabic;
  final Widget statusBadge;
  final List<TicketInfoCell> cells;

  /// HyperPay merchantTransactionId — the reference support asks for. Shown
  /// only on the live card: it's a copy-to-clipboard affordance, so it would
  /// be dead weight in the shared image.
  final String? transactionId;
  final bool shareMode;

  @override
  State<TicketVisualCard> createState() => _TicketVisualCardState();
}

class _TicketVisualCardState extends State<TicketVisualCard> {
  final _topKey = GlobalKey();
  double _tearLineY = _kTopHeight + _kTearHalf;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTearLine());
  }

  void _updateTearLine() {
    final ctx = _topKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final actual = box.size.height + _kTearHalf;
    if ((actual - _tearLineY).abs() > 0.5) {
      setState(() => _tearLineY = actual);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = cs.surfaceContainer;
    final tearLineY = _tearLineY;

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipPath(
        clipper: _TicketClipper(tearLineY),
        child: Container(
          color: cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                key: _topKey,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.displayName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    widget.statusBadge,
                    const SizedBox(height: 20),
                    _InfoGrid(cells: widget.cells),
                    if (!widget.shareMode &&
                        widget.transactionId != null &&
                        widget.transactionId!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _GlassFieldRow(
                        label: widget.isArabic
                            ? 'رقم العملية'
                            : 'Transaction ID',
                        value: widget.transactionId!,
                        isArabic: widget.isArabic,
                        // 32-char ids don't fit a capsule on one line; a
                        // rounded rect wraps cleanly to two.
                        capsule: false,
                        compactValue: true,
                      ),
                    ],
                  ],
                ),
              ),
              _TearLine(color: cs.onSurface.withValues(alpha: 0.18)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  children: [
                    Text(
                      widget.isArabic ? 'امسح رمز QR' : 'Scan This QR',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isArabic
                          ? 'وجّه الكاميرا إلى مكان المسح'
                          : 'Point This QR To The Scan Place',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: AppSpacing.borderRadiusXL,
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: widget.qrToken.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: QrBlock(qrToken: widget.qrToken),
                            )
                          : SizedBox(
                              width: 232,
                              height: 232,
                              child: Icon(
                                Icons.qr_code_rounded,
                                size: 120,
                                color: cs.onSurface.withValues(alpha: 0.15),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded, fixed-width composition for the shared ticket image.
class ShareableTicketVisualCard extends StatelessWidget {
  const ShareableTicketVisualCard({
    super.key,
    required this.qrToken,
    required this.displayName,
    required this.isArabic,
    required this.statusBadge,
    required this.cells,
  });

  final String qrToken;
  final String displayName;
  final bool isArabic;
  final Widget statusBadge;
  final List<TicketInfoCell> cells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 360,
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandedHeader(),
          const SizedBox(height: 16),
          TicketVisualCard(
            qrToken: qrToken,
            displayName: displayName,
            isArabic: isArabic,
            statusBadge: statusBadge,
            cells: cells,
            shareMode: true,
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.cells});
  final List<TicketInfoCell> cells;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final rows = <List<TicketInfoCell>>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add([cells[i], if (i + 1 < cells.length) cells[i + 1]]);
    }

    return Column(
      children: List.generate(rows.length, (ri) {
        final row = rows[ri];
        return Column(
          children: [
            if (ri > 0)
              Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: row.map((cell) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell.label,
                          style: tt.labelSmall?.copyWith(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Values are always numeric/Latin (dates, times, amounts,
                        // codes). Force LTR so the Arabic RTL layout doesn't
                        // reorder them (e.g. "12 Jun 2026" -> "Jun 2026 12"); the
                        // block still sits on the start edge under the label.
                        Text(
                          cell.value,
                          textDirection: cell.forceLtr ? TextDirection.ltr : null,
                          style: tt.titleMedium?.copyWith(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.1,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// A copyable field on the ticket (Code, Transaction ID).
///
/// On iOS 26+ the pill itself is a native Liquid Glass container and the copy
/// button is a native glass button. Everywhere else (Android, iOS < 26, where
/// `LiquidGlassContainer` renders nothing at all) it falls back to the
/// hand-rolled frosted gradient this started as.
class _GlassFieldRow extends StatelessWidget {
  const _GlassFieldRow({
    required this.label,
    required this.value,
    required this.isArabic,
    this.capsule = true,
    this.compactValue = false,
  });

  final String label;
  final String value;
  final bool isArabic;

  /// Capsule for short values; a rounded rect for ones that wrap.
  final bool capsule;

  /// Smaller, tighter value type so a long id fits the card width.
  final bool compactValue;

  static const double _kRectRadius = 22.0;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final borderColor = cs.onSurface.withValues(alpha: 0.18);

    void onCopy() {
      Clipboard.setData(ClipboardData(text: value));
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تم النسخ' : 'Copied'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // iOS — native Liquid Glass copy button. Android keeps the original
    // bordered button.
    final Widget copyButton = Platform.isIOS
        ? CNButton.icon(
            onPressed: onCopy,
            icon: CNSymbol('doc.on.doc', size: 15, color: cs.primary),
            config: const CNButtonConfig(
              style: CNButtonStyle.glass,
              width: 50,
              minHeight: 34,
            ),
          )
        : GestureDetector(
            onTap: onCopy,
            child: Container(
              width: 50,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: AppSpacing.borderRadiusLG,
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Icon(
                Icons.content_copy_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          );

    final textColumn = Expanded(
      child: Column(
        crossAxisAlignment: isArabic
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            // Values here are Latin/numeric references. Force LTR so the
            // Arabic layout doesn't reorder them.
            textDirection: TextDirection.ltr,
            textAlign: isArabic ? TextAlign.end : TextAlign.start,
            maxLines: 2,
            style: compactValue
                ? tt.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  )
                : tt.titleSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
          ),
        ],
      ),
    );

    // Force LTR on the Row so the explicit child order is visually respected
    // regardless of the app's text direction (Arabic RTL would otherwise flip it).
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: isArabic
            ? [copyButton, const SizedBox(width: 12), textColumn]
            : [textColumn, const SizedBox(width: 12), copyButton],
      ),
    );

    final Widget field;
    if (PlatformVersion.supportsLiquidGlass) {
      field = LiquidGlassContainer(
        config: LiquidGlassConfig(
          shape: capsule
              ? CNGlassEffectShape.capsule
              : CNGlassEffectShape.rect,
          cornerRadius: capsule ? null : _kRectRadius,
        ),
        child: content,
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final radius = BorderRadius.circular(capsule ? 999 : _kRectRadius);
      field = Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: isDark ? 0.22 : 0.68),
              Colors.white.withValues(alpha: isDark ? 0.08 : 0.32),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.38 : 0.85),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.50),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      );
    }

    return Directionality(textDirection: TextDirection.ltr, child: field);
  }
}

class _TearLine extends StatelessWidget {
  const _TearLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kTearHalf * 2,
      child: CustomPaint(
        painter: _DashPainter(color: color),
        size: const Size(double.infinity, _kTearHalf * 2),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 9.0;
    const gapWidth = 7.0;
    final y = size.height / 2;
    double x = 4.0;
    while (x < size.width - 4) {
      final end = (x + dashWidth).clamp(0.0, size.width - 4.0);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper(this.tearLineY);
  final double tearLineY;

  @override
  Path getClip(Size size) {
    const r = 24.0;
    const nr = _kNotchRadius;
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(
        Offset(w, r),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(w, tearLineY - nr)
      ..arcToPoint(
        Offset(w, tearLineY + nr),
        radius: const Radius.circular(nr),
        clockwise: false,
      )
      ..lineTo(w, h - r)
      ..arcToPoint(
        Offset(w - r, h),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(r, h)
      ..arcToPoint(
        Offset(0, h - r),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(0, tearLineY + nr)
      ..arcToPoint(
        Offset(0, tearLineY - nr),
        radius: const Radius.circular(nr),
        clockwise: false,
      )
      ..lineTo(0, r)
      ..arcToPoint(
        Offset(r, 0),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..close();
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.tearLineY != tearLineY;
}
