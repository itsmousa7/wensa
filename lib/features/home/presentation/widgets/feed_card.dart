// lib/features/home/presentation/widgets/feed_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/home/presentation/widgets/home_search_bar.dart';

enum FeedCardBadge { trending, event, newOpening }

class FeedCard extends ConsumerWidget {
  const FeedCard({
    super.key,
    required this.coverImageUrl,
    required this.titleEn,
    required this.titleAr,
    this.subtitleEn,
    this.subtitleAr,
    this.badge = FeedCardBadge.trending,
    this.isVerified = false, // 👈 new
    this.onTap,
  });

  final String? coverImageUrl;
  final String titleEn;
  final String titleAr;
  final String? subtitleEn;
  final String? subtitleAr;
  final FeedCardBadge badge;
  final bool isVerified; // 👈 new
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context).colorScheme;

    final isNewOpening = badge == FeedCardBadge.newOpening;

    // Text-area badge (only for trending / event)
    final (badgeColor, badgeText) = switch (badge) {
      FeedCardBadge.trending => (kOrange, isAr ? '🔥 رائج' : '🔥 Hot'),
      FeedCardBadge.event => (
        AppColors.headline2,
        isAr ? '🎉 حدث' : '🎉 Event',
      ),
      FeedCardBadge.newOpening => (
        AppColors.success,
        isAr ? '✦ افتتح مؤخراً' : '✦ Just Opened',
      ),
    };

    final subtitleColor = badge == FeedCardBadge.event ? kOrange : kText3;
    final justOpenedLabel = isAr ? '✦ افتتح مؤخراً' : '✦ Just Opened';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Image + overlays ──────────────────────────────────────────
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
                            placeholder: (_, _) =>
                                Container(color: theme.surfaceContainer),
                            errorWidget: (_, _, _) =>
                                Container(color: theme.surfaceContainer),
                          )
                        : Container(color: theme.surfaceContainer),
                  ),
                ),

                // "Just Opened" label — top-start corner
                if (isNewOpening)
                  Positioned(
                    top: 9,
                    left: isAr ? null : 9,
                    right: isAr ? 9 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        justOpenedLabel,
                        style: const TextStyle(
                          color: AppColors.shadegrey2,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Verified checkmark — top-end corner
                if (isVerified)
                  Positioned(
                    top: 9,
                    right: isAr ? null : 9,
                    left: isAr ? 9 : null,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '✓',
                          style: TextStyle(
                            color: AppColors.darkPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ─── Text area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 165,
                        child: Text(
                          isAr ? titleAr : titleEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.outline,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Hide text-area badge for newOpening — the image overlay handles it
                      if (!isNewOpening)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: theme.surface,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (isAr ? subtitleAr : subtitleEn) ?? '',
                    maxLines: 1,
                    style: TextStyle(color: subtitleColor, fontSize: 10),
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
