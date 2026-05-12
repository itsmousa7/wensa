// lib/features/bookings_history/presentation/pages/ticket_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/qr_block.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_status_badge.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Layout constants
// ─────────────────────────────────────────────────────────────────────────────

/// Approximate height of the details top section (name + badge + info grid).
/// name ~28 + gap 10 + badge ~26 + gap 20 + grid ~137 + vPadding 48.
const double _kTopHeight = 270.0;

/// Half-height of the tear-line strip.
const double _kTearHalf = 14.0;

/// Radius of the semicircle notches on each side of the tear line.
const double _kNotchRadius = 14.0;

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isMembership
              ? (isArabic ? 'العضوية' : 'Membership')
              : (isArabic ? 'تفاصيل الحجز' : 'Booking Details'),
          style: Theme.of(context).textTheme.titleLarge,
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

  static String _amount(int iqd) =>
      '${NumberFormat('#,##0').format(iqd)} IQD';

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
    final extraCells = <_InfoCell>[];

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
        extraCells.add(_InfoCell(
          label: isArabic ? 'الملعب' : 'Court',
          value: courtDisplay,
        ));

      case BookingCategory.shift:
        extraCells.add(_InfoCell(
          label: isArabic ? 'الوردية' : 'Shift',
          value: d['shift_type']?.toString() ?? '—',
        ));

      case BookingCategory.venueSeat:
        extraCells.addAll([
          _InfoCell(
            label: isArabic ? 'المقعد' : 'Seat',
            value: d['seat_id']?.toString() ?? '—',
          ),
          _InfoCell(
            label: isArabic ? 'الدرجة' : 'Tier',
            value: d['tier_id']?.toString() ?? '—',
          ),
        ]);

      case BookingCategory.reservation:
        extraCells.add(_InfoCell(
          label: isArabic ? 'عدد الأشخاص' : 'Party Size',
          value: d['party_size']?.toString() ?? '—',
        ));

      case BookingCategory.membership:
        break;
    }

    final cells = <_InfoCell>[
      _InfoCell(label: isArabic ? 'التاريخ' : 'Date', value: _date(booking.startsAt)),
      _InfoCell(label: isArabic ? 'الوقت' : 'Time', value: _time(booking.startsAt)),
      _InfoCell(label: isArabic ? 'المبلغ' : 'Amount', value: _amount(booking.amountIqd)),
      ...extraCells,
    ];

    return _TicketBody(
      qrToken: booking.qrToken,
      displayName: name,
      isArabic: isArabic,
      statusBadge: TicketStatusBadge.booking(status: booking.status, isArabic: isArabic),
      cells: cells,
      paymentId: booking.paymentId,
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
            child: Text(isArabic ? 'العضوية غير موجودة' : 'Membership not found.'),
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

  static String _amount(int iqd) =>
      '${NumberFormat('#,##0').format(iqd)} IQD';

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayName = membership.membershipType.isNotEmpty
        ? membership.membershipType
        : (isArabic ? 'عضوية' : 'Membership');

    final cells = [
      _InfoCell(
        label: isArabic ? 'صالح من' : 'Valid From',
        value: _date(membership.startsAt),
      ),
      _InfoCell(
        label: isArabic ? 'صالح حتى' : 'Valid Until',
        value: _date(membership.endsAt),
      ),
      _InfoCell(
        label: isArabic ? 'المبلغ' : 'Amount',
        value: _amount(membership.amountIqd),
      ),
    ];

    return _TicketBody(
      qrToken: membership.qrToken,
      displayName: displayName,
      isArabic: isArabic,
      statusBadge: TicketStatusBadge.membership(status: membership.status, isArabic: isArabic),
      cells: cells,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Ticket body — the visual ticket card UI
// ─────────────────────────────────────────────────────────────────────────────

class _TicketBody extends StatefulWidget {
  const _TicketBody({
    required this.qrToken,
    required this.displayName,
    required this.isArabic,
    required this.statusBadge,
    required this.cells,
    this.paymentId,
  });

  final String qrToken;
  final String displayName;
  final bool isArabic;
  final Widget statusBadge;
  final List<_InfoCell> cells;
  final String? paymentId;

  @override
  State<_TicketBody> createState() => _TicketBodyState();
}

class _TicketBodyState extends State<_TicketBody> {
  // GlobalKey on the top-section Padding so we can measure its actual height.
  final _topKey = GlobalKey();

  // Start with the estimated value; updated after first layout.
  double _tearLineY = _kTopHeight + _kTearHalf;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTearLine());
  }

  void _updateTearLine() {
    final ctx = _topKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final actual = box.size.height + _kTearHalf;
    if ((actual - _tearLineY).abs() > 0.5) {
      setState(() => _tearLineY = actual);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;

    // Notch is centered at the actual top-section height + half tear-line.
    final tearLineY = _tearLineY;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Container(
        // Shadow lives outside the clip so it renders around the full card.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipPath(
          clipper: _TicketClipper(tearLineY),
          child: Container(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top: booking info ───────────────────────────────────────
                Padding(
                  key: _topKey,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      widget.statusBadge,
                      const SizedBox(height: 20),
                      _InfoGrid(cells: widget.cells),
                      if (widget.paymentId != null && widget.paymentId!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                        _ReferenceRow(paymentId: widget.paymentId!, isArabic: widget.isArabic),
                      ],
                    ],
                  ),
                ),

                // ── Tear line ───────────────────────────────────────────────
                _TearLine(color: cs.onSurface.withValues(alpha: 0.18)),

                // ── Bottom: QR section ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    children: [
                      Text(
                        widget.isArabic ? 'امسح رمز QR' : 'Scan This QR',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isArabic
                            ? 'وجّه الكاميرا إلى مكان المسح'
                            : 'Point This QR To The Scan Place',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: widget.qrToken.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: QrBlock(qrToken: widget.qrToken),
                              )
                            : SizedBox(
                                width: 232,
                                height: 232,
                                child: Icon(
                                  Icons.qr_code_rounded,
                                  size: 120,
                                  color: cs.onSurface.withValues(alpha: 0.15),
                                ),
                              ),
                      ),
                    ],
                  ),
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
//  Tear line — dashed horizontal rule
// ─────────────────────────────────────────────────────────────────────────────

class _TearLine extends StatelessWidget {
  const _TearLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kTearHalf * 2,
      child: CustomPaint(
        painter: _DashPainter(color: color),
        size: const Size(double.infinity, _kTearHalf * 2),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 9.0;
    const gapWidth = 7.0;
    final y = size.height / 2;
    // Draw edge-to-edge; the ClipPath notches mask the ends naturally.
    double x = 4.0;
    while (x < size.width - 4) {
      final end = (x + dashWidth).clamp(0.0, size.width - 4.0);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Ticket shape clipper — rounded rect with inward semicircle notches
// ─────────────────────────────────────────────────────────────────────────────

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper(this.tearLineY);

  /// Y position of the notch center (midpoint of the tear-line strip).
  final double tearLineY;

  @override
  Path getClip(Size size) {
    const r = 24.0; // card corner radius
    const nr = _kNotchRadius; // notch radius
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      // top-right corner
      ..arcToPoint(Offset(w, r),
          radius: const Radius.circular(r), clockwise: true)
      // right edge → notch top
      ..lineTo(w, tearLineY - nr)
      // right inward notch (counterclockwise = curves into the card)
      ..arcToPoint(Offset(w, tearLineY + nr),
          radius: const Radius.circular(nr), clockwise: false)
      // right edge → bottom
      ..lineTo(w, h - r)
      // bottom-right corner
      ..arcToPoint(Offset(w - r, h),
          radius: const Radius.circular(r), clockwise: true)
      ..lineTo(r, h)
      // bottom-left corner
      ..arcToPoint(Offset(0, h - r),
          radius: const Radius.circular(r), clockwise: true)
      // left edge → notch bottom
      ..lineTo(0, tearLineY + nr)
      // left inward notch (counterclockwise = curves into the card)
      ..arcToPoint(Offset(0, tearLineY - nr),
          radius: const Radius.circular(nr), clockwise: false)
      // left edge → top
      ..lineTo(0, r)
      // top-left corner
      ..arcToPoint(Offset(r, 0),
          radius: const Radius.circular(r), clockwise: true)
      ..close();
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.tearLineY != tearLineY;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Info grid — 2-column pairs
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCell {
  const _InfoCell({required this.label, required this.value});
  final String label;
  final String value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.cells});
  final List<_InfoCell> cells;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    // Group into rows of 2
    final rows = <List<_InfoCell>>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add([
        cells[i],
        if (i + 1 < cells.length) cells[i + 1],
      ]);
    }

    return Column(
      children: List.generate(rows.length, (ri) {
        final row = rows[ri];
        return Column(
          children: [
            if (ri > 0)
              Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: row.map((cell) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell.label,
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cell.value,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reference row — shows Wayl transaction ID with tap-to-copy
// ─────────────────────────────────────────────────────────────────────────────

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.paymentId, required this.isArabic});

  final String paymentId;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final mutedColor = cs.onSurface.withValues(alpha: 0.55);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: paymentId));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم النسخ' : 'Copied!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Text(
              isArabic ? 'المرجع' : 'Reference',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                paymentId,
                style: tt.bodySmall?.copyWith(color: mutedColor),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.copy_rounded, size: 16, color: mutedColor),
          ],
        ),
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
            Icon(Icons.error_outline_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
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
