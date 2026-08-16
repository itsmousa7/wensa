enum BookingCategory { hourly, shift, reservation, venueSeat, membership }

/// `wayl` is historical-only — it records bookings paid through Wayl while it
/// was the PSP (2026-07-31 → 2026-08-16) and is never sent for a new booking.
enum PaymentMethod { wayl, cash, hyperpay }

enum BookingStatus { pending, confirmed, completed, cancelled, expired, noShow, used }


enum FarmShiftType { day, night, full }

enum MembershipStatus { pending, active, frozen, expired, cancelled, used }

enum SeatStatus { free, held, taken }

extension BookingCategoryFromString on BookingCategory {
  static BookingCategory fromString(String value) {
    switch (value) {
      case 'sports':
        return BookingCategory.hourly;
      case 'farm':
        return BookingCategory.shift;
      case 'restaurant':
        return BookingCategory.reservation;
      case 'concert':
        return BookingCategory.venueSeat;
      case 'membership':
        return BookingCategory.membership;
      default:
        return BookingCategory.hourly;
    }
  }
}

extension BookingStatusFromString on BookingStatus {
  static BookingStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'expired':
        return BookingStatus.expired;
      case 'no_show':
        return BookingStatus.noShow;
      case 'used':
        return BookingStatus.used;
      default:
        return BookingStatus.pending;
    }
  }
}

extension FarmShiftTypeFromString on FarmShiftType {
  static FarmShiftType fromString(String value) {
    switch (value) {
      case 'day':
        return FarmShiftType.day;
      case 'night':
        return FarmShiftType.night;
      case 'full':
        return FarmShiftType.full;
      default:
        return FarmShiftType.day;
    }
  }
}

extension MembershipStatusFromString on MembershipStatus {
  static MembershipStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return MembershipStatus.pending;
      case 'active':
        return MembershipStatus.active;
      case 'frozen':
        return MembershipStatus.frozen;
      case 'expired':
        return MembershipStatus.expired;
      case 'cancelled':
        return MembershipStatus.cancelled;
      case 'used':
        return MembershipStatus.used;
      default:
        // Unknown values must NEVER be treated as 'active' — that would grant
        // service to an unverified row. Default to 'pending' so the membership
        // stays invisible/unusable until something explicitly activates it.
        return MembershipStatus.pending;
    }
  }
}

extension PaymentMethodFromString on PaymentMethod {
  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'hyperpay':
        return PaymentMethod.hyperpay;
      case 'wayl':
        return PaymentMethod.wayl;
      default:
        // Unknown values fall back to `wayl`, which renders as "E-Payment".
        // Never default to `cash` — that means "no money collected yet", so an
        // unpaid booking would show as awaiting cash at the venue.
        return PaymentMethod.wayl;
    }
  }
}

extension SeatStatusFromString on SeatStatus {
  static SeatStatus fromString(String value) {
    switch (value) {
      case 'free':
        return SeatStatus.free;
      case 'held':
        return SeatStatus.held;
      case 'taken':
        return SeatStatus.taken;
      default:
        return SeatStatus.free;
    }
  }
}
