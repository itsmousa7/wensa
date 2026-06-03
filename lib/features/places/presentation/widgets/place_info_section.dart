import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/widgets/discount_badge.dart';
import 'package:future_riverpod/core/widgets/merchant_logo.dart';
import 'package:future_riverpod/core/widgets/place_statistic_chip.dart';
import 'package:future_riverpod/core/widgets/primary_action_button.dart';
import 'package:future_riverpod/features/discounts/presentation/providers/merchant_discounts_provider.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_app_bar_state.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_contact_section.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_details_helper.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_location_sheet.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_opening_hours.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_reviews_sheet.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

class PlaceInfoSection extends ConsumerWidget {
  const PlaceInfoSection({
    super.key,
    required this.place,
    required this.placeId,
    required this.isAr,
  });

  final PlaceModel place;
  final String placeId;
  final bool isAr;

  static const _descLimit = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(placeAppbarStateProvider(placeId));
    final notifier = ref.read(placeAppbarStateProvider(placeId).notifier);
    final tagsAsync = ref.watch(placeTagsProvider(placeId));
    final autoDiscount = ref.watch(
      bestAutoDiscountProvider(
        AutoDiscountKey(
          orderType: 'bookings',
          placeId: place.id,
          merchantId: place.merchantId,
          categoryId: place.categoryId,
        ),
      ),
    );
    final merchantDiscount = ref.watch(
      placeMerchantDiscountProvider(
        PlaceDiscountKey(placeId: place.id, merchantId: place.merchantId),
      ),
    );
    // Highest-percent discount for the header badge — merchant discount may
    // beat the auto-discount, and we always want to surface the best offer.
    final autoPercent = autoDiscount?.percent ?? 0;
    final merchPercent = merchantDiscount?.percent ?? 0;
    final bestPercent = autoPercent > merchPercent ? autoPercent : merchPercent;
    final headerDiscountPercent = bestPercent > 0 ? bestPercent.round() : null;
    // Spending cap of whichever offer is being surfaced (the winning one).
    final headerMaxDiscount = bestPercent <= 0
        ? null
        : (autoPercent > merchPercent
              ? autoDiscount?.maxDiscountAmount
              : merchantDiscount?.maxDiscountAmount);

    final name = isAr ? place.nameAr : place.nameEn;
    final desc = isAr ? place.descriptionAr : place.descriptionEn;
    final isLong = (desc ?? '').length > _descLimit;

    // ── Reusable decoration for primary-tinted chips ────────────────────
    BoxDecoration primaryChipDecoration() => BoxDecoration(
      color: cs.primary.withValues(alpha: 0.08),
      borderRadius: AppSpacing.borderRadiusMD,
      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
    );

    // ── Reusable description text style ────────────────────────────────
    final descStyle = tt.labelLarge?.copyWith(
      color: cs.outline,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo + Name + Location (ListTile-style) ───────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MerchantLogo(logoUrl: place.logoUrl, size: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: tt.titleLarge?.copyWith(
                              color: cs.outline,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (place.isVerified) ...[
                          const Gap(10),
                          SizedBox(
                            height: 20,
                            child: SvgPicture.asset('assets/icons/verify.svg'),
                          ),
                        ],
                      ],
                    ),
                    // Location chip + discount badge
                    if (place.area != null || place.city.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          GestureDetector(
                            onTap:
                                place.latitude != null &&
                                    place.longitude != null
                                ? () => showLocationSheet(
                                    context: context,
                                    latitude: place.latitude!,
                                    longitude: place.longitude!,
                                    placeName: name,
                                    isAr: isAr,
                                  )
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: primaryChipDecoration(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 13,
                                    child: SvgPicture.asset(
                                      'assets/icons/location.svg',
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      [
                                        if (isAr
                                            ? (place.areaAr ?? place.area)?.isNotEmpty == true
                                            : place.area?.isNotEmpty == true)
                                          (isAr ? (place.areaAr ?? place.area)! : place.area!),
                                        if ((isAr ? (place.cityAr ?? place.city) : place.city).isNotEmpty)
                                          isAr ? (place.cityAr ?? place.city) : place.city,
                                      ].join(' · '),
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (place.latitude != null) ...[
                                    const SizedBox(width: 5),
                                    Icon(
                                      CupertinoIcons.arrow_up_right_square,
                                      size: 14,
                                      color: cs.primary.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (headerDiscountPercent != null)
                            DiscountBadge(percent: headerDiscountPercent),
                          if (headerMaxDiscount != null &&
                              headerMaxDiscount > 0)
                            MaxDiscountBadge(
                              maxAmount: headerMaxDiscount,
                              isAr: isAr,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────────────────────
          Row(
            children: [
              PlaceStatisticChip(
                icon: CupertinoIcons.eye,
                value: compactNumber(place.viewCount),
                label: isAr ? 'مشاهدة' : 'Views',
                textColor: cs.secondary,
                accentColor: cs.primary,
              ),
              const SizedBox(width: 10),
              PlaceStatisticChip(
                icon: CupertinoIcons.heart_fill,
                value: compactNumber(place.savesCount),
                label: isAr ? 'إعجاب' : 'Likes',
                accentColor: AppColors.alert,
                textColor: cs.errorContainer,
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => showReviewsSheet(
                  context: context,
                  placeId: placeId,
                  placeName: name,
                  isAr: isAr,
                ),
                child: PlaceStatisticChip(
                  icon: Icons.star_rounded,
                  value: compactNumber(place.reviewsCount),
                  label: isAr ? 'تقييم' : 'Reviews',
                  accentColor: const Color(0xFFFFC107),
                  textColor: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),

          // ── Tags ──────────────────────────────────────────────────────
          tagsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (tags) {
              if ((tags as List).isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 26),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          // Reuses the same chip decoration with pill radius
                          decoration: primaryChipDecoration().copyWith(
                            borderRadius: AppSpacing.borderRadiusXL,
                          ),
                          child: Text(
                            isAr ? tag.nameAr : tag.nameEn,
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),

          // ── Description ───────────────────────────────────────────────
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: isAr ? 'عن المكان' : 'About'),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: state.descExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              // Reuses descStyle for both children
              firstChild: Text(
                '${desc.substring(0, isLong ? _descLimit : desc.length)}${isLong ? '...' : ''}',
                style: descStyle,
              ),
              secondChild: Text(desc, style: descStyle),
            ),
            if (isLong)
              GestureDetector(
                onTap: notifier.toggleDesc,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    state.descExpanded
                        ? (isAr ? 'عرض أقل' : 'Show less')
                        : (isAr ? 'اقرأ المزيد' : 'Read more'),
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],

          // ── Opening hours ─────────────────────────────────────────────
          if (place.openingHours != null && place.openingHours!.isNotEmpty) ...[
            const SizedBox(height: 24),
            PlaceOpeningHours(
              hours: place.openingHours!,
              isAr: isAr,
              // Per-day discount badges only make sense for hourly bookings —
              // the merchant_discounts.hour_slots window has no effect on
              // shift/day-based bookings.
              discount: place.bookingCategory == 'hourly'
                  ? merchantDiscount
                  : null,
            ),
          ],

          // ── Contact ───────────────────────────────────────────────────
          if (place.phone != null ||
              place.instagramUrl != null ||
              place.websiteUrl != null) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: isAr ? 'التواصل' : 'Contact'),
            const SizedBox(height: 12),
            PlaceContactSection(place: place, isAr: isAr),
          ],

          // ── Reviews card ──────────────────────────────────────────────
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: AppSpacing.borderRadiusLG,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showReviewsSheet(
                    context: context,
                    placeId: placeId,
                    placeName: name,
                    isAr: isAr,
                  ),
                  splashColor: cs.primary.withValues(alpha: 0.07),
                  highlightColor: cs.primary.withValues(alpha: 0.04),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC107),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'التقييمات' : 'Reviews',
                                style: tt.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  letterSpacing: -0.2,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAr
                                    ? '${compactNumber(place.reviewsCount)} تقييم'
                                    : '${compactNumber(place.reviewsCount)} ratings',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.outline,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr ? 'عرض الكل' : 'See all',
                              style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              isAr
                                  ? CupertinoIcons.chevron_left
                                  : CupertinoIcons.chevron_right,
                              size: 13,
                              color: cs.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── CTAs ──────────────────────────────────────────────────────
          const SizedBox(height: 28),
          if (place.bookingCategory != null) ...[
            PrimaryActionButton(
              label: isAr ? 'احجز الآن' : 'Book Now',
              onTap: () => context.push(
                '/place/$placeId/book?category=${place.bookingCategory}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.outline,
          ),
        ),
      ],
    );
  }
}
