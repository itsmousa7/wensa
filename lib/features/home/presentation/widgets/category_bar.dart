import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CategoryBar extends ConsumerWidget {
  const CategoryBar({super.key, required this.isAr});
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedIndex = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context);
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);

    return categoriesAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => _buildSkeleton(theme),
      error: (_, _) => const SizedBox.shrink(),
      data: (cats) => SizedBox(
        height: 110,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          itemCount: cats.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final isActive = selectedIndex == i;
            final cat = cats[i];

            return GestureDetector(
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).select(i);
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.surfaceContainerHigh,
                        width: 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    // PERFORMANCE FIX: only animate the selected item.
                    // Previously every visible category ran its Lottie
                    // animation simultaneously — typically 6 animations × 30fps
                    // = a significant per-frame cost on low-end Android devices.
                    // Non-selected items show a static first frame instead.
                    child: Center(
                      child: _categoryIcon(cat.nameEn, animate: isActive),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? cat.nameAr : cat.nameEn,
                    style: tt.labelLarge?.copyWith(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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
  child: SizedBox(
    height: 110,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) => Column(
        children: [
          Bone(width: 64, height: 64, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 6),
          Bone(width: 40, height: 11, borderRadius: BorderRadius.circular(6)),
        ],
      ),
    ),
  ),
);

// PERFORMANCE FIX: added `animate` parameter.
// When animate: false the Lottie widget renders only the first frame
// (frameRate: FrameRate.max is kept on active items so they look snappy).
Widget _categoryIcon(String nameEn, {bool animate = true}) {
  String? asset;
  switch (nameEn) {
    case 'Sports':
      asset = 'assets/lottie/categories/gym.json';
      break;
    case 'Restaurants':
      asset = 'assets/lottie/categories/food.json';
      break;
    case 'Music':
      asset = 'assets/lottie/categories/music.json';
      break;
    case 'Malls':
      asset = 'assets/lottie/categories/mall.json';
      break;
    case 'Cafes':
      asset = 'assets/lottie/categories/cafe.json';
      break;
    case 'Cinema':
      asset = 'assets/lottie/categories/movie.json';
      break;
    case 'Festivals':
      asset = 'assets/lottie/categories/festival.json';
      break;
  }

  if (asset == null) {
    return const Icon(CupertinoIcons.location);
  }

  return Lottie.asset(
    asset,
    width: 42,
    height: 42,
    fit: BoxFit.contain,
    // When not selected: animate: false freezes on frame 0 with no loop.
    // FrameRate(0) is NOT valid (asserts framesPerSecond > 0) — don't use it.
    repeat: animate,
    animate: animate,
    frameRate: animate ? FrameRate.max : FrameRate.composition,
  );
}
