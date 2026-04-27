import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/home/models/promoted_banner.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Top carousel ──────────────────────────────────────────────────────────────

class PromotedBanner extends ConsumerStatefulWidget {
  const PromotedBanner({super.key});

  @override
  ConsumerState<PromotedBanner> createState() => _PromotedBannerState();
}

class _PromotedBannerState extends ConsumerState<PromotedBanner> {
  late final PageController _ctrl;
  Timer? _timer;
  int _current = 0;
  int? _timerBannerCount;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  void _startTimer(int count) {
    _timer?.cancel();
    _timerBannerCount = count;
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % count;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(promotedBannersProvider);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context);

    return bannersAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => _buildSkeleton(theme),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        if (banners.length != _timerBannerCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_current >= banners.length) {
              setState(() => _current = 0);
              _ctrl.jumpToPage(0);
            }
            _startTimer(banners.length);
          });
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 82,
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: banners.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, index) =>
                      _BannerCard(banner: banners[index], isAr: isAr),
                ),
              ),
              if (banners.length > 1) ...[
                const SizedBox(height: 6),
                _DotsIndicator(count: banners.length, current: _current),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Inline single-banner slot (vertical lists) ───────────────────────────────
// Uses modulo so banners always cycle — no hard limit on appearances.

class PromotedBannerInline extends ConsumerWidget {
  const PromotedBannerInline({super.key, required this.slotIndex});

  final int slotIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(promotedBannersProvider);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context);

    return bannersAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => _buildSkeleton(theme),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        final banner = banners[slotIndex % banners.length];
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: _BannerCard(banner: banner, isAr: isAr),
        );
      },
    );
  }
}

// ── Inline banner card for horizontal carousels ───────────────────────────────
// Same card, taller (210 px) so it matches the carousel height.

class PromotedBannerCardInline extends ConsumerWidget {
  const PromotedBannerCardInline({super.key, required this.slotIndex});

  final int slotIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(promotedBannersProvider);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;

    return bannersAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        final banner = banners[slotIndex % banners.length];
        return SizedBox(
          width: 250,
          height: 210,
          child: _BannerCard(banner: banner, isAr: isAr, height: 210),
        );
      },
    );
  }
}

// ── Shared card widget ────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.isAr,
    this.height = 82,
  });

  final PromotedBannerModel banner;
  final bool isAr;
  final double height;

  VoidCallback? _onTap(BuildContext context) {
    if (banner.placeId != null) {
      return () => context.pushNamed(
            RouteNames.placeDetails,
            queryParameters: {'placeId': banner.placeId!},
          );
    }
    if (banner.eventId != null) {
      return () => context.pushNamed(
            RouteNames.eventDetails,
            queryParameters: {'eventId': banner.eventId!},
          );
    }
    if (banner.actionUrl != null) {
      return () async {
        final uri = Uri.tryParse(banner.actionUrl!);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = isAr ? 'ar' : 'en';
    final title = banner.displayNameFor(locale);
    final location = banner.displayLocationFor(locale);

    return GestureDetector(
      onTap: _onTap(context),
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: theme.colorScheme.primary),
                  errorWidget: (_, _, _) =>
                      Container(color: theme.colorScheme.surfaceContainer),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.black.withValues(alpha: 0.7),
                        AppColors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (location != null && location.isNotEmpty)
                            Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
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

// ── Dots indicator ────────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? primary : primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

Widget _buildSkeleton(ThemeData theme) => Skeletonizer(
  enabled: true,
  effect: ShimmerEffect(
    baseColor: theme.colorScheme.surfaceContainer,
    highlightColor: theme.colorScheme.surfaceContainerHighest,
    duration: const Duration(milliseconds: 1200),
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  ),
  child: Padding(
    padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
    child: Bone(
      height: 82,
      width: double.infinity,
      borderRadius: BorderRadius.circular(18),
    ),
  ),
);
