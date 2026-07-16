import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:intl/intl.dart';

/// Immersive full-screen payment outcome page shown right after a HyperPay
/// transaction completes. The whole page is tinted by the outcome — a deep
/// green gradient for success, deep red for failure — with a pulsing status
/// badge, the gateway's decline description on failure, a frosted details
/// panel, and a 5-second countdown ring that auto-redirects when it finishes
/// (tapping it, or anywhere, skips the wait).
///
/// The page pops itself before invoking [onDone], so callers can safely
/// `context.go(...)` from the callback. Back gestures are intercepted and
/// treated as "continue now" to keep the redirect deterministic.
class PaymentResultPage extends StatefulWidget {
  const PaymentResultPage({
    super.key,
    required this.success,
    this.message,
    this.merchantTransactionId,
    this.onDone,
    this.countdown,
  });

  final bool success;

  /// Failure description from HyperPay (ignored on success, where a fixed
  /// confirmation line is shown instead).
  final String? message;

  /// HyperPay merchantTransactionId — shown (and copyable) on both outcomes
  /// so users can quote it to support.
  final String? merchantTransactionId;

  /// Runs after the page has popped itself (countdown elapsed or tapped).
  final VoidCallback? onDone;

  /// Time before auto-redirect. `null` (the default) disables the countdown:
  /// the page stays up until the user taps to continue.
  final Duration? countdown;

  /// Pushes the page as a fade-through route on the root navigator (above
  /// any open bottom sheets).
  static Future<void> show(
    BuildContext context, {
    required bool success,
    String? message,
    String? merchantTransactionId,
    VoidCallback? onDone,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: PaymentResultPage(
            success: success,
            message: message,
            merchantTransactionId: merchantTransactionId,
            onDone: onDone,
          ),
        ),
      ),
    );
  }

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  /// Slow ambient loop driving the badge pulse rings and drifting orbs.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  late final AnimationController? _timer = widget.countdown == null
      ? null
      : AnimationController(vsync: this, duration: widget.countdown);

  bool _finished = false;

  late final Animation<double> _badgePop = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.05, 0.55, curve: Curves.elasticOut),
  );
  late final Animation<double> _titleIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _detailsIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _timer
      ?..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _timer?.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    Navigator.of(context).pop();
    widget.onDone?.call();
  }

  // Outcome palettes follow the app theme: airy white with dark ink in light
  // mode, deep charcoal with light ink in dark mode — success tinted green,
  // failure tinted red.
  _Palette _paletteFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    if (widget.success) {
      return dark ? _Palette.successDark : _Palette.successLight;
    }
    return dark ? _Palette.failureDark : _Palette.failureLight;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = _paletteFor(brightness);
    // Same bilingual pattern as the rest of the app (see BilingualLabel):
    // inline en/ar picked off the active locale. HyperPay's decline
    // description is shown as-is — it comes from the gateway.
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final subtitle = widget.success
        ? (isAr
            ? 'تم تأكيد حجزك بنجاح'
            : 'Your booking has been confirmed successfully')
        : (widget.message?.trim().isNotEmpty == true
            ? widget.message!.trim()
            : (isAr
                ? 'تعذّر إتمام عملية الدفع. يرجى المحاولة مرة أخرى.'
                : 'Your payment could not be completed. Please try again.'));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.gradient,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _DriftingOrbs(
                    ambient: _ambient,
                    glow: palette.glow,
                    opacityScale: palette.orbOpacityScale,
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 3),
                          _PulsingBadge(
                            success: widget.success,
                            glow: palette.glow,
                            pop: _badgePop,
                            ambient: _ambient,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Reveal(
                            animation: _titleIn,
                            child: Column(
                              children: [
                                Text(
                                  widget.success
                                      ? (isAr ? 'شكراً لك!' : 'Thank you!')
                                      : (isAr
                                          ? 'فشلت عملية الدفع'
                                          : 'Payment failed'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  subtitle,
                                  key: const Key('payment_result_message'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.ink.withValues(alpha: 0.75),
                                    fontSize: 15,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Reveal(
                            animation: _detailsIn,
                            child: _DetailsPanel(
                              merchantTransactionId:
                                  widget.merchantTransactionId,
                              palette: palette,
                              isAr: isAr,
                            ),
                          ),
                          const Spacer(flex: 4),
                          _Reveal(
                            animation: _detailsIn,
                            child: Column(
                              children: [
                                if (_timer != null) ...[
                                  _CountdownRing(
                                    key: const Key('payment_result_countdown'),
                                    progress: _timer,
                                    palette: palette,
                                    onTap: _finish,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                Text(
                                  _timer != null
                                      ? (widget.success
                                          ? (isAr
                                              ? 'جارٍ نقلك إلى حجزك · اضغط للتخطي'
                                              : 'Taking you to your booking · tap to skip')
                                          : (isAr
                                              ? 'العودة إلى الحجز · اضغط للتخطي'
                                              : 'Returning to booking · tap to skip'))
                                      : (isAr
                                          ? 'اضغط في أي مكان للمتابعة'
                                          : 'Tap anywhere to continue'),
                                  style: TextStyle(
                                    color: palette.ink.withValues(alpha: 0.5),
                                    fontSize: 12.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
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

/// Per-outcome color system: background gradient, primary text ("ink"),
/// glow accent, and frosted-panel tints — so the same layout works on both
/// the white success page and the dark failure page.
class _Palette {
  const _Palette({
    required this.gradient,
    required this.ink,
    required this.glow,
    required this.panelFill,
    required this.panelBorder,
    required this.orbOpacityScale,
  });

  final List<Color> gradient;
  final Color ink;
  final Color glow;
  final Color panelFill;
  final Color panelBorder;

  /// Orbs read stronger on white, so success dampens them.
  final double orbOpacityScale;

  static const successLight = _Palette(
    gradient: [Colors.white, Color(0xFFF6FCF9), Color(0xFFE9F8F0)],
    ink: Color(0xFF0B2B20),
    glow: Color(0xFF2DC182),
    panelFill: Color(0x0D0B2B20), // ink 5%
    panelBorder: Color(0x1F0B2B20), // ink 12%
    orbOpacityScale: 0.7,
  );

  static const failureLight = _Palette(
    gradient: [Colors.white, Color(0xFFFDF7F7), Color(0xFFFBECEC)],
    ink: Color(0xFF33100F),
    glow: Color(0xFFE5484D),
    panelFill: Color(0x0D33100F), // ink 5%
    panelBorder: Color(0x1F33100F), // ink 12%
    orbOpacityScale: 0.7,
  );

  static const successDark = _Palette(
    gradient: [Color(0xFF0C1211), Color(0xFF0E1B16), Color(0xFF11251C)],
    ink: Color(0xFFEAF6F0),
    glow: Color(0xFF3DDC97),
    panelFill: Color(0x14FFFFFF), // white 8%
    panelBorder: Color(0x1FFFFFFF), // white 12%
    orbOpacityScale: 1,
  );

  static const failureDark = _Palette(
    gradient: [Color(0xFF141010), Color(0xFF1E1213), Color(0xFF291516)],
    ink: Color(0xFFF7EDED),
    glow: Color(0xFFFF6B6B),
    panelFill: Color(0x14FFFFFF), // white 8%
    panelBorder: Color(0x1FFFFFFF), // white 12%
    orbOpacityScale: 1,
  );
}

/// Fade + gentle upward slide used for the staged content reveal.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Status badge: glowing disc with the check/cross, wrapped in two soft
/// rings that continuously ripple outwards.
class _PulsingBadge extends StatelessWidget {
  const _PulsingBadge({
    required this.success,
    required this.glow,
    required this.pop,
    required this.ambient,
  });

  final bool success;
  final Color glow;
  final Animation<double> pop;
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: pop,
      child: SizedBox(
        height: 168,
        child: AnimatedBuilder(
          animation: ambient,
          builder: (context, child) {
            return CustomPaint(
              painter: _RipplePainter(t: ambient.value, color: glow),
              child: child,
            );
          },
          child: Center(
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [glow, glow.withValues(alpha: 0.75)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.45),
                    blurRadius: 48,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two staggered rings expanding and fading around the badge, looped.
class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (final phase in const [0.0, 0.5]) {
      final p = (t + phase) % 1;
      final radius = 54 + p * 46;
      final opacity = (1 - p) * 0.35;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + (1 - p) * 1.5
          ..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.t != t || old.color != color;
}

/// Soft translucent orbs drifting slowly in the backdrop for depth.
class _DriftingOrbs extends StatelessWidget {
  const _DriftingOrbs({
    required this.ambient,
    required this.glow,
    required this.opacityScale,
  });

  final Animation<double> ambient;
  final Color glow;
  final double opacityScale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, _) {
        final t = ambient.value * 2 * math.pi;
        return CustomPaint(
          painter: _OrbsPainter(t: t, color: glow, opacityScale: opacityScale),
        );
      },
    );
  }
}

class _OrbsPainter extends CustomPainter {
  const _OrbsPainter({
    required this.t,
    required this.color,
    required this.opacityScale,
  });

  final double t;
  final Color color;
  final double opacityScale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    void orb(double fx, double fy, double r, double drift, double phase,
        double alpha) {
      canvas.drawCircle(
        Offset(
          size.width * fx + math.sin(t + phase) * drift,
          size.height * fy + math.cos(t + phase) * drift,
        ),
        r,
        paint..color = color.withValues(alpha: alpha * opacityScale),
      );
    }

    orb(0.15, 0.12, 70, 14, 0, 0.10);
    orb(0.88, 0.28, 52, 18, 2.1, 0.08);
    orb(0.10, 0.78, 60, 16, 4.2, 0.07);
    orb(0.85, 0.88, 80, 12, 1.3, 0.09);
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter old) =>
      old.t != t || old.color != color || old.opacityScale != opacityScale;
}

/// Frosted glass panel with the date-time plus the HyperPay transaction id
/// (copyable), shown on both outcomes.
class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.merchantTransactionId,
    required this.palette,
    required this.isAr,
  });

  final String? merchantTransactionId;
  final _Palette palette;
  final bool isAr;

  static TextStyle labelStyle(_Palette palette) => TextStyle(
        color: palette.ink.withValues(alpha: 0.55),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      );
  static TextStyle valueStyle(_Palette palette) => TextStyle(
        color: palette.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final dateTime = '${DateFormat('d MMM yyyy', locale).format(now)}'
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
          item(isAr ? 'التاريخ والوقت' : 'DATE & TIME', dateTime),
          if (txnId?.isNotEmpty == true) ...[
            divider,
            _CopyableTxnRow(txnId: txnId!, palette: palette, isAr: isAr),
          ],
        ],
      ),
    );
  }
}

/// Transaction-id row: tapping anywhere on it copies the id to the clipboard
/// and briefly swaps the copy glyph for a "Copied" check.
class _CopyableTxnRow extends StatefulWidget {
  const _CopyableTxnRow({
    required this.txnId,
    required this.palette,
    required this.isAr,
  });

  final String txnId;
  final _Palette palette;
  final bool isAr;

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
                  widget.isAr ? 'رقم العملية' : 'TRANSACTION ID',
                  style: _DetailsPanel.labelStyle(widget.palette),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.txnId,
                  key: const Key('payment_result_txn_id'),
                  style: _DetailsPanel.valueStyle(widget.palette),
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
                      Icon(Icons.check_rounded,
                          color: widget.palette.ink, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.isAr ? 'تم النسخ' : 'Copied',
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

/// Depleting countdown ring with the remaining seconds in the middle.
/// Tapping it skips straight to the redirect.
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    super.key,
    required this.progress,
    required this.palette,
    required this.onTap,
  });

  final AnimationController progress;
  final _Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final remaining =
              (progress.duration! * (1 - progress.value)).inSeconds + 1;
          return Center(
            child: CustomPaint(
              painter: _RingPainter(
                progress: 1 - progress.value,
                color: palette.ink,
                track: palette.ink.withValues(alpha: 0.18),
                glow: palette.glow,
              ),
              child: SizedBox(
                width: 62,
                height: 62,
                child: Center(
                  child: Text(
                    '$remaining',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.glow,
  });

  final double progress;
  final Color color;
  final Color track;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base..color = track);
    // Soft halo behind the active arc.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = glow.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false,
        base..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.glow != glow;
}
