// lib/features/places/presentation/widgets/place_reviews_sheet.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/places/domain/models/review_with_user_model.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_reviews_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/comment_section_skeleton.dart';
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
    // isDismissible only fires when the MODAL BARRIER is tapped.
    // With isScrollControlled:true the DraggableScrollableSheet fills the full
    // height, so the barrier is never exposed. We handle dismiss with an
    // explicit GestureDetector in the builder (see below).
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) =>
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
    final userId = ref.read(authStateProvider)?.id;
    if (userId == null) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(placeReviewsProvider(widget.placeId).notifier)
        .addReview(
          userId: userId,
          rating: _selectedRating,
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
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
    final currentUserId = ref.watch(authStateProvider)?.id;
    final isLoading = reviewsAsync.isLoading;

    final hasReviewed =
        reviewsAsync.value?.any((r) => r.review.userId == currentUserId) ??
        false;
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    // ── Layout: Column fills the full modal height.
    // The top transparent GestureDetector dismisses when tapped — this reliably
    // handles "tap outside to close" even though isScrollControlled:true means
    // the DraggableScrollableSheet otherwise swallows all hit-testing above the
    // visible card.
    return Directionality(
      textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // ── Transparent dismiss area (top portion above the card) ──────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Actual sheet card ──────────────────────────────────────────────
          Container(
            // 75 % of the screen height; keyboard pushes it up automatically
            // via MediaQuery.viewInsets in the input area.
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // ── Handle + Header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
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
                            data: (r) =>
                                _CountBadge(count: r.length, cs: cs, tt: tt),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                          const Spacer(),
                          // ↓ replace the old CircularProgressIndicator with this
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
                              child: Bone(
                                width: 60,
                                height: 14,
                                borderRadius: BorderRadius.circular(6),
                              ),
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

                // ── Reviews list ───────────────────────────────────────────
                Expanded(
                  child: reviewsAsync.when(
                    loading: () => const ReviewsSkeleton(),
                    error: (e, _) => Center(
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
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.45),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.isAr
                                      ? 'كن أول من يقيّم هذا المكان'
                                      : 'Be the first to review',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.3),
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
                            tt: tt,
                            cs: cs,
                            // Only allow swipe-delete on own reviews
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

                // ── Add Review area ────────────────────────────────────────
                if (currentUserId != null) ...[
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: cs.surfaceContainerHighest,
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: hasReviewed
                        ? ConstrainedBox(
                            key: const ValueKey('banner'),
                            constraints:
                                const BoxConstraints(), // ← matches input height
                            child: _AlreadyReviewedBanner(
                              isAr: widget.isAr,
                              cs: cs,
                              tt: tt,
                            ),
                          )
                        : ConstrainedBox(
                            key: const ValueKey('input'),
                            constraints: const BoxConstraints(minHeight: 120),
                            child: _AddReviewInput(
                              isAr: widget.isAr,
                              tt: tt,
                              cs: cs,
                              commentCtrl: _commentCtrl,
                              selectedRating: _selectedRating,
                              isLoading: isLoading,
                              onRatingChanged: (r) =>
                                  setState(() => _selectedRating = r),
                              onSubmit: isLoading ? null : _submit,
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.cs, required this.tt});
  final int count;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Container(
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

class _AlreadyReviewedBanner extends StatelessWidget {
  const _AlreadyReviewedBanner({
    required this.isAr,
    required this.cs,
    required this.tt,
  });
  final bool isAr;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).scaffoldBackgroundColor,
    padding: EdgeInsets.fromLTRB(20, 14, 20, 40),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline_rounded, color: cs.primary, size: 20),
        const SizedBox(width: 10),
        // ── FIX: Expanded prevents horizontal overflow ──────────────
        Expanded(
          child: Text(
            isAr
                ? 'لقد قيّمت هذا المكان مسبقاً. يمكنك حذف تقييمك بالتمرير يساراً.'
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

class _AddReviewInput extends StatelessWidget {
  const _AddReviewInput({
    super.key,
    required this.isAr,
    required this.tt,
    required this.cs,
    required this.commentCtrl,
    required this.selectedRating,
    required this.isLoading,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final bool isAr;
  final TextTheme tt;
  final ColorScheme cs;
  final TextEditingController commentCtrl;
  final int selectedRating;
  final bool isLoading;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        MediaQuery.of(context).viewInsets.bottom + 56,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star row — large & prominent
          Row(
            children: List.generate(5, (i) {
              final filled = i < selectedRating;
              return GestureDetector(
                onTap: () => onRatingChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled
                        ? AppColors.headline2
                        : cs.onSurface.withValues(alpha: 0.3),
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: commentCtrl,
                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  minLines: 1,
                  maxLines: 3,
                  style: tt.bodyMedium,
                  decoration: InputDecoration(
                    hintText: isAr ? 'أضف تعليقاً...' : 'Add a comment...',
                    hintStyle: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onSubmit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isLoading
                        ? cs.primary.withValues(alpha: 0.5)
                        : cs.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: cs.onPrimary,
                    size: 20,
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
//  _ReviewTile — swipe-left to delete own review, no visible delete button
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.reviewWithUser,
    required this.isOwn,
    required this.isAr,
    required this.tt,
    required this.cs,
    this.onDelete,
  });

  final ReviewWithUser reviewWithUser;
  final bool isOwn;
  final bool isAr;
  final TextTheme tt;
  final ColorScheme cs;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final review = reviewWithUser.review;
    final name = reviewWithUser.displayName;
    final initials = reviewWithUser.initials;

    Widget tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            backgroundImage: reviewWithUser.avatarUrl != null
                ? CachedNetworkImageProvider(reviewWithUser.avatarUrl!)
                : null,
            child: reviewWithUser.avatarUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.isEmpty ? (isAr ? 'مستخدم' : 'User') : name,
                        style: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                    const Spacer(),
                    // Stars
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: i < review.rating
                              ? AppColors.headline2
                              : cs.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (review.comment != null && review.comment!.isNotEmpty)
                  Text(
                    review.comment!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(review.createdAt),
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // ── Wrap own review in Dismissible for swipe-left to delete ────────────
    if (isOwn && onDelete != null) {
      // inside _ReviewTile, replace the Dismissible block
      tile = Dismissible(
        key: ValueKey(review.id),
        direction:
            DismissDirection.endToStart, // same physical gesture both languages
        background: const SizedBox.shrink(), // not used
        secondaryBackground: Container(
          alignment: isAr
              ? Alignment.centerLeft
              : Alignment.centerRight, // ← Arabic: left side
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

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
