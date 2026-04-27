import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/models/promoted_banner.dart';
import 'package:future_riverpod/features/home/models/trending_feed_item_model.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_card_row_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_card.dart';
import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';
import 'package:future_riverpod/features/home/presentation/widgets/view_all_card.dart';

class FeaturedSection extends ConsumerWidget {
  const FeaturedSection({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final featuredAsync = ref.watch(featuredFeedProvider);
    final banners =
        ref.watch(promotedBannersProvider).value ?? const <PromotedBannerModel>[];

    return featuredAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => const BuildCardRowSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final n = items.length;
        final hasBanners = banners.isNotEmpty;
        final bannerCount = hasBanners ? n ~/ 5 : 0;
        final viewAllCount = onViewAll != null ? 1 : 0;
        final totalCount = n + bannerCount + viewAllCount;

        return SizedBox(
          height: 210,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: totalCount,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              if (onViewAll != null && i == totalCount - 1) {
                return ViewAllCard(isAr: isAr, onTap: onViewAll!);
              }

              if (hasBanners) {
                final group = i ~/ 6;
                final pos = i % 6;
                if (pos == 5 && group < bannerCount) {
                  return PromotedBannerCardInline(slotIndex: group);
                }
                final idx = group * 5 + pos;
                if (idx >= n) return const SizedBox.shrink();
                final item = items[idx];
                return _feedCard(item);
              }

              return _feedCard(items[i]);
            },
          ),
        );
      },
    );
  }

  Widget _feedCard(TrendingFeedItemModel item) => FeedCard(
        placeId: item.id,
        coverImageUrl: item.coverImageUrl,
        logoUrl: item.logoUrl,
        titleEn: item.titleEn,
        titleAr: item.titleAr,
        subtitleEn: item.subtitleEn,
        subtitleAr: item.subtitleAr,
        badge: item.isEvent ? FeedCardBadge.event : FeedCardBadge.featured,
        isVerified: item.isVerified,
        itemType: item.isEvent ? 'event' : 'place',
      );
}
