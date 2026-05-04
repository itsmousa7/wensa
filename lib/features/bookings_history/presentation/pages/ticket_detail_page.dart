// lib/features/bookings_history/presentation/pages/ticket_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/qr_block.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_status_badge.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:intl/intl.dart';

class TicketDetailPage extends ConsumerWidget {
  const TicketDetailPage({super.key, required this.id});

  final String id;

  bool get _isMembership => id.startsWith('m_');
  String get _rawId => _isMembership ? id.substring(2) : id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          _isMembership ? 'Membership' : 'Booking',
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
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(bookingDetailProvider(bookingId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (booking) => _BookingDetailBody(booking: booking),
    );
  }
}

class _BookingDetailBody extends ConsumerWidget {
  const _BookingDetailBody({required this.booking});

  final Booking booking;

  static IconData _categoryIcon(BookingCategory cat) {
    switch (cat) {
      case BookingCategory.padel:
      case BookingCategory.football:
        return Icons.sports_tennis;
      case BookingCategory.farm:
        return Icons.landscape;
      case BookingCategory.concert:
        return Icons.music_note;
      case BookingCategory.restaurant:
        return Icons.restaurant;
    }
  }

  static String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Resolve place or event name
    final String displayName;
    if (booking.placeId != null && booking.placeId!.isNotEmpty) {
      final placeAsync = ref.watch(placeDetailsProvider(booking.placeId!));
      displayName = placeAsync.when(
        data: (p) => p.nameEn.isNotEmpty ? p.nameEn : p.nameAr,
        loading: () => '...',
        error: (_, _) => booking.category.name.toUpperCase(),
      );
    } else if (booking.eventId != null && booking.eventId!.isNotEmpty) {
      final eventAsync = ref.watch(eventDetailsProvider(booking.eventId!));
      displayName = eventAsync.when(
        data: (e) => e.titleEn.isNotEmpty ? e.titleEn : e.titleAr,
        loading: () => '...',
        error: (_, _) => booking.category.name.toUpperCase(),
      );
    } else {
      displayName = booking.category.name.toUpperCase();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Main ticket card ──────────────────────────────────────────────
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: icon + category + status
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          _categoryIcon(booking.category),
                          color: cs.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: tt.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              booking.category.name.toUpperCase(),
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TicketStatusBadge.booking(status: booking.status),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Date/time
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date & Time',
                    value: _formatDate(booking.startsAt),
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Amount',
                    value: '${booking.amountIqd} IQD',
                  ),
                  const SizedBox(height: 12),

                  // Category-specific data
                  ..._categoryFields(context, booking),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── QR block ──────────────────────────────────────────────────────
          if (booking.qrToken.isNotEmpty) ...[
            Text(
              'Scan to verify',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(child: QrBlock(qrToken: booking.qrToken)),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _categoryFields(BuildContext context, Booking b) {
    final data = b.categoryData;
    switch (b.category) {
      case BookingCategory.padel:
      case BookingCategory.football:
        final courtId = data['court_id']?.toString() ?? '—';
        return [
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Court',
            value: courtId,
          ),
        ];
      case BookingCategory.farm:
        final shiftType = data['shift_type']?.toString() ?? '—';
        return [
          _DetailRow(
            icon: Icons.wb_sunny_outlined,
            label: 'Shift',
            value: shiftType,
          ),
        ];
      case BookingCategory.concert:
        final seatId = data['seat_id']?.toString() ?? '—';
        final tierId = data['tier_id']?.toString() ?? '—';
        return [
          _DetailRow(
            icon: Icons.event_seat_outlined,
            label: 'Seat',
            value: seatId,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.layers_outlined,
            label: 'Tier',
            value: tierId,
          ),
        ];
      case BookingCategory.restaurant:
        final partySize = data['party_size']?.toString() ?? '—';
        return [
          _DetailRow(
            icon: Icons.people_outline,
            label: 'Party Size',
            value: partySize,
          ),
        ];
    }
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
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(userMembershipsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (memberships) {
        final match = memberships.where((m) => m.id == membershipId).toList();
        if (match.isEmpty) {
          return const Center(child: Text('Membership not found.'));
        }
        return _MembershipDetailBody(membership: match.first);
      },
    );
  }
}

class _MembershipDetailBody extends StatelessWidget {
  const _MembershipDetailBody({required this.membership});

  final Membership membership;

  static String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Main ticket card ──────────────────────────────────────────────
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: icon + type + status
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.fitness_center,
                          color: cs.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              membership.membershipType.isNotEmpty
                                  ? membership.membershipType
                                  : 'Membership',
                              style: tt.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'MEMBERSHIP',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TicketStatusBadge.membership(status: membership.status),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Validity range
                  _DetailRow(
                    icon: Icons.date_range_outlined,
                    label: 'Valid From',
                    value: _formatDate(membership.startsAt),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Valid Until',
                    value: _formatDate(membership.endsAt),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Amount',
                    value: '${membership.amountIqd} IQD',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── QR block ──────────────────────────────────────────────────────
          if (membership.qrToken.isNotEmpty) ...[
            Text(
              'Scan to verify',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(child: QrBlock(qrToken: membership.qrToken)),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared detail row
// ─────────────────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
