enum BookingCategory { padel, football, farm, concert, restaurant }

enum BookingStatus { pending, confirmed, completed, cancelled, expired, noShow, used }


enum FarmShiftType { day, night, full }

enum MembershipStatus { active, frozen, expired, cancelled, used }

enum SeatStatus { free, held, taken }

extension BookingCategoryFromString on BookingCategory {
  static BookingCategory fromString(String value) {
    switch (value) {
      case 'padel':
        return BookingCategory.padel;
      case 'football':
        return BookingCategory.football;
      case 'farm':
        return BookingCategory.farm;
      case 'concert':
        return BookingCategory.concert;
      case 'restaurant':
        return BookingCategory.restaurant;
      default:
        return BookingCategory.padel;
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
        return MembershipStatus.active;
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
