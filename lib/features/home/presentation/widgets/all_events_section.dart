import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/home/presentation/providers/all_events_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_card_row_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_error_widget.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_card.dart';
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

    return eventsAsync.when(
      skipLoadingOnRefresh: false,

      loading: () => const BuildCardRowSkeleton(),
      error: (e, _) => buildErrorWidget(e.toString()),
      data: (allItems) {
        final items = allItems.take(_maxInlineItems).toList();

        if (items.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                isAr ? 'لا توجد أحداث حالياً' : 'No events right now',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 210,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              if (i == items.length) {
                return ViewAllCard(isAr: isAr, onTap: onViewAll);
              }
              final event = items[i];
              return FeedCard(
                placeId: event.id,
                coverImageUrl: event.coverImageUrl,
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
            },
          ),
        );
      },
    );
  }
}
