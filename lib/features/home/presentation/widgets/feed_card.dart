import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/home/presentation/widgets/new_opening_badge.dart';
import 'package:gap/gap.dart';

enum FeedCardBadge { trending, event, newOpening }

// Color token used by home_page
const kOrange = Color(0xFFFF5E2C);
const kText3 = Color(0xFF5A5A72);

class FeedCard extends ConsumerWidget {
  const FeedCard({
    super.key,
    required this.coverImageUrl,
    required this.titleEn,
    required this.titleAr,
    this.subtitleEn,
    this.subtitleAr,
    this.badge = FeedCardBadge.trending,
    this.isVerified = false,
    this.onTap,
  });

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
      child: Container(
        width: 250,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Image + badge overlay ─────────────────────────────────
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

                // ✅ كل الـ badges في نفس المكان — top-start corner على الصورة
                Positioned(
                  top: 9,
                  left: isAr ? null : 9,
                  right: isAr ? 9 : null,
                  child: feedBadge(
                    isAr: isAr,
                    context: context,
                    color: badgeColor, // ← اللون حسب النوع
                    text: badgeText, // ← النص حسب النوع
                  ),
                ),
              ],
            ),

            // ─── Text area ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Title + verify badge بجانب بعض
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
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
                      // ✅ verify badge بجانب الاسم مباشرة
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
                      Gap(4),
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
