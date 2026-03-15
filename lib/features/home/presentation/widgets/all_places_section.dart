import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_list_section.dart';

class AllPlacesSection extends ConsumerWidget {
  const AllPlacesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(allPlacesFeedProvider);

    return FeedListSection(
      feed: feed,
      onLoadMore: () => ref.read(allPlacesFeedProvider.notifier).loadMore(),
      emptyTitleEn: 'No places yet',
      emptyTitleAr: 'لا توجد أماكن حالياً',
    );
  }
}

class SeeAllSection extends ConsumerWidget {
  const SeeAllSection({super.key, required this.type});

  final SeeAllType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(seeAllFeedProvider(type));

    return FeedListSection(
      feed: feed,
      onLoadMore: () => ref.read(seeAllFeedProvider(type).notifier).loadMore(),
      emptyTitleEn: type == SeeAllType.trending
          ? 'Nothing trending right now'
          : 'No new openings yet',
      emptyTitleAr: type == SeeAllType.trending
          ? 'لا يوجد شيء رائج الآن'
          : 'لا توجد افتتاحات جديدة',
    );
  }
}
