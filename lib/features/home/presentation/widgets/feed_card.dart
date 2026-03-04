import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/new_opening_badge.dart';
import 'package:gap/gap.dart';

enum FeedCardBadge { trending, event, newOpening }

const kOrange = Color(0xFFFF5E2C);
const kText3 = Color(0xFF5A5A72);

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
    this.onTap,
  });

  final String placeId;
  final String? coverImageUrl;
  final String titleEn;
  final String titleAr;
  final String? subtitleEn;
  final String? subtitleAr;
  final FeedCardBadge badge;
  final bool isVerified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final theme = Theme.of(context).colorScheme;
    final isFav =
        ref.watch(favoritesProvider).value?.contains(placeId) ?? false;

    final (badgeColor, badgeText) = switch (badge) {
      FeedCardBadge.trending => (
        AppColors.darkRedSecondary,
        isAr ? '🔥 رائج' : '🔥 Hot',
      ),
      FeedCardBadge.event => (
        const Color(0xFF3E3E9B),
        isAr ? '🎉 حدث' : '🎉 Event',
      ),
      FeedCardBadge.newOpening => (
        theme.primary,
        isAr ? 'افتتح مؤخراً' : 'Just Opened',
      ),
    };

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () => ref.read(favoritesProvider.notifier).toggle(placeId),
      child: Container(
        width: 250,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ───────────────────────────────────────────────────
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
                            placeholder: (_, __) =>
                                Container(color: theme.surfaceContainer),
                            errorWidget: (_, __, ___) =>
                                Container(color: theme.surfaceContainer),
                          )
                        : Container(color: theme.surfaceContainer),
                  ),
                ),

                // ✅ Badge (start) + Heart (end) — same row with spacer
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

                // ✅ Heart — opposite corner
                Positioned(
                  top: 7,
                  right: isAr ? null : 8,
                  left: isAr ? 8 : null,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(favoritesProvider.notifier).toggle(placeId),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 14,
                        color: isFav ? Colors.red.shade400 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Text area ───────────────────────────────────────────────
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
                          style: TextStyle(
                            color: theme.outline,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
                        height: 9,
                        child: Image.asset('assets/icons/location.png'),
                      ),
                      const Gap(4),
                      Text(
                        (isAr ? subtitleAr : subtitleEn) ?? '',
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.onSurface.withValues(alpha: 0.8),
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
