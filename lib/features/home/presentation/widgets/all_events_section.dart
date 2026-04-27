import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:future_riverpod/features/home/models/promoted_banner.dart';
import 'package:future_riverpod/features/home/presentation/providers/all_events_provider.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_card_row_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_error_widget.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_card.dart';
import 'package:future_riverpod/features/home/presentation/widgets/promoted_banner.dart';
import 'package:future_riverpod/features/home/presentation/widgets/view_all_card.dart';
import 'package:go_router/go_router.dart';

class AllEventsSection extends ConsumerWidget {
  const AllEventsSection({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  static const int _maxInlineItems = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final eventsAsync = ref.watch(allEventsProvider);
    final banners =
        ref.watch(promotedBannersProvider).value ?? const <PromotedBannerModel>[];

    return eventsAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => const BuildCardRowSkeleton(),
      error: (e, _) => buildErrorWidget(e.toString()),
      data: (allItems) {
        final items = allItems.take(_maxInlineItems).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        final n = items.length;
        final hasBanners = banners.isNotEmpty;
        final bannerCount = hasBanners ? n ~/ 5 : 0;
        // +1 for the ViewAll card
        final totalCount = n + bannerCount + 1;

        return SizedBox(
          height: 210,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: totalCount,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              // ViewAll is the last slot
              if (i == totalCount - 1) {
                return ViewAllCard(isAr: isAr, onTap: onViewAll);
              }

              if (hasBanners) {
                final group = i ~/ 6;
                final pos = i % 6;
                if (pos == 5 && group < bannerCount) {
                  return PromotedBannerCardInline(slotIndex: group);
                }
                final idx = group * 5 + pos;
                if (idx >= n) return const SizedBox.shrink();
                return _eventCard(context, items[idx]);
              }

              return _eventCard(context, items[i]);
            },
          ),
        );
      },
    );
  }

  Widget _eventCard(BuildContext context, EventModel event) => FeedCard(
        placeId: event.id,
        coverImageUrl: event.coverImageUrl,
        logoUrl: event.logoUrl,
        titleEn: event.titleEn,
        titleAr: event.titleAr,
        subtitleEn: event.city,
        subtitleAr: event.city,
        badge: FeedCardBadge.event,
        itemType: 'event',
        onTap: () => context.pushNamed(
          RouteNames.eventDetails,
          queryParameters: {'eventId': event.id},
        ),
      );
}
