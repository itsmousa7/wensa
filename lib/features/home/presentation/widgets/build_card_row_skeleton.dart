import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BuildCardRowSkeleton extends StatelessWidget {
  const BuildCardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: theme.colorScheme.surfaceContainer,
        highlightColor: theme.colorScheme.surfaceContainerHighest,
        duration: const Duration(milliseconds: 1200),
      ),
      child: SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image: height 130, borderRadius 20 ──────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                // ── Text block: matches padding fromLTRB(12,10,12,12) ─
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title ~h13 + badge 52×20
                      Row(
                        children: [
                          Container(
                            height: 13,
                            width: 130,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 20,
                            width: 52,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Subtitle ~h10
                      Container(
                        height: 10,
                        width: 90,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
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
  }
}
