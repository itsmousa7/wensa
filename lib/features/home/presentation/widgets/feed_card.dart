import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/new_opening_badge.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

enum FeedCardBadge { trending, event, newOpening }

class FeedCard extends ConsumerWidget {
  const FeedCard({
    super.key,
    required this.coverImageUrl,
    required this.titleEn,
    required this.titleAr,
    required this.placeId,
    this.subtitleEn,
    this.subtitleAr,
    this.badge = FeedCardBadge.trending,
    this.isVerified = false,
    this.itemType = 'place', // ✅ NEW — 'place' | 'event'
    this.onTap,
  });

  final String placeId; // holds the item ID regardless of type
  final String? coverImageUrl;
  final String titleEn;
  final String titleAr;
  final String? subtitleEn;
  final String? subtitleAr;
  final FeedCardBadge badge;
  final bool isVerified;
  final String itemType; // ✅ NEW
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context);
    final isFav =
        ref.watch(favoritesProvider).value?.contains(placeId) ?? false;

    final (badgeColor, badgeText) = switch (badge) {
      FeedCardBadge.trending => (
        AppColors.darkRedSecondary,
        isAr ? '🔥 رائج' : '🔥 Hot',
      ),
      FeedCardBadge.event => (
        AppColors.headline2,
        isAr ? '🎉 حدث' : '🎉 Event',
      ),
      FeedCardBadge.newOpening => (
        theme.colorScheme.primary,
        isAr ? 'افتتح مؤخراً' : 'Just Opened',
      ),
    };

    return GestureDetector(
      onTap:
          onTap ??
          (itemType == 'place'
              ? () => context.pushNamed(
                  RouteNames.placeDetails,
                  queryParameters: {'placeId': placeId},
                )
              : null),
      onDoubleTap: () => ref
          .read(favoritesProvider.notifier)
          .toggle(placeId, itemType: itemType),
      child: Container(
        width: 250,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: theme.colorScheme.surfaceContainer,
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: theme.colorScheme.surfaceContainer,
                            ),
                          )
                        : Container(color: theme.colorScheme.surfaceContainer),
                  ),
                ),

                // Badge
                Positioned(
                  top: 8,
                  left: isAr ? null : 8,
                  right: isAr ? 8 : null,
                  child: feedBadge(
                    isAr: isAr,
                    context: context,
                    color: badgeColor,
                    text: badgeText,
                  ),
                ),

                // Heart
                Positioned(
                  top: 7,
                  right: isAr ? null : 8,
                  left: isAr ? 8 : null,
                  child: GestureDetector(
                    // ✅ Pass itemType here too
                    onTap: () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(placeId, itemType: itemType),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 14,
                        color: isFav ? AppColors.alert : AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Text area ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isAr ? titleAr : titleEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const Gap(5),
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: Image.asset('assets/icons/verify.png'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SizedBox(
                        height: 12,
                        child: itemType == 'place'
                            ? Image.asset('assets/icons/location.png')
                            : Image.asset('assets/icons/calendar.png'),
                      ),
                      const Gap(6),
                      Text(
                        (isAr ? subtitleAr : subtitleEn) ?? '',
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
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
