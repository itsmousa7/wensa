import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/home/presentation/widgets/wensa_badge.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FullWidthFeedCard extends ConsumerWidget {
  const FullWidthFeedCard({
    super.key,
    required this.item,
    this.badge,
    this.onTap,
  });

  final CategoryFeedItem item;
  final WensaBadgeType? badge; // null = no badge shown
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final cs = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);
    final isFav =
        ref.watch(favoritesProvider).value?.contains(item.id) ?? false;

    return GestureDetector(
      onDoubleTap: () => ref
          .read(favoritesProvider.notifier)
          .toggle(item.id, itemType: item.type),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // ✅ Explicit card background — visible in both light & dark mode
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image 200px ────────────────────────────────────────────────
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  item.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              ColoredBox(color: cs.surfaceContainerHighest),
                          errorWidget: (_, __, ___) =>
                              ColoredBox(color: cs.surfaceContainerHighest),
                        )
                      : ColoredBox(color: cs.surfaceContainerHighest),

                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),

                  // Badge — start corner
                  Positioned(
                    top: 10,
                    left: isAr ? null : 10,
                    right: isAr ? 10 : null,
                    child: badge != null
                        ? WensaBadge(type: badge!, isAr: isAr)
                        : const SizedBox.shrink(),
                  ),

                  // Heart — end corner
                  Positioned(
                    top: 8,
                    right: isAr ? null : 10,
                    left: isAr ? 10 : null,
                    child: _HeartButton(
                      itemId: item.id,
                      itemType: item.type,
                      isFavorited: isFav,
                    ),
                  ),
                ],
              ),
            ),

            // ── Text area — inside the same Container ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + verify badge inline
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isAr ? item.titleAr : item.titleEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(color: cs.onSurface),
                        ),
                      ),
                      if (item.isVerified) ...[
                        const Gap(6),
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: Image.asset('assets/icons/verify.png'),
                        ),
                      ],
                    ],
                  ),

                  // Subtitle (area / location)
                  if ((isAr ? item.subtitleAr : item.subtitleEn) != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        SizedBox(
                          height: 10,
                          child: Image.asset('assets/icons/location.png'),
                        ),
                        const Gap(4),
                        Text(
                          isAr ? item.subtitleAr! : item.subtitleEn!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  buildFullWidthSkeleton — matches card structure exactly
// ─────────────────────────────────────────────────────────────────────────────
Widget buildFullWidthSkeleton(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Skeletonizer(
    enabled: true,
    effect: ShimmerEffect(
      baseColor: cs.surfaceContainer,
      highlightColor: cs.surfaceContainerHighest,
      duration: const Duration(milliseconds: 1200),
    ),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image placeholder
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: cs.surfaceContainerHighest),
                // Badge pill
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 90,
                    height: 26,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Heart circle
                Positioned(
                  top: 8,
                  right: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Text placeholder
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + verify
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 150,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      height: 16,
                      width: 16,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(4),
                    Container(
                      height: 10,
                      width: 90,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
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

// ─────────────────────────────────────────────────────────────────────────────
//  _HeartButton
// ─────────────────────────────────────────────────────────────────────────────
class _HeartButton extends ConsumerStatefulWidget {
  const _HeartButton({
    required this.itemId,
    required this.itemType,
    required this.isFavorited,
  });
  final String itemId;
  final String itemType;
  final bool isFavorited;

  @override
  ConsumerState<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends ConsumerState<_HeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    ref
        .read(favoritesProvider.notifier)
        .toggle(widget.itemId, itemType: widget.itemType);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _tap,
    child: ScaleTransition(
      scale: _scale,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.isFavorited
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          size: 17,
          color: widget.isFavorited ? Colors.red.shade400 : Colors.white,
        ),
      ),
    ),
  );
}
