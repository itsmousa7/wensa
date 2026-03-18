import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PromotedBanner extends ConsumerWidget {
  const PromotedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(promotedBannersProvider);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context);

    return bannersAsync.when(
      skipLoadingOnRefresh: false,
      // ✅ Skeletonizer — يرسم skeleton بنفس شكل الـ widget الحقيقي
      loading: () => _buildSkeleton(theme),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        final banner = banners.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: GestureDetector(
            onTap: banner.placeId != null
                ? () => context.pushNamed(
                    RouteNames.placeDetails,
                    queryParameters: {'placeId': banner.placeId!},
                  )
                : null,
            child: SizedBox(
              height: 82,

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
                            Container(color: AppColors.success),
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
                                Text(
                                  isAr
                                      ? (banner.placeNameAr ?? '')
                                      : (banner.placeNameEn ?? ''),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (banner.placeArea != null)
                                  Text(
                                    banner.placeArea!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.white.withValues(
                                        alpha: 0.8,
                                      ),
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
          ),
        );
      },
    );
  }
}

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
    child: SizedBox(
      height: 82,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // ── Full banner pulse ────────────────────────────
          Bone(
            height: 82,
            width: double.infinity,
            borderRadius: BorderRadius.circular(18),
          ),
          // ── Content overlaid on top ──────────────────────
          Row(
            children: [
              Bone(
                width: 30,
                height: 30,
                borderRadius: BorderRadius.circular(6),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Gap(20),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
