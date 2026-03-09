import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/home_providers.dart';
import 'package:future_riverpod/features/home/presentation/widgets/build_card_row_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/widgets/feed_card.dart';
import 'package:future_riverpod/features/home/presentation/widgets/view_all_card.dart';

class NewOpeningSection extends ConsumerWidget {
  const NewOpeningSection({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final newOpeningAsync = ref.watch(newOpeningsProvider);

    return newOpeningAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => const BuildCardRowSkeleton(),
      // ✅ Silent fail — home_page shows the centered error instead
      error: (_, __) => const SizedBox.shrink(),
      data: (items) => SizedBox(
        height: 210,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: items.length + (onViewAll != null ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            if (onViewAll != null && i == items.length) {
              return ViewAllCard(isAr: isAr, onTap: onViewAll!);
            }
            final item = items[i];
            return FeedCard(
              placeId: item.id,
              coverImageUrl: item.coverImageUrl,
              titleEn: item.nameEn,
              titleAr: item.nameAr,
              subtitleEn: item.area,
              subtitleAr: item.area,
              badge: FeedCardBadge.newOpening, // ✅ WensaBadge
              isVerified: item.isVerified,
              itemType: 'place',
            );
          },
        ),
      ),
    );
  }
}
