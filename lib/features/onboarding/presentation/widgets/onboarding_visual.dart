import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:lottie/lottie.dart';

/// Renders a slide's Lottie animation inside a soft glass card.
///
/// If the asset is missing or fails to decode, it degrades to an on-theme
/// gradient orb with a fallback icon so the screen never looks broken.
class OnboardingVisual extends StatelessWidget {
  const OnboardingVisual({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    required this.accent,
  });

  /// Path to the Lottie JSON, e.g. `assets/lottie/onboarding/discover.json`.
  final String asset;
  final IconData fallbackIcon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft radial glow behind the art.
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Lottie.asset(
              asset,
              fit: BoxFit.contain,
              repeat: true,
              errorBuilder: (context, error, stack) =>
                  _Fallback(icon: fallbackIcon, accent: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, AppColors.headline],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(icon, size: 72, color: AppColors.white),
      ),
    );
  }
}
