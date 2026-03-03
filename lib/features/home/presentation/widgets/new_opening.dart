import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_card_row_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_error_widget.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_card.dart';

class NewOpening extends ConsumerWidget {
  const NewOpening({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newOpeningsAsync = ref.watch(newOpeningsProvider);
    return newOpeningsAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => BuildCardRowSkeleton(),
      error: (e, _) => buildErrorWidget(e.toString()),
      data: (places) => SizedBox(
        height: 210,
        child: ListView.separated(
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: places.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final place = places[i];
            return FeedCard(
              coverImageUrl: place.coverImageUrl,
              titleEn: place.nameEn,
              titleAr: place.nameAr,
              subtitleEn: place.area,
              subtitleAr: place.area,
              badge: FeedCardBadge.newOpening,
              isVerified: place.isVerified, // 👈
              onTap: () {
                /* TODO: Navigate */
              },
            );
          },
        ),
      ),
    );
  }
}
