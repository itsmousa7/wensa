import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CategoryBar extends ConsumerStatefulWidget {
  const CategoryBar({super.key, required this.isAr});
  final bool isAr;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CategoryBarState();
}

class _CategoryBarState extends ConsumerState<CategoryBar> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedIndex = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context).colorScheme;
    return categoriesAsync.when(
      loading: () => Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor: theme.surfaceContainer,
          highlightColor: theme.surfaceContainerHighest,
        ),
        child: SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 48, height: 10, color: theme.surfaceContainer),
              ],
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (cats) => SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: cats.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final isActive = i == selectedIndex;
            final cat = cats[i];
            return GestureDetector(
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).select(i),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.primary.withValues(alpha: 0.6)
                          : theme.onPrimaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? theme.primary.withValues(alpha: 0.4)
                            : theme.surfaceContainerHighest.withValues(
                                alpha: 0.4,
                              ),
                        width: 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: theme.primary.withValues(alpha: 0.3),
                                blurRadius: 14,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        _categoryEmoji(cat.nameEn),
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isAr ? cat.nameAr : cat.nameEn,
                    style: TextStyle(
                      color: isActive
                          ? theme.outline
                          : theme.surfaceContainerLowest,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

String _categoryEmoji(String nameEn) {
  const map = {
    'Restaurants': '🍽️',
    'Music': '🎵',
    'Malls': '🛍️',
    'Cafes': '☕',
    'Cinema': '🎬',
    'Festivals': '🎪',
    'Sports': '🏋️',
  };
  return map[nameEn] ?? '📍';
}
