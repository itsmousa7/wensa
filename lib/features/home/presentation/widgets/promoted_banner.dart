import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/home/presentation/pages/home_page.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PromotedBanner extends ConsumerWidget {
  const PromotedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(promotedBannersProvider);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context);

    return bannersAsync.when(
      // ✅ Skeletonizer — يرسم skeleton بنفس شكل الـ widget الحقيقي
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
        child: Skeletonizer(
          enabled: true,
          effect: ShimmerEffect(
            baseColor: theme.colorScheme.surfaceContainer,
            highlightColor: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Container(
            height: 82,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 160,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 70,
                  height: 30,
                  margin: const EdgeInsets.only(right: 18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        final banner = banners.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: GestureDetector(
            onTap: () {},
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
                        errorWidget: (_, _, _) => Container(color: kSurface2),
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
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                if (banner.placeArea != null)
                                  Text(
                                    banner.placeArea!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAr ? 'استكشف' : 'Explore',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.surface,
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
          ),
        );
      },
    );
  }
}
