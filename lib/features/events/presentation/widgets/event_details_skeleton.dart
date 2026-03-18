// lib/features/events/presentation/widgets/event_details_skeleton.dart
//
// Loading skeleton for EventDetailsPage.
// Mirrors PlaceDetailsSkeleton exactly — same image height, same section ordering,
// with extra bones for the date chip and ticket row unique to events.

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EventDetailsSkeleton extends StatelessWidget {
  const EventDetailsSkeleton({super.key});

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
            // ── Cover image ───────────────────────────────────────────────
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
                  // ── Title row ──────────────────────────────────────────
                  Row(
                    children: [
                      Bone(
                        width: 200,
                        height: 26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 14),
                      Bone.circle(size: 24),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Location chip ──────────────────────────────────────
                  Bone(
                    width: 160,
                    height: 38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 10),

                  // ── Date chip (event-specific) ─────────────────────────
                  Bone(
                    width: 220,
                    height: 38,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats row ──────────────────────────────────────────
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

                  // ── Ticket row (event-specific) ────────────────────────
                  Row(
                    children: [
                      Bone(
                        width: 100,
                        height: 40,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      const SizedBox(width: 10),
                      Bone(
                        width: 130,
                        height: 40,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── About section label ────────────────────────────────
                  Bone(
                    width: 80,
                    height: 16,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 10),

                  // ── Description lines ──────────────────────────────────
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
                  const SizedBox(height: 28),

                  // ── CTA button ─────────────────────────────────────────
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