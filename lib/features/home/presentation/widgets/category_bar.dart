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
    // ✅ BUG 1 FIX: int? — null يعني لا فئة مختارة
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
            // ✅ BUG 1 FIX: null-safe — لو selectedIndex = null كل الفئات inactive
            final isActive = selectedIndex == i;
            final cat = cats[i];

            return GestureDetector(
              onTap: () {
                // نفس الفئة مرة ثانية → deselect (يرجع null)
                ref.read(selectedCategoryProvider.notifier).select(i);
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      // ✅ BUG 5: theme colors
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
                    child: Center(child: _categoryIcon(cat.nameEn)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? cat.nameAr : cat.nameEn,
                    // ✅ BUG 5: AppTypography
                    style: tt.labelLarge?.copyWith(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

// ─── CategoryBar._buildSkeleton ──────────────────────────────────────────────
// FIX: ListView inside Skeletonizer must use NeverScrollableScrollPhysics.
//      Without it the scrollable viewport creates its own layer and the shimmer
//      can't paint over it — exactly what HotEventsSection already does correctly.

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
  switch (nameEn) {
    case 'Sports':
      return Lottie.asset(
        'assets/lottie/categories/gym.json',
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        repeat: true,
      );

    case 'Restaurants':
      return Lottie.asset(
        'assets/lottie/categories/food.json',
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        repeat: true,
      );

    case 'Music':
      return Lottie.asset(
        'assets/lottie/categories/music.json',
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        repeat: true,
      );

    case 'Malls':
      return Lottie.asset(
        'assets/lottie/categories/mall.json',
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        repeat: true,
      );

    case 'Cafes':
      return Lottie.asset(
        'assets/lottie/categories/cafe.json',
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        repeat: true,
      );

    case 'Cinema':
      return Lottie.asset(
        'assets/lottie/categories/movie.json',
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        repeat: true,
      );

    case 'Festivals':
      return Lottie.asset(
        'assets/lottie/categories/festival.json',
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        repeat: true,
      );

    default:
      return const Icon(CupertinoIcons.location);
  }
}
