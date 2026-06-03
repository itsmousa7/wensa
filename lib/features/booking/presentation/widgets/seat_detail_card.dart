import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/features/booking/domain/models/event_tier.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';
import 'package:future_riverpod/features/booking/domain/models/venue_section.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

/// Bottom card shown in the section seat-picker — mirrors the rival's
/// seat-detail panel: the focused seat's stand / tier / price, plus the
/// running total of all selected seats and a Review action.
class SeatDetailCard extends StatelessWidget {
  const SeatDetailCard({
    super.key,
    required this.section,
    required this.focusedSeat,
    required this.selectedSeats,
    required this.tierByKey,
    required this.onReview,
  });

  final VenueSection section;
  final Seat? focusedSeat;
  final List<Seat> selectedSeats;
  final Map<String, EventTier> tierByKey;
  final VoidCallback onReview;

  int _priceOf(Seat s) => s.priceIqd > 0
      ? s.priceIqd
      : (tierByKey[s.tierKey]?.priceIqd ?? section.priceIqd);

  int get _total => selectedSeats.fold(0, (sum, s) => sum + _priceOf(s));

  String _money(int iqd) {
    final formatted = iqd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'IQD $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final sectionName = isAr
        ? (section.nameAr.isNotEmpty ? section.nameAr : section.nameEn)
        : (section.nameEn.isNotEmpty ? section.nameEn : section.nameAr);

    final seat = focusedSeat;
    final tier = seat != null ? tierByKey[seat.tierKey] : null;
    final tierName = tier == null
        ? section.tierKey
        : (isAr
              ? (tier.nameAr.isNotEmpty ? tier.nameAr : tier.nameEn)
              : (tier.nameEn.isNotEmpty ? tier.nameEn : tier.nameAr));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isAr ? 'التذاكر الخاصة بك' : 'Your Tickets',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (seat == null)
              Text(
                isAr
                    ? 'لم يتم اختيار تذكرة — اختر مقعداً على الخريطة'
                    : 'No ticket selected — pick a seat on the map',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: Column(
                  children: [
                    _detailRow(
                      context,
                      label: isAr ? 'المدرج' : 'Stand',
                      value: '$sectionName · ${seat.row}${seat.seat}',
                    ),
                    const SizedBox(height: 6),
                    _detailRow(
                      context,
                      label: isAr ? 'الفئة' : 'Tier',
                      value: tierName,
                    ),
                    const SizedBox(height: 6),
                    _detailRow(
                      context,
                      label: isAr ? 'سعر التذكرة' : 'Ticket price',
                      value: _money(_priceOf(seat)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAr ? 'الكلي' : 'Total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        '${selectedSeats.length} · ${_money(_total)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: selectedSeats.isEmpty ? null : onReview,
                  child: Text(
                    isAr ? 'مراجعة' : 'Review',
                    style: TextStyle(
                      fontFamily:
                          AppTypography.getBodyFontFamily(isAr ? 'ar' : 'en'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
