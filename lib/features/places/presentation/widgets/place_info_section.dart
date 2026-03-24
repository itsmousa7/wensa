import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_app_bar_state.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_contact_section.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_details_helper.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_location_sheet.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_opening_hours.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_reviews_sheet.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_statistic_chip.dart';
import 'package:gap/gap.dart';

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

    final name = isAr ? place.nameAr : place.nameEn;
    final desc = isAr ? place.descriptionAr : place.descriptionEn;
    final isLong = (desc ?? '').length > _descLimit;

    // ── Reusable decoration for primary-tinted chips ────────────────────
    BoxDecoration primaryChipDecoration() => BoxDecoration(
      color: cs.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
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
          // ── Name + verified ───────────────────────────────────────────
          Row(
            children: [
              Text(
                name,
                style: tt.titleLarge?.copyWith(
                  color: cs.outline,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              if (place.isVerified) ...[
                const Gap(15),
                SizedBox(
                  height: 20,
                  child: SvgPicture.asset('assets/icons/verify.svg'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Location chip ─────────────────────────────────────────────
          if (place.area != null || place.city.isNotEmpty)
            GestureDetector(
              onTap: place.latitude != null && place.longitude != null
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
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: primaryChipDecoration(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 14,
                      child: SvgPicture.asset('assets/icons/location.svg'),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      [
                        if (place.area?.isNotEmpty == true) place.area!,
                        if (place.city.isNotEmpty) place.city,
                      ].join(' · '),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (place.latitude != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.arrow_up_right_square,
                        size: 16,
                        color: cs.primary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ),
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
                  icon: Icons.star,
                  value: compactNumber(place.reviewsCount),
                  label: isAr ? 'تقييم' : 'Reviews',
                  highlighted: true,
                  textColor: cs.secondary,
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
                            borderRadius: BorderRadius.circular(20),
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
            PlaceOpeningHours(hours: place.openingHours!, isAr: isAr),
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

          // ── Reviews CTA ───────────────────────────────────────────────
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => showReviewsSheet(
              context: context,
              placeId: placeId,
              placeName: name,
              isAr: isAr,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, AppColors.lightGreenSecondary],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'التقييمات' : 'Reviews',
                    style: tt.titleMedium?.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
