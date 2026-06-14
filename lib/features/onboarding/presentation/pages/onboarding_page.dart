import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/core/widgets/primary_action_button.dart';
import 'package:future_riverpod/features/onboarding/data/onboarding_provider.dart';
import 'package:future_riverpod/features/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// First-launch onboarding: three slides introducing the app, with a language
/// toggle, a skip shortcut, and a Get Started CTA that finishes onboarding.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_SlideData>[
    _SlideData(
      asset: 'assets/lottie/onboarding/discover.lottie',
      fallbackIcon: Icons.directions_car_outlined,
      accent: AppColors.lightGreenPrimary,
      titleKey: 'onboarding_title_1',
      bodyKey: 'onboarding_body_1',
    ),
    _SlideData(
      asset: 'assets/lottie/onboarding/venues.lottie',
      fallbackIcon: Icons.sports_soccer_outlined,
      accent: AppColors.headline,
      titleKey: 'onboarding_title_2',
      bodyKey: 'onboarding_body_2',
    ),
    _SlideData(
      asset: 'assets/lottie/onboarding/joy.lottie',
      fallbackIcon: Icons.celebration_outlined,
      accent: AppColors.lightGreenSecondary,
      titleKey: 'onboarding_title_3',
      bodyKey: 'onboarding_body_3',
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    await ref.read(hasSeenOnboardingProvider.notifier).complete();
    if (!mounted) return;
    context.goNamed(RouteNames.signin);
  }

  void _toggleLanguage() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    ref
        .read(appLocaleProvider.notifier)
        .switchLocale(isAr ? const EnglishLocale() : const ArabicLocale());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _slides[_index].accent;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.12),
              cs.surface,
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                onToggleLanguage: _toggleLanguage,
                onSkip: _finish,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return OnboardingSlide(
                      asset: s.asset,
                      fallbackIcon: s.fallbackIcon,
                      accent: s.accent,
                      title: context.tr(s.titleKey),
                      body: context.tr(s.bodyKey),
                    );
                  },
                ),
              ),
              const Gap(AppSpacing.lg),
              _Dots(count: _slides.length, index: _index, color: cs.primary),
              const Gap(AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: PrimaryActionButton(
                  label: _isLast
                      ? context.tr('onboarding_get_started')
                      : context.tr('onboarding_next'),
                  onTap: _next,
                ),
              ),
              const Gap(AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onToggleLanguage, required this.onSkip});

  final VoidCallback onToggleLanguage;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.mlg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language toggle (ع | EN)
          GestureDetector(
            onTap: onToggleLanguage,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: AppSpacing.borderRadiusLG,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 18, color: cs.onSurface),
                  const Gap(AppSpacing.sm),
                  Text(
                    isAr ? 'EN' : 'العربية',
                    style: tt.labelLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Skip
          TextButton(
            onPressed: onSkip,
            child: Text(
              context.tr('onboarding_skip'),
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.color});

  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 24 : 8,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.asset,
    required this.fallbackIcon,
    required this.accent,
    required this.titleKey,
    required this.bodyKey,
  });

  final String asset;
  final IconData fallbackIcon;
  final Color accent;
  final String titleKey;
  final String bodyKey;
}
