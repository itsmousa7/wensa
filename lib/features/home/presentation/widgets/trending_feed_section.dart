import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_card_row_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_error_widget.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_card.dart';
import 'package:future_riverpod/features/home/presentation/widgets/view_all_card.dart';
import 'package:future_riverpod/features/places/domain/models/trending_feed_item_model.dart';

class TrendingFeedSection extends ConsumerStatefulWidget {
  const TrendingFeedSection({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  ConsumerState<TrendingFeedSection> createState() =>
      _TrendingFeedSectionState();
}

class _TrendingFeedSectionState extends ConsumerState<TrendingFeedSection> {
  bool get isAr => ref.watch(appLocaleProvider) is ArabicLocale;

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingFeedProvider);

    return trendingAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => const BuildCardRowSkeleton(),
      error: (e, _) => buildErrorWidget(e.toString()),
      data: (items) => SizedBox(
        height: 210,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: items.length + (widget.onViewAll != null ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            if (widget.onViewAll != null && i == items.length) {
              return ViewAllCard(isAr: isAr, onTap: widget.onViewAll!);
            }
            final item = items[i];
            return FeedCard(
              placeId: item.id,
              coverImageUrl: item.coverImageUrl,
              titleEn: item.titleEn,
              titleAr: item.titleAr,
              subtitleEn: item.subtitleEn,
              subtitleAr: item.subtitleAr,
              badge: item.isEvent
                  ? FeedCardBadge.event
                  : FeedCardBadge.trending,
              itemType: item.isEvent ? 'event' : 'place',
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
