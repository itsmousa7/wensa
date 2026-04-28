// lib/features/bookings_history/presentation/widgets/ticket_status_badge.dart

import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';

class TicketStatusBadge extends StatelessWidget {
  TicketStatusBadge.booking({
    super.key,
    required BookingStatus status,
  })  : _label = _labelFromBooking(status),
        _color = _colorFromBooking(status);

  TicketStatusBadge.membership({
    super.key,
    required MembershipStatus status,
  })  : _label = _labelFromMembership(status),
        _color = _colorFromMembership(status);

  final String _label;
  final Color _color;

  static String _labelFromBooking(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
      case BookingStatus.noShow:
        return 'No Show';
      case BookingStatus.used:
        return 'Used';
    }
  }

  static Color _colorFromBooking(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.completed:
      case BookingStatus.used:
        return Colors.grey;
      case BookingStatus.cancelled:
      case BookingStatus.expired:
      case BookingStatus.noShow:
        return Colors.red;
    }
  }

  static String _labelFromMembership(MembershipStatus s) {
    switch (s) {
      case MembershipStatus.active:
        return 'Active';
      case MembershipStatus.frozen:
        return 'Frozen';
      case MembershipStatus.expired:
        return 'Expired';
      case MembershipStatus.cancelled:
        return 'Cancelled';
      case MembershipStatus.used:
        return 'Used';
    }
  }

  static Color _colorFromMembership(MembershipStatus s) {
    switch (s) {
      case MembershipStatus.active:
        return Colors.green;
      case MembershipStatus.frozen:
        return Colors.blue;
      case MembershipStatus.expired:
      case MembershipStatus.cancelled:
        return Colors.red;
      case MembershipStatus.used:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
