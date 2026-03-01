import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_card_row_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_error_widget.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_card.dart';
import 'package:future_riverpod/features/places/domain/models/trending_feed_item_model.dart';

class TrendingFeed extends ConsumerStatefulWidget {
  const TrendingFeed({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TrendingFeedState();
}

class _TrendingFeedState extends ConsumerState<TrendingFeed> {
  bool get isAr => ref.watch(appLocaleProvider) is ArabicLocale;
  String get trendingBadge => isAr ? '🔥 رائج' : '🔥 Hot';
  String get eventBadge => isAr ? '🎉 حدث' : '🎉 Event';
  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingFeedProvider);

    return trendingAsync.when(
      loading: () => BuildCardRowSkeleton(),
      error: (e, _) => buildErrorWidget(e.toString()),
      data: (items) => SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final item = items[i];
            return FeedCard(
              coverImageUrl: item.coverImageUrl,
              titleEn: item.titleEn,
              titleAr: item.titleAr,
              subtitleEn: item.subtitleEn,
              subtitleAr: item.subtitleAr,
              badge: item.isEvent
                  ? FeedCardBadge.event
                  : FeedCardBadge.trending,
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
