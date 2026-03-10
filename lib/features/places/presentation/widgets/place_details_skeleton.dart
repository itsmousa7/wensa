// lib/features/places/presentation/widgets/place_details/place_details_skeleton.dart
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PlaceDetailsSkeleton extends StatelessWidget {
  const PlaceDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: cs.surfaceContainer,
        highlightColor: cs.surfaceContainerHighest,
        duration: const Duration(milliseconds: 1200),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ──────────────────────────────────────────────────
            _Bone(width: double.infinity, height: 380, radius: 0),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + verified badge ──────────────────────────────
                  Row(
                    children: [
                      _Bone(width: 200, height: 26),
                      const Spacer(),
                      _Bone(width: 24, height: 24, isCircle: true),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Location chip ──────────────────────────────────────
                  _Bone(width: 160, height: 38, radius: 12),
                  const SizedBox(height: 16),

                  // ── Stats row (3 chips) ────────────────────────────────
                  Row(
                    children: [
                      _Bone(width: 90, height: 52, radius: 12),
                      const SizedBox(width: 10),
                      _Bone(width: 90, height: 52, radius: 12),
                      const SizedBox(width: 10),
                      _Bone(width: 90, height: 52, radius: 12),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Price range ────────────────────────────────────────
                  _Bone(width: 120, height: 16, radius: 6),
                  const SizedBox(height: 16),

                  // ── Tags ───────────────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Bone(width: 72, height: 30, radius: 20),
                      _Bone(width: 56, height: 30, radius: 20),
                      _Bone(width: 88, height: 30, radius: 20),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── "About" section header ─────────────────────────────
                  _Bone(width: 80, height: 16, radius: 6),
                  const SizedBox(height: 10),

                  // ── Description lines ──────────────────────────────────
                  _Bone(width: double.infinity, height: 13, radius: 6),
                  const SizedBox(height: 6),
                  _Bone(width: double.infinity, height: 13, radius: 6),
                  const SizedBox(height: 6),
                  _Bone(width: 220, height: 13, radius: 6),
                  const SizedBox(height: 24),

                  // ── "Opening hours" section header ─────────────────────
                  _Bone(width: 120, height: 16, radius: 6),
                  const SizedBox(height: 12),
                  _Bone(width: double.infinity, height: 48, radius: 14),
                  const SizedBox(height: 24),

                  // ── "Contact" section header ───────────────────────────
                  _Bone(width: 80, height: 16, radius: 6),
                  const SizedBox(height: 12),

                  // ── Contact buttons row ────────────────────────────────
                  Row(
                    children: [
                      _Bone(width: 140, height: 48, radius: 14),
                      const SizedBox(width: 12),
                      _Bone(width: 140, height: 48, radius: 14),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Reviews CTA button ─────────────────────────────────
                  _Bone(width: double.infinity, height: 54, radius: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal bone widget ──────────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    this.radius = 8,
    this.isCircle = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainer, // ← was surfaceContainerHighest
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}
