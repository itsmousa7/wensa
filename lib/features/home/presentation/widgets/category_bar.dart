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
          itemCount: cats.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            // ── Synthetic "Discounts" chip (sentinel index -1) ──────────
            if (i == 0) {
              final isActive = selectedIndex == -1;
              return GestureDetector(
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).select(-1);
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
                      // Reuses _categoryIcon, which maps 'Discounts' →
                      // assets/lottie/categories/discount.lottie.
                      child: Center(
                        child: _categoryIcon('Discounts'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr ? 'خصومات' : 'Discounts',
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
            }

            // ── Real DB category (offset by 1) ──────────────────────────
            final catIndex = i - 1;
            final isActive = selectedIndex == catIndex;
            final cat = cats[catIndex];

            return GestureDetector(
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).select(catIndex);
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
                    child: Center(
                      child: _categoryIcon(cat.nameEn),
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

Widget _categoryIcon(String nameEn) {
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
    case 'Discounts':
      asset = 'assets/lottie/categories/discount.lottie';
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
    repeat: true,
    animate: true,
    frameRate: FrameRate.max,
  );
}
