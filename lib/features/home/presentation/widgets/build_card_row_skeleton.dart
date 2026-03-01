import 'package:flutter/material.dart';
import 'package:future_riverpod/features/home/presentation/pages/home_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BuildCardRowSkeleton extends StatelessWidget {
  const BuildCardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
    enabled: true,
    effect: const ShimmerEffect(baseColor: kSurface2, highlightColor: kBorder),
    child: SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) => Container(
          width: 170,
          decoration: BoxDecoration(
            color: kSurface2,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة
              Container(
                height: 112,
                width: 170,
                decoration: const BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              // badge
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Container(
                  width: 50,
                  height: 16,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(height: 13, width: 130, color: kBorder),
              ),
              const SizedBox(height: 6),
              // subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(height: 10, width: 80, color: kBorder),
              ),
            ],
          ),
        ),
      ),
    ),);
  }
}
