import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/places/domain/models/review_with_user_model.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_reviews_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/comment_create_date.dart';
import 'package:future_riverpod/features/places/presentation/widgets/comment_section_skeleton.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/user_avatar.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Entry-point
// ─────────────────────────────────────────────────────────────────────────────

void showReviewsSheet({
  required BuildContext context,
  required String placeId,
  required String placeName,
  required bool isAr,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (_) =>
        _ReviewsSheet(placeId: placeId, placeName: placeName, isAr: isAr),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsSheet extends ConsumerStatefulWidget {
  const _ReviewsSheet({
    required this.placeId,
    required this.placeName,
    required this.isAr,
  });

  final String placeId;
  final String placeName;
  final bool isAr;

  @override
  ConsumerState<_ReviewsSheet> createState() => _ReviewsSheetState();
}

class _ReviewsSheetState extends ConsumerState<_ReviewsSheet> {
  final _commentCtrl = TextEditingController();
  int _selectedRating = 5;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    FocusScope.of(context).unfocus();
    // Single trim — reused for both the null-check and the value
    final comment = _commentCtrl.text.trim();
    await ref
        .read(placeReviewsProvider(widget.placeId).notifier)
        .addReview(
          userId: userId,
          rating: _selectedRating,
          comment: comment.isEmpty ? null : comment,
        );
    _commentCtrl.clear();
    setState(() => _selectedRating = 5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = AppTypography.getTextTheme(widget.isAr ? 'ar' : 'en', context);
    final reviewsAsync = ref.watch(placeReviewsProvider(widget.placeId));
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isLoading = reviewsAsync.isLoading;

    final hasReviewed =
        reviewsAsync.value?.any((r) => r.review.userId == currentUserId) ??
        false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Directionality(
        textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // ── Transparent dismiss area ───────────────────────────────────
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Sheet card ─────────────────────────────────────────────────
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // ── Handle + Header ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        const _DragHandle(), // ← extracted, reusable
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              widget.isAr ? 'التقييمات' : 'Reviews',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            reviewsAsync.when(
                              data: (r) => _CountBadge(count: r.length),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),

                            if (isLoading)
                              Skeletonizer(
                                enabled: true,
                                effect: ShimmerEffect(
                                  baseColor: cs.surfaceContainer,
                                  highlightColor: cs.surfaceContainerHighest,
                                  duration: const Duration(milliseconds: 1200),
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                ),
                                child: Bone.circle(size: 20),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 20,
                    thickness: 0.5,
                    color: cs.surfaceContainerHighest,
                  ),

                  // ── Reviews list ───────────────────────────────────────
                  Expanded(
                    child: reviewsAsync.when(
                      loading: () => const ReviewsSkeleton(),
                      error: (_, _) => Center(
                        child: Text(
                          widget.isAr
                              ? 'تعذّر تحميل التقييمات'
                              : 'Could not load reviews',
                          style: tt.bodyMedium,
                        ),
                      ),
                      data: (reviews) {
                        if (reviews.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 52,
                                    color: cs.onSurface.withValues(alpha: 0.2),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.isAr
                                        ? 'لا توجد تقييمات بعد'
                                        : 'No reviews yet',
                                    style: tt.titleMedium?.copyWith(
                                      color: cs.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.isAr
                                        ? 'كن أول من يقيّم هذا المكان'
                                        : 'Be the first to review',
                                    style: tt.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          itemCount: reviews.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 0.4,
                            color: cs.surfaceContainerHighest,
                          ),
                          itemBuilder: (_, i) {
                            final r = reviews[i];
                            final isOwn = r.review.userId == currentUserId;
                            return _ReviewTile(
                              reviewWithUser: r,
                              isOwn: isOwn,
                              isAr: widget.isAr,
                              onDelete: isOwn
                                  ? () => ref
                                        .read(
                                          placeReviewsProvider(
                                            widget.placeId,
                                          ).notifier,
                                        )
                                        .deleteReview(r.review.id)
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Add review area ────────────────────────────────────
                  if (currentUserId != null) ...[
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: cs.surfaceContainerHighest,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: hasReviewed
                          ? _AlreadyReviewedBanner(
                              key: const ValueKey('banner'),
                              isAr: widget.isAr,
                            )
                          : _AddReviewInput(
                              key: const ValueKey('input'),
                              isAr: widget.isAr,
                              commentCtrl: _commentCtrl,
                              selectedRating: _selectedRating,
                              isLoading: isLoading,
                              onRatingChanged: (r) =>
                                  setState(() => _selectedRating = r),
                              onSubmit: isLoading ? null : _submit,
                            ),
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
//  Shared primitives
// ─────────────────────────────────────────────────────────────────────────────

/// Reusable drag handle pill — used here and in any other bottom sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// Star row — covers both the interactive input (large, tappable, padded)
/// and the display tile (small, read-only). Pass [onTap] to make it interactive.
class _Stars extends StatelessWidget {
  const _Stars({
    required this.rating,
    this.size = 13,
    this.spacing = 0,
    this.onTap,
  });

  final int rating;
  final double size;
  final double spacing;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? AppColors.headline2 : cs.surfaceContainerHighest,
          size: size,
        );
        if (onTap == null) return star;
        return GestureDetector(
          onTap: () => onTap!(i + 1),
          child: Padding(
            padding: EdgeInsets.only(right: spacing),
            child: star,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets — no longer receive cs / tt; each reads Theme.of(context)
// ─────────────────────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AlreadyReviewedBanner extends StatelessWidget {
  const _AlreadyReviewedBanner({super.key, required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'لقد قيّمت هذا المكان مسبقاً. يمكنك حذف تقييمك بالتمرير يميناً.'
                  : 'You already reviewed this place. Swipe your review left to delete it.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReviewInput extends StatelessWidget {
  const _AddReviewInput({
    super.key,
    required this.isAr,
    required this.commentCtrl,
    required this.selectedRating,
    required this.isLoading,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final bool isAr;
  final TextEditingController commentCtrl;
  final int selectedRating;
  final bool isLoading;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Star rating row ──────────────────────────────────────────
          _Stars(
            rating: selectedRating,
            size: 32,
            spacing: 4,
            onTap: onRatingChanged,
          ),
          const SizedBox(height: 10),

          // ── Instagram-style input row ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pill-shaped field with send button inside
              Expanded(
                child: TextField(
                  controller: commentCtrl,
                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  minLines: 1,
                  maxLines: 4,
                  autofocus: true,
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.outline,
                  ),
                
                  decoration: InputDecoration(
                    hintText: isAr ? 'أضف تعليقاً...' : 'Add a comment...',
                    hintStyle: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: cs.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: commentCtrl,
                      builder: (_, value, _) {
                        final hasText = value.text.trim().isNotEmpty;
                        if (!hasText) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: GestureDetector(
                            onTap: isLoading ? null : onSubmit,
                            child: Container(
                              width: 56, // wider
                              decoration: BoxDecoration(
                                color: isLoading
                                    ? cs.primary.withValues(alpha: 0.5)
                                    : cs.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                CupertinoIcons.arrow_up,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Review tile
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.reviewWithUser,
    required this.isOwn,
    required this.isAr,
    this.onDelete,
  });

  final ReviewWithUser reviewWithUser;
  final bool isOwn;
  final bool isAr;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final review = reviewWithUser.review;
    final name = reviewWithUser.displayName;

    Widget tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ───────────────────────────────────────────────────
          UserAvatar(
            avatarUrl: reviewWithUser.avatarUrl, // ← direct field
            initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
            radius: 20,
          ),

          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AFTER — stars on their own line below the name
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.isEmpty ? (isAr ? 'مستخدم' : 'User') : name,
                        style: tt.titleSmall?.copyWith(color: cs.outline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAr ? 'أنت' : 'You',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _Stars(rating: review.rating),
                const SizedBox(height: 4),
                if (review.comment?.isNotEmpty == true)
                  Text(
                    review.comment!,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          TimeAgo(iso: review.createdAt, isAr: isAr),
        ],
      ),
    );

    if (isOwn && onDelete != null) {
      tile = Dismissible(
        key: ValueKey(review.id),
        direction: DismissDirection.endToStart,
        background: const SizedBox.shrink(),
        secondaryBackground: Container(
          alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
          padding: EdgeInsets.only(left: isAr ? 20 : 0, right: isAr ? 0 : 20),
          decoration: BoxDecoration(
            color: AppColors.alert,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.trash, color: AppColors.white, size: 26),
              const SizedBox(height: 4),
              Text(
                isAr ? 'حذف' : 'Delete',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDelete!(),
        child: tile,
      );
    }

    return tile;
  }
}
