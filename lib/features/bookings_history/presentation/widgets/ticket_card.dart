// lib/features/bookings_history/presentation/widgets/ticket_card.dart

import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_status_badge.dart';
import 'package:intl/intl.dart';

/// Displays a booking or membership as a list card.
///
/// Exactly one of [booking] or [membership] must be non-null.
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (booking != null) {
      final b = booking!;
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: cs.surfaceContainerHighest,
            child: Icon(_categoryIcon(b.category), color: cs.primary, size: 20),
          ),
          title: Text(
            _formatDate(b.startsAt),
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                TicketStatusBadge.booking(status: b.status),
                const SizedBox(width: 8),
                Text(
                  '${b.amountIqd} IQD',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    final m = membership!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.surfaceContainerHighest,
          child: Icon(Icons.fitness_center, color: cs.primary, size: 20),
        ),
        title: Text(
          m.membershipType.isNotEmpty ? m.membershipType : 'Membership',
          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              TicketStatusBadge.membership(status: m.status),
              const SizedBox(width: 8),
              Text(
                '${m.amountIqd} IQD',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: cs.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
