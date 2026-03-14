// lib/features/profile/presentation/widgets/profile_skeleton.dart

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: cs.surfaceContainer,
        highlightColor: cs.surfaceContainerHighest,
        duration: const Duration(milliseconds: 1200),
        begin: Alignment.centerRight, // ← right-to-left sweep
        end: Alignment.centerLeft,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header area (avatar + name + email) ─────────────────────────
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 32,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar circle with ring
                    Bone.circle(size: 120),
                    const SizedBox(height: 16),

                    // Full name
                    Bone(
                      width: 160,
                      height: 20,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),

                    // Email
                    Bone(
                      width: 210,
                      height: 14,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Stats row (2 chips) ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Liked chip
                      Bone(
                        width: 120,
                        height: 64,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(width: 12),
                      // Reviews chip
                      Bone(
                        width: 120,
                        height: 64,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── "Appearance" section label ─────────────────────────────
                  _SectionLabelBone(),
                  const SizedBox(height: 10),

                  // ── Dark Mode settings card (1 row) ────────────────────────
                  Bone(
                    width: double.infinity,
                    height: 60,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  const SizedBox(height: 16),

                  // ── "Language" section label ───────────────────────────────
                  _SectionLabelBone(),
                  const SizedBox(height: 10),

                  // ── Arabic toggle card (1 row) ─────────────────────────────
                  Bone(
                    width: double.infinity,
                    height: 60,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  const SizedBox(height: 16),

                  // ── "Account" section label ────────────────────────────────
                  _SectionLabelBone(),
                  const SizedBox(height: 10),

                  // ── Account card (2 rows: Change Name + Change Password) ───
                  Bone(
                    width: double.infinity,
                    height: 112, // ~56px per row × 2
                    borderRadius: BorderRadius.circular(18),
                  ),
                  const SizedBox(height: 28),

                  // ── Sign Out button ────────────────────────────────────────
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

// ── Section label bone (vertical bar + text) ──────────────────────────────────

class _SectionLabelBone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The coloured vertical bar
        Bone(width: 3, height: 16, borderRadius: BorderRadius.circular(2)),
        const SizedBox(width: 8),
        // The label text
        Bone(width: 90, height: 14, borderRadius: BorderRadius.circular(6)),
      ],
    );
  }
}
