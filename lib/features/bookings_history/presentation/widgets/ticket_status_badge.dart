// lib/features/bookings_history/presentation/widgets/ticket_status_badge.dart

import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

class TicketStatusBadge extends StatelessWidget {
  const TicketStatusBadge.booking({
    super.key,
    required BookingStatus status,
    this.isArabic = false,
  })  : _bookingStatus = status,
        _membershipStatus = null;

  const TicketStatusBadge.membership({
    super.key,
    required MembershipStatus status,
    this.isArabic = false,
  })  : _membershipStatus = status,
        _bookingStatus = null;

  final BookingStatus? _bookingStatus;
  final MembershipStatus? _membershipStatus;
  final bool isArabic;

  // ── Booking ────────────────────────────────────────────────────────────────

  static String _bookingLabel(BookingStatus s, bool ar) {
    if (ar) {
      switch (s) {
        case BookingStatus.confirmed:
          return 'قادم';
        case BookingStatus.pending:
          return 'قيد الانتظار';
        case BookingStatus.completed:
          return 'مكتمل';
        case BookingStatus.cancelled:
          return 'ملغى';
        case BookingStatus.expired:
          return 'منتهي';
        case BookingStatus.noShow:
          return 'لم يحضر';
        case BookingStatus.used:
          return 'مستخدم';
      }
    }
    switch (s) {
      case BookingStatus.confirmed:
        return 'Upcoming';
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

  static Color _bookingColor(BookingStatus s) {
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

  // ── Membership ─────────────────────────────────────────────────────────────

  static String _membershipLabel(MembershipStatus s, bool ar) {
    if (ar) {
      switch (s) {
        case MembershipStatus.pending:
          return 'قيد الانتظار';
        case MembershipStatus.active:
          return 'نشط';
        case MembershipStatus.frozen:
          return 'مجمّد';
        case MembershipStatus.expired:
          return 'منتهي';
        case MembershipStatus.cancelled:
          return 'ملغى';
        case MembershipStatus.used:
          return 'مستخدم';
      }
    }
    switch (s) {
      case MembershipStatus.pending:
        return 'Pending';
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

  static Color _membershipColor(MembershipStatus s) {
    switch (s) {
      case MembershipStatus.pending:
        return Colors.orange;
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
    final String label;
    final Color color;

    final bs = _bookingStatus;
    if (bs != null) {
      label = _bookingLabel(bs, isArabic);
      color = _bookingColor(bs);
    } else {
      // _membershipStatus is guaranteed non-null when _bookingStatus is null
      // (enforced by the named constructors).
      final ms = _membershipStatus!;
      label = _membershipLabel(ms, isArabic);
      color = _membershipColor(ms);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppSpacing.borderRadiusXL,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
