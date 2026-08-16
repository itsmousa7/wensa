import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ambient decoration for the payment result page: the drifting backdrop orbs
/// and the pulsing status badge. Both are driven by the page's looping
/// `_ambient` controller.

/// Soft translucent orbs drifting slowly in the backdrop for depth.
class DriftingOrbs extends StatelessWidget {
  const DriftingOrbs({
    super.key,
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
          painter: OrbsPainter(t: t, color: glow, opacityScale: opacityScale),
        );
      },
    );
  }
}

class OrbsPainter extends CustomPainter {
  const OrbsPainter({
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

    void orb(
      double fx,
      double fy,
      double r,
      double drift,
      double phase,
      double alpha,
    ) {
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
  bool shouldRepaint(covariant OrbsPainter old) =>
      old.t != t || old.color != color || old.opacityScale != opacityScale;
}

/// Status badge: glowing disc with the check/cross, wrapped in two soft
/// rings that continuously ripple outwards.
class PulsingBadge extends StatelessWidget {
  const PulsingBadge({
    super.key,
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
              painter: RipplePainter(t: ambient.value, color: glow),
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
class RipplePainter extends CustomPainter {
  const RipplePainter({required this.t, required this.color});

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
  bool shouldRepaint(covariant RipplePainter old) =>
      old.t != t || old.color != color;
}
