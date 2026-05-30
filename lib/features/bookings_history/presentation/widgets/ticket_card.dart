// lib/features/bookings_history/presentation/widgets/ticket_card.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_status_badge.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:intl/intl.dart';

/// Displays a booking or membership as a modern list card.
class TicketCard extends StatelessWidget {
  const TicketCard.booking({
    super.key,
    required this.booking,
    required this.onTap,
  }) : membership = null;

  const TicketCard.membership({
    super.key,
    required this.membership,
    required this.onTap,
  }) : booking = null;

  final Booking? booking;
  final Membership? membership;
  final VoidCallback onTap;

  static IconData _categoryIcon(BookingCategory cat) {
    switch (cat) {
      case BookingCategory.hourly:
        return CupertinoIcons.sportscourt;
      case BookingCategory.shift:
        return Icons.place;
      case BookingCategory.venueSeat:
        return CupertinoIcons.music_house;
      case BookingCategory.reservation:
        return Icons.restaurant_rounded;
      case BookingCategory.membership:
        return Icons.fitness_center_rounded;
    }
  }

  static Color _categoryAccent(BookingCategory cat) {
    switch (cat) {
      case BookingCategory.hourly:
        return const Color(0xFF3490A2);
      case BookingCategory.shift:
        return const Color(0xFF43A047);
      case BookingCategory.venueSeat:
        return const Color(0xFF8E24AA);
      case BookingCategory.reservation:
        return const Color(0xFFEF6C00);
      case BookingCategory.membership:
        return const Color(0xFF1E88E5);
    }
  }

  static String _formatAmount(int iqd) =>
      '${NumberFormat('#,##0').format(iqd)} IQD';

  static String _categoryFallback(BookingCategory cat, bool isArabic) {
    switch (cat) {
      case BookingCategory.hourly:
        return isArabic ? 'حجز رياضي' : 'Sports Booking';
      case BookingCategory.shift:
        return isArabic ? 'حجز مزرعة' : 'Farm Booking';
      case BookingCategory.venueSeat:
        return isArabic ? 'حجز حفلة' : 'Concert Booking';
      case BookingCategory.reservation:
        return isArabic ? 'حجز مطعم' : 'Restaurant Booking';
      case BookingCategory.membership:
        return isArabic ? 'عضوية' : 'Membership';
    }
  }

  static String _formatTimeRemaining(String iso, bool isArabic) {
    if (iso.isEmpty) return '';
    final DateTime dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '';
    }
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return '';
    if (diff.inDays >= 1) {
      final d = diff.inDays;
      return isArabic
          ? 'خلال $d ${d == 1 ? 'يوم' : 'أيام'}'
          : 'in $d ${d == 1 ? 'day' : 'days'}';
    }
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      return isArabic
          ? 'خلال $h ${h == 1 ? 'ساعة' : 'ساعات'}'
          : 'in $h ${h == 1 ? 'hour' : 'hours'}';
    }
    final m = diff.inMinutes;
    if (m < 1) return isArabic ? 'الآن' : 'now';
    return isArabic ? 'خلال $m دقيقة' : 'in $m min';
  }

  // Informal Arabic weekday names (no ال prefix).
  // Index order: 0=Sunday, 1=Monday … 6=Saturday (matches dt.weekday % 7).
  static const _arWeekdays = [
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
  ];

  static String _formatWeekdayDate(String iso, bool isArabic) {
    if (iso.isEmpty) return '';
    final DateTime dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '';
    }
    if (isArabic) {
      final weekday =
          _arWeekdays[dt.weekday % 7]; // DateTime.sunday==7 → index 0
      const monthNames = [
        '',
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      return '$weekday، ${dt.day} ${monthNames[dt.month]} ${dt.year}';
    } else {
      return DateFormat('EEEE, d MMM yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (booking != null) return _BookingCard(booking: booking!, onTap: onTap);
    return _MembershipCard(membership: membership!, onTap: onTap);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cardColor = Theme.of(context).colorScheme.surfaceContainer;
    final accent = TicketCard._categoryAccent(booking.category);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Resolve bilingual display name (mirrors _BookingDetailBody)
    final String placeName;
    if (booking.placeId != null && booking.placeId!.isNotEmpty) {
      final pa = ref.watch(placeDetailsProvider(booking.placeId!));
      placeName = pa.when(
        data: (p) => isArabic
            ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn)
            : (p.nameEn.isNotEmpty ? p.nameEn : p.nameAr),
        loading: () => '…',
        // ignore: avoid_types_on_closure_parameters
        error: (e, st) =>
            TicketCard._categoryFallback(booking.category, isArabic),
      );
    } else if (booking.eventId != null && booking.eventId!.isNotEmpty) {
      final ea = ref.watch(eventDetailsProvider(booking.eventId!));
      placeName = ea.when(
        data: (e) => isArabic
            ? (e.titleAr.isNotEmpty ? e.titleAr : e.titleEn)
            : (e.titleEn.isNotEmpty ? e.titleEn : e.titleAr),
        loading: () => '…',
        // ignore: avoid_types_on_closure_parameters
        error: (e, st) =>
            TicketCard._categoryFallback(booking.category, isArabic),
      );
    } else {
      placeName = TicketCard._categoryFallback(booking.category, isArabic);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: GestureDetector(
          onTap: onTap,

          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon square
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    TicketCard._categoryIcon(booking.category),
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: place/event name + status badge
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                placeName,
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TicketStatusBadge.booking(
                              status: booking.status,
                              isArabic: isArabic,
                            ),
                          ],
                        ),
                      ),
                      // Row 2: time remaining (only when in the future)
                      Builder(
                        builder: (context) {
                          final remaining = TicketCard._formatTimeRemaining(
                            booking.startsAt,
                            isArabic,
                          );
                          if (remaining.isEmpty) return const SizedBox.shrink();
                          return Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                remaining,
                                style: tt.bodySmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      // Row 3: weekday+date (left) · amount (right)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                TicketCard._formatWeekdayDate(
                                  booking.startsAt,
                                  isArabic,
                                ),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              TicketCard._formatAmount(booking.amountIqd),
                              style: tt.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MembershipCard extends ConsumerWidget {
  const _MembershipCard({required this.membership, required this.onTap});

  final Membership membership;
  final VoidCallback onTap;

  static const _accent = Color(0xFF1E88E5);

  /// "expires in N days" shown only on active memberships, mirrors
  /// _BookingCard's _formatTimeRemaining.
  static String _formatExpiresIn(String endsAt, bool isArabic) {
    if (endsAt.isEmpty) return '';
    final DateTime dt;
    try {
      dt = DateTime.parse(endsAt);
    } catch (_) {
      return '';
    }
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return '';
    if (diff.inDays >= 1) {
      final d = diff.inDays;
      return isArabic
          ? 'ينتهي خلال $d ${d == 1 ? 'يوم' : 'أيام'}'
          : 'expires in $d ${d == 1 ? 'day' : 'days'}';
    }
    return isArabic ? 'ينتهي اليوم' : 'expires today';
  }

  static String _formatDateRange(
      String startsAt, String endsAt, bool isArabic) {
    if (startsAt.isEmpty || endsAt.isEmpty) return '';
    try {
      final start = DateTime.parse(startsAt);
      final end = DateTime.parse(endsAt);
      if (isArabic) {
        const months = [
          '',
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
        ];
        return '${start.day} ${months[start.month]} – '
            '${end.day} ${months[end.month]} ${end.year}';
      } else {
        return '${DateFormat('d MMM').format(start)} – '
            '${DateFormat('d MMM yyyy').format(end)}';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cardColor = Theme.of(context).colorScheme.surfaceContainer;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Resolve place name — same pattern as _BookingCard
    final String placeName;
    if (membership.placeId.isNotEmpty) {
      final pa = ref.watch(placeDetailsProvider(membership.placeId));
      placeName = pa.when(
        data: (p) => isArabic
            ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn)
            : (p.nameEn.isNotEmpty ? p.nameEn : p.nameAr),
        loading: () => '…',
        error: (_, _) => isArabic ? 'عضوية' : 'Membership',
      );
    } else {
      placeName = isArabic ? 'عضوية' : 'Membership';
    }

    final expiresIn = membership.status == MembershipStatus.active
        ? _formatExpiresIn(membership.endsAt, isArabic)
        : '';
    final dateRange =
        _formatDateRange(membership.startsAt, membership.endsAt, isArabic);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon square — identical to _BookingCard
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: _accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: place name + status badge
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                placeName,
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TicketStatusBadge.membership(
                              status: membership.status,
                              isArabic: isArabic,
                            ),
                          ],
                        ),
                      ),
                      // Row 2: expires countdown (active only)
                      if (expiresIn.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              expiresIn,
                              style: tt.bodySmall?.copyWith(
                                color: _accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      // Row 3: date range (left) · amount (right)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dateRange,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              TicketCard._formatAmount(membership.amountIqd),
                              style: tt.bodySmall?.copyWith(
                                color: _accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
