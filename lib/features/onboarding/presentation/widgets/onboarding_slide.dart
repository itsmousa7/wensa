import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/features/onboarding/presentation/widgets/onboarding_visual.dart';
import 'package:gap/gap.dart';

/// A single onboarding page: animated visual on top, then title + body.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final String asset;
  final IconData fallbackIcon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OnboardingVisual(
            asset: asset,
            fallbackIcon: fallbackIcon,
            accent: accent,
          ),
          const Gap(AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: tt.headlineMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const Gap(AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
