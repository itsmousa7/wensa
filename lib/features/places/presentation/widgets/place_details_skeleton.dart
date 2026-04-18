import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PlaceDetailsSkeleton extends StatelessWidget {
  const PlaceDetailsSkeleton({super.key});

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
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone(
              width: double.infinity,
              height: 380,
              borderRadius: BorderRadius.zero,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo + Name + Location (ListTile-style) ──────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Bone(
                        width: 67,
                        height: 67,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Bone(
                                  width: 160,
                                  height: 22,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                const SizedBox(width: 10),
                                Bone(
                                  width: 20,
                                  height: 20,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Bone(
                              width: 130,
                              height: 30,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Bone(
                        width: 90,
                        height: 52,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(width: 10),
                      Bone(
                        width: 90,
                        height: 52,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(width: 10),
                      Bone(
                        width: 90,
                        height: 52,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Bone(
                    width: 120,
                    height: 16,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Bone(
                        width: 72,
                        height: 30,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      Bone(
                        width: 56,
                        height: 30,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      Bone(
                        width: 88,
                        height: 30,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Bone(
                    width: 80,
                    height: 16,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 10),

                  Bone(
                    width: double.infinity,
                    height: 13,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                  Bone(
                    width: double.infinity,
                    height: 13,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                  Bone(
                    width: 220,
                    height: 13,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 24),

                  Bone(
                    width: 120,
                    height: 16,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  Bone(
                    width: double.infinity,
                    height: 48,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(height: 24),

                  Bone(
                    width: 80,
                    height: 16,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Bone(
                        width: 140,
                        height: 48,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      const SizedBox(width: 12),
                      Bone(
                        width: 140,
                        height: 48,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Bone(
                    width: double.infinity,
                    height: 54,
                    borderRadius: BorderRadius.circular(18),
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
