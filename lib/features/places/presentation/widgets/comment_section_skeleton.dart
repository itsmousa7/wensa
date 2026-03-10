import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ReviewsSkeleton extends StatelessWidget {
  const ReviewsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: cs.surfaceContainer,
        highlightColor: cs.surfaceContainerHighest,
        duration: const Duration(milliseconds: 1200),
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone.circle(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Bone(
                        width: 120,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const Spacer(),
                      Bone(
                        width: 60,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Bone(
                    width: double.infinity,
                    height: 10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                  Bone(
                    width: 180,
                    height: 10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                  Bone(
                    width: 60,
                    height: 8,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
