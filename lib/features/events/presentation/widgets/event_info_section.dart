// lib/features/events/presentation/widgets/event_info_section.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_app_bar_state.dart';
import 'package:future_riverpod/features/events/presentation/widgets/event_date_section.dart';
import 'package:future_riverpod/features/events/presentation/widgets/event_ticket_section.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_details_helper.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_location_sheet.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_statistic_chip.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

class EventInfoSection extends ConsumerWidget {
  const EventInfoSection({
    super.key,
    required this.event,
    required this.eventId,
    required this.isAr,
  });

  final EventModel event;
  final String eventId;
  final bool isAr;

  static const _descLimit = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(eventAppbarStateProvider(eventId));
    final notifier = ref.read(eventAppbarStateProvider(eventId).notifier);

    final title = isAr ? event.titleAr : event.titleEn;
    final desc = isAr ? event.descriptionAr : event.descriptionEn;
    final isLong = (desc ?? '').length > _descLimit;
    final hasLocation = event.latitude != null && event.longitude != null;

    BoxDecoration primaryChipDecoration() => BoxDecoration(
      color: cs.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
    );

    final descStyle = tt.labelLarge?.copyWith(
      color: cs.outline,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + featured badge ─────────────────────────────────────
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: tt.titleLarge?.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ),
              if (event.isFeatured) ...[
                const Gap(15),
                SizedBox(
                  height: 20,
                  child: SvgPicture.asset('assets/icons/verify.svg'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Location chip — tappable when lat/lng available ────────────
          if (event.city != null && event.city!.isNotEmpty)
            GestureDetector(
              onTap: hasLocation
                  ? () => showLocationSheet(
                      context: context,
                      latitude: event.latitude!,
                      longitude: event.longitude!,
                      placeName: title,
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
                      event.city!,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Arrow icon shown only when location is tappable
                    if (hasLocation) ...[
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
          const SizedBox(height: 10),

          // ── Date chip ─────────────────────────────────────────────────
          if (event.startDate.isNotEmpty)
            EventDateSection(
              startDate: event.startDate,
              endDate: event.endDate,
              isAr: isAr,
            ),
          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────────────────────
          Row(
            children: [
              PlaceStatisticChip(
                icon: CupertinoIcons.eye,
                value: compactNumber(event.viewCount),
                label: isAr ? 'مشاهدة' : 'Views',
                accentColor: cs.primary,
                textColor: cs.primary,
              ),
              const SizedBox(width: 10),
              PlaceStatisticChip(
                icon: CupertinoIcons.heart_fill,
                value: compactNumber(event.savesCount),
                label: isAr ? 'إعجاب' : 'Likes',
                accentColor: AppColors.alert,
                textColor: cs.errorContainer,
              ),
              const SizedBox(width: 10),
              PlaceStatisticChip(
                icon: CupertinoIcons.person_2_fill,
                value: compactNumber(event.checkinsCount),
                label: isAr ? 'حضور' : 'Going',
                accentColor: cs.primary,
                textColor: cs.primary,
              ),
            ],
          ),

          // ── Ticket section ─────────────────────────────────────────────
          if (event.ticketPrice != null || event.ticketUrl != null) ...[
            const SizedBox(height: 16),
            _EventSectionHeader(title: isAr ? 'التذاكر' : 'Tickets'),
            const SizedBox(height: 12),
            EventTicketSection(
              ticketPrice: event.ticketPrice ?? 0,
              ticketUrl: event.ticketUrl ?? '',
              isAr: isAr,
            ),
          ],

          // ── Description ────────────────────────────────────────────────
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 20),
            _EventSectionHeader(title: isAr ? 'عن الحدث' : 'About'),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: state.descExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                '${desc.substring(0, isLong ? _descLimit : desc.length)}'
                '${isLong ? '...' : ''}',
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

          // ── CTA ────────────────────────────────────────────────────────
          const SizedBox(height: 28),
          _EventCtaButton(ticketUrl: event.ticketUrl, isAr: isAr),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _EventSectionHeader extends StatelessWidget {
  const _EventSectionHeader({required this.title});
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

// ── CTA button ─────────────────────────────────────────────────────────────────

class _EventCtaButton extends StatelessWidget {
  const _EventCtaButton({required this.ticketUrl, required this.isAr});

  final String? ticketUrl;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasUrl = ticketUrl != null && ticketUrl!.isNotEmpty;

    return GestureDetector(
      onTap: hasUrl ? () => _launch(ticketUrl!) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: hasUrl
              ? LinearGradient(
                  colors: [cs.primary, AppColors.lightGreenSecondary],
                )
              : null,
          color: hasUrl ? null : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          boxShadow: hasUrl
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasUrl
                  ? Icons.confirmation_num_outlined
                  : Icons.event_busy_outlined,
              color: hasUrl
                  ? AppColors.white
                  : cs.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              hasUrl
                  ? (isAr ? 'احجز تذكرتك الآن' : 'Get Your Tickets')
                  : (isAr ? 'لا تتوفر تذاكر حالياً' : 'No Tickets Available'),
              style: tt.titleMedium?.copyWith(
                color: hasUrl
                    ? AppColors.white
                    : cs.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
