// lib/features/bookings_history/presentation/pages/ticket_detail_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:future_riverpod/core/share/share_service.dart';
import 'package:future_riverpod/core/share/share_link.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_visual_card.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_status_badge.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────────────────────

class TicketDetailPage extends ConsumerWidget {
  const TicketDetailPage({super.key, required this.id});

  final String id;

  bool get _isMembership => id.startsWith('m_');
  String get _rawId => _isMembership ? id.substring(2) : id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context);
    return Scaffold(
      backgroundColor: cs.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/bookings');
            }
          },
          child: Icon(
            isArabic
                ? CupertinoIcons.chevron_right
                : CupertinoIcons.chevron_left,
            color: cs.colorScheme.onSurface,
          ),
        ),
        title: Text(
          _isMembership
              ? (isArabic ? 'العضوية' : 'Membership')
              : (isArabic ? 'تفاصيل الحجز' : 'Booking Details'),
          style: cs.textTheme.titleLarge?.copyWith(
            color: cs.colorScheme.onSurface,
          ),
        ),
      ),
      body: _isMembership
          ? _MembershipDetail(membershipId: _rawId)
          : _BookingDetail(bookingId: _rawId),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Booking detail
// ─────────────────────────────────────────────────────────────────────────────

class _BookingDetail extends ConsumerWidget {
  const _BookingDetail({required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBooking = ref.watch(bookingDetailProvider(bookingId));
    return asyncBooking.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBody(
        message: e.toString(),
        onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
      ),
      data: (booking) => _BookingDetailBody(booking: booking),
    );
  }
}

class _BookingDetailBody extends ConsumerWidget {
  const _BookingDetailBody({required this.booking});
  final Booking booking;

  static String _date(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String _time(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String _amount(int iqd) => '${NumberFormat('#,##0').format(iqd)} IQD';

  static String _shiftTypeLabel(String raw, bool ar) {
    switch (raw) {
      case 'day':
        return ar ? 'نهار' : 'Day';
      case 'night':
        return ar ? 'ليل' : 'Night';
      case 'full':
        return ar ? 'يوم كامل' : 'Full Day';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Resolve display name (prefer locale)
    final String name;
    if (booking.placeId != null && booking.placeId!.isNotEmpty) {
      final pa = ref.watch(placeDetailsProvider(booking.placeId!));
      name = pa.when(
        data: (p) => isArabic
            ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn)
            : (p.nameEn.isNotEmpty ? p.nameEn : p.nameAr),
        loading: () => '…',
        error: (_, _) => booking.category.name.toUpperCase(),
      );
    } else if (booking.eventId != null && booking.eventId!.isNotEmpty) {
      final ea = ref.watch(eventDetailsProvider(booking.eventId!));
      name = ea.when(
        data: (e) => isArabic
            ? (e.titleAr.isNotEmpty ? e.titleAr : e.titleEn)
            : (e.titleEn.isNotEmpty ? e.titleEn : e.titleAr),
        loading: () => '…',
        error: (_, _) => booking.category.name.toUpperCase(),
      );
    } else {
      name = booking.category.name.toUpperCase();
    }

    // Category-specific cells (court name resolved via provider)
    final d = booking.categoryData;
    final extraCells = <TicketInfoCell>[];

    switch (booking.category) {
      case BookingCategory.hourly:
        final courtId = d['court_id']?.toString() ?? '';
        final placeId = booking.placeId ?? '';
        final String courtDisplay;
        if (courtId.isNotEmpty && placeId.isNotEmpty) {
          final courtsAsync = ref.watch(courtsProvider(placeId));
          courtDisplay = courtsAsync.when(
            data: (courts) {
              final court = courts.where((c) => c.id == courtId).firstOrNull;
              if (court == null) return courtId;
              return isArabic
                  ? (court.nameAr.isNotEmpty ? court.nameAr : court.nameEn)
                  : (court.nameEn.isNotEmpty ? court.nameEn : court.nameAr);
            },
            loading: () => '…',
            error: (_, _) => courtId,
          );
        } else {
          courtDisplay = courtId.isNotEmpty ? courtId : '—';
        }
        extraCells.add(
          TicketInfoCell(label: isArabic ? 'الملعب' : 'Court', value: courtDisplay),
        );

      case BookingCategory.shift:
        extraCells.add(
          TicketInfoCell(
            label: isArabic ? 'الوردية' : 'Shift',
            value: _shiftTypeLabel(d['shift_type']?.toString() ?? '', isArabic),
          ),
        );

      case BookingCategory.venueSeat:
        final row = d['row']?.toString() ?? '';
        final seat = d['seat']?.toString() ?? '';
        final seatLabel = (row.isEmpty && seat.isEmpty) ? '—' : '$row$seat';
        final tier = (d['tier_key'] ?? d['tier_id'])?.toString() ?? '—';
        extraCells.addAll([
          TicketInfoCell(
            label: isArabic ? 'المقعد' : 'Seat',
            value: seatLabel,
          ),
          TicketInfoCell(
            label: isArabic ? 'الدرجة' : 'Tier',
            value: tier,
          ),
        ]);

      case BookingCategory.reservation:
        extraCells.add(
          TicketInfoCell(
            label: isArabic ? 'عدد الأشخاص' : 'Party Size',
            value: d['party_size']?.toString() ?? '—',
          ),
        );

      case BookingCategory.membership:
        break;
    }

    final cells = <TicketInfoCell>[
      TicketInfoCell(
        label: isArabic ? 'التاريخ' : 'Date',
        value: _date(booking.startsAt),
      ),
      TicketInfoCell(
        label: isArabic ? 'الوقت' : 'Time',
        value: _time(booking.startsAt),
      ),
      TicketInfoCell(
        label: isArabic ? 'المبلغ' : 'Amount',
        value: _amount(booking.amountIqd),
      ),
      ...extraCells,
    ];

    return _TicketScreen(
      qrToken: booking.qrToken,
      displayName: name,
      isArabic: isArabic,
      buildStatusBadge: () => TicketStatusBadge.booking(
        status: booking.status,
        isArabic: isArabic,
      ),
      cells: cells,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Membership detail
// ─────────────────────────────────────────────────────────────────────────────

class _MembershipDetail extends ConsumerWidget {
  const _MembershipDetail({required this.membershipId});
  final String membershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMemberships = ref.watch(userMembershipsProvider);
    return asyncMemberships.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBody(
        message: e.toString(),
        onRetry: () => ref.invalidate(userMembershipsProvider),
      ),
      data: (memberships) {
        final match = memberships.where((m) => m.id == membershipId).toList();
        if (match.isEmpty) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          return Center(
            child: Text(
              isArabic ? 'العضوية غير موجودة' : 'Membership not found.',
            ),
          );
        }
        return _MembershipDetailBody(membership: match.first);
      },
    );
  }
}

class _MembershipDetailBody extends StatelessWidget {
  const _MembershipDetailBody({required this.membership});
  final Membership membership;

  static String _date(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String _amount(int iqd) => '${NumberFormat('#,##0').format(iqd)} IQD';

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayName = membership.membershipType.isNotEmpty
        ? membership.membershipType
        : (isArabic ? 'عضوية' : 'Membership');

    final cells = [
      TicketInfoCell(
        label: isArabic ? 'صالح من' : 'Valid From',
        value: _date(membership.startsAt),
      ),
      TicketInfoCell(
        label: isArabic ? 'صالح حتى' : 'Valid Until',
        value: _date(membership.endsAt),
      ),
      TicketInfoCell(
        label: isArabic ? 'المبلغ' : 'Amount',
        value: _amount(membership.amountIqd),
      ),
    ];

    return _TicketScreen(
      qrToken: membership.qrToken,
      displayName: displayName,
      isArabic: isArabic,
      buildStatusBadge: () => TicketStatusBadge.membership(
        status: membership.status,
        isArabic: isArabic,
      ),
      cells: cells,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  On-screen ticket: the card + a "Share Ticket" button
// ─────────────────────────────────────────────────────────────────────────────

class _TicketScreen extends StatefulWidget {
  const _TicketScreen({
    required this.qrToken,
    required this.displayName,
    required this.isArabic,
    required this.buildStatusBadge,
    required this.cells,
  });

  final String qrToken;
  final String displayName;
  final bool isArabic;
  final Widget Function() buildStatusBadge;
  final List<TicketInfoCell> cells;

  @override
  State<_TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<_TicketScreen> {
  final ShareService _share = ShareService();
  bool _sharing = false;

  Future<void> _onShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final png = await _share.renderToPng(
        context,
        ShareableTicketVisualCard(
          qrToken: widget.qrToken,
          displayName: widget.displayName,
          isArabic: widget.isArabic,
          statusBadge: widget.buildStatusBadge(),
          cells: widget.cells,
        ),
        isAr: widget.isArabic,
        delay: const Duration(milliseconds: 300),
      );
      if (!mounted) return;
      await _share.shareImage(
        context,
        png,
        caption: ticketShareCaption(
          name: widget.displayName,
          isAr: widget.isArabic,
        ),
        fileName: 'wensa_ticket.png',
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic ? 'تعذّرت المشاركة' : 'Couldn\'t share',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        children: [
          TicketVisualCard(
            qrToken: widget.qrToken,
            displayName: widget.displayName,
            isArabic: widget.isArabic,
            statusBadge: widget.buildStatusBadge(),
            cells: widget.cells,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sharing ? null : _onShare,
              icon: _sharing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(CupertinoIcons.share, size: 20),
              label: Text(
                _sharing
                    ? (widget.isArabic ? 'جارٍ التحضير…' : 'Preparing…')
                    : (widget.isArabic ? 'مشاركة التذكرة' : 'Share Ticket'),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Error body
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
