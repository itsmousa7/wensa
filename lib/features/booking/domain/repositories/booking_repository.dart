import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/court.dart';
import 'package:future_riverpod/features/booking/domain/models/event_tier.dart';
import 'package:future_riverpod/features/booking/domain/models/farm_shift.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';
import 'package:future_riverpod/features/booking/domain/models/restaurant_seating_option.dart';
import 'package:future_riverpod/features/booking/domain/models/seat.dart';
import 'package:future_riverpod/features/booking/domain/models/slot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'booking_repository.g.dart';

class BookingRepository {
  const BookingRepository(this._client);
  final SupabaseClient _client;

  Future<List<Booking>> fetchUserBookings({BookingCategory? category}) async {
    var query = _client.from('bookings').select();
    if (category != null) {
      query = query.eq('category', category.name);
    }
    final data = await query.order('created_at', ascending: false);
    return data.map(Booking.fromJson).toList();
  }

  Future<Booking> fetchBooking(String id) async {
    final data = await _client.from('bookings').select().eq('id', id).single();
    return Booking.fromJson(data);
  }

  Future<List<Membership>> fetchUserMemberships() async {
    final data = await _client
        .from('memberships')
        .select()
        .order('created_at', ascending: false);
    return data.map(Membership.fromJson).toList();
  }

  Future<List<Court>> fetchCourts(String placeId) async {
    final data = await _client
        .from('courts')
        .select()
        .eq('place_id', placeId)
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return data.map(Court.fromJson).toList();
  }

  Future<List<Slot>> fetchAvailableSlots({
    required String courtId,
    required String date,
  }) async {
    final data = await _client.schema('bookings').rpc(
      'available_slots',
      params: {'court_id': courtId, 'date': date},
    );
    return (data as List).map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FarmShift>> fetchFarmShifts(String placeId) async {
    final data = await _client.from('farm_shifts').select().eq('place_id', placeId);
    return data.map(FarmShift.fromJson).toList();
  }

  Future<List<EventTier>> fetchEventTiers(String eventId) async {
    final data = await _client
        .from('event_tiers')
        .select()
        .eq('event_id', eventId)
        .order('sort_order', ascending: true);
    return data.map(EventTier.fromJson).toList();
  }

  Future<List<Seat>> fetchAvailableSeats(String eventId) async {
    final data = await _client.schema('bookings').rpc(
      'available_seats',
      params: {'event_id': eventId},
    );
    return (data as List).map((e) => Seat.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MembershipPlan>> fetchMembershipPlans(String placeId) async {
    final data = await _client
        .from('membership_plans')
        .select()
        .eq('place_id', placeId)
        .eq('is_active', true)
        .order('duration_days', ascending: true);
    return data.map(MembershipPlan.fromJson).toList();
  }

  Future<List<RestaurantSeatingOption>> fetchSeatingOptions(String placeId) async {
    final data = await _client
        .from('restaurant_seating_options')
        .select()
        .eq('place_id', placeId)
        .eq('is_active', true);
    return data.map(RestaurantSeatingOption.fromJson).toList();
  }

  Future<void> cancelBooking(String id) async {
    await _client.schema('bookings').rpc('cancel_booking', params: {'id': id});
  }

  Future<void> freezeMembership(String id) async {
    await _client.schema('bookings').rpc('freeze_membership', params: {'id': id});
  }

  Future<void> resumeMembership(String id) async {
    await _client.schema('bookings').rpc('resume_membership', params: {'id': id});
  }
}

@riverpod
BookingRepository bookingRepository(Ref ref) =>
    BookingRepository(Supabase.instance.client);
