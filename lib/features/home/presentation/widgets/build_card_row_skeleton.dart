import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BuildCardRowSkeleton extends StatelessWidget {
  const BuildCardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: theme.surfaceContainer,
        highlightColor: theme.surfaceContainerHighest,
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
                // Image — fully rounded to match ClipRRect(radius: 20)
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                // Text area
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + badge row
                      Row(
                        children: [
                          Container(
                            height: 13,
                            width: 130,
                            decoration: BoxDecoration(
                              color: theme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 20,
                            width: 52,
                            decoration: BoxDecoration(
                              color: theme.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Container(
                        height: 10,
                        width: 90,
                        decoration: BoxDecoration(
                          color: theme.surfaceContainer,
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
