import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget, WidgetRef
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_app_bar_state.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_contact_section.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_details_helper.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_location_sheet.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_opening_hours.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_reviews_sheet.dart';
import 'package:gap/gap.dart'; // placeTagsProvider

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(placeAppbarStateProvider(placeId));
    final notifier = ref.read(placeAppbarStateProvider(placeId).notifier);
    final tagsAsync = ref.watch(placeTagsProvider(placeId));

    final name = isAr ? place.nameAr : place.nameEn;
    final desc = isAr ? place.descriptionAr : place.descriptionEn;
    const descLimit = 120;
    final isLong = (desc ?? '').length > descLimit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + verified ─────────────────────────────────────────────
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
              const Gap(15),
              if (place.isVerified) ...[
                SizedBox(
                  height: 20,
                  child: Image.asset('assets/icons/verify.png'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Location chip ───────────────────────────────────────────────
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
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 14,
                      child: Image.asset('assets/icons/location.png'),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      [
                        if (place.area?.isNotEmpty == true) place.area!,
                        if (place.city.isNotEmpty) place.city,
                      ].join(' · '),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
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

          // ── Stats row ───────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                _StatChip(
                  icon: Icons.visibility_outlined,
                  value: compactNumber(place.viewCount),
                  label: isAr ? 'مشاهدة' : 'Views',
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.favorite_rounded,
                  value: compactNumber(place.savesCount),
                  label: isAr ? 'إعجاب' : 'Likes',
                  accentColor: AppColors.alert,
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => showReviewsSheet(
                    context: context,
                    placeId: placeId,
                    placeName: name,
                    isAr: isAr,
                  ),
                  child: _StatChip(
                    icon: Icons.star_rounded,
                    value: compactNumber(place.reviewsCount),
                    label: isAr ? 'تقييم' : 'Reviews',
                    highlighted: true,
                  ),
                ),
              ],
            ),
          ),

          // ── Price range ─────────────────────────────────────────────────
          if (place.priceRange != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  isAr ? 'نطاق السعر:' : 'Price range:',
                  style: tt.bodyMedium?.copyWith(color: cs.outline),
                ),
                const SizedBox(width: 8),
                ...List.generate(
                  4,
                  (i) => Text(
                    '\$',
                    style: tt.bodyMedium?.copyWith(
                      color: i < (place.priceRange ?? 0)
                          ? AppColors.lightGreenSecondary
                          : cs.onSurface.withValues(alpha: 0.2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Tags ────────────────────────────────────────────────────────
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
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                            ),
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

          // ── Description ─────────────────────────────────────────────────
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: isAr ? 'عن المكان' : 'About'),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: state.descExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                isLong && !state.descExpanded
                    ? '${desc.substring(0, descLimit)}...'
                    : desc,
                style: tt.bodyLarge?.copyWith(color: cs.outline, height: 1.65),
              ),
              secondChild: Text(
                desc,
                style: tt.bodyLarge?.copyWith(color: cs.outline, height: 1.65),
              ),
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

          // ── Opening hours ───────────────────────────────────────────────
          if (place.openingHours != null && place.openingHours!.isNotEmpty) ...[
            const SizedBox(height: 24),
            PlaceOpeningHours(hours: place.openingHours!, isAr: isAr),
          ],

          // ── Contact ─────────────────────────────────────────────────────
          if (place.phone != null ||
              place.instagramUrl != null ||
              place.websiteUrl != null) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: isAr ? 'التواصل' : 'Contact'),
            const SizedBox(height: 12),
            PlaceContactSection(place: place, isAr: isAr),
          ],

          // ── Reviews CTA ─────────────────────────────────────────────────
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
                  const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isAr
                        ? 'التقييمات (${place.reviewsCount})'
                        : 'Reviews (${place.reviewsCount})',
                    style: tt.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

// ── Shared small widgets ──────────────────────────────────────────────────────

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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.highlighted = false,
    this.accentColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlighted;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color =
        accentColor ??
        (highlighted ? cs.primary : cs.onSurface.withValues(alpha: 0.5));
    final bg = accentColor != null
        ? accentColor!.withValues(alpha: 0.08)
        : highlighted
        ? cs.primary.withValues(alpha: 0.08)
        : cs.surfaceContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: tt.titleLarge?.copyWith(
                  color: cs.onSurface,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
