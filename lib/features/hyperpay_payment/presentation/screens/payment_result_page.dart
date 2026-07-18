import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

import '../payment_strings.dart';
import '../widgets/payment_result_details_panel.dart';
import '../widgets/payment_result_effects.dart';
import '../widgets/payment_result_palette.dart';

/// Immersive full-screen payment outcome page shown right after a HyperPay
/// transaction completes. The whole page is tinted by the outcome — a deep
/// green gradient for success, deep red for failure — with a pulsing status
/// badge, the gateway's decline description on failure, a frosted details
/// panel, and an optional countdown ring that auto-redirects when it finishes
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
    Duration? countdown,
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
            countdown: countdown,
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

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = PaymentResultPalette.forOutcome(
      success: widget.success,
      brightness: brightness,
    );
    // HyperPay's decline description is shown as-is — it comes from the
    // gateway, already localized on their side.
    final s = PaymentStrings.of(context);
    final subtitle = widget.success
        ? s.bookingConfirmed
        : (widget.message?.trim().isNotEmpty == true
              ? widget.message!.trim()
              : s.paymentCouldNotComplete);

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
                  DriftingOrbs(
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
                          PulsingBadge(
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
                                      ? s.thankYou
                                      : s.paymentFailedTitle,
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
                            child: PaymentResultDetailsPanel(
                              merchantTransactionId:
                                  widget.merchantTransactionId,
                              palette: palette,
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
                                            ? s.takingYouToBooking
                                            : s.returningToBooking)
                                      : s.tapAnywhereToContinue,
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
  final PaymentResultPalette palette;
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
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      base..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.glow != glow;
}
