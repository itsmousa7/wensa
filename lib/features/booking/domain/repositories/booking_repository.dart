import 'package:future_riverpod/features/booking/domain/models/booking.dart';
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

  Future<List<Booking>> fetchUserBookings({List<String>? categories}) async {
    // Only surface paid bookings. Pending rows are either in-flight (user is in
    // the payment webview) or abandoned (user cancelled / closed the sheet);
    // either way they don't represent a real reservation and must not appear
    // in history — otherwise staff could grant service against an unpaid row.
    var query = _client
        .schema('bookings')
        .from('bookings')
        .select()
        .eq('payment_status', 'paid');
    if (categories != null && categories.isNotEmpty) {
      query = query.inFilter('category', categories);
    }
    final data = await query.order('created_at', ascending: false);
    return data.map(Booking.fromJson).toList();
  }

  Future<Booking> fetchBooking(String id) async {
    final data = await _client.schema('bookings').from('bookings').select().eq('id', id).single();
    return Booking.fromJson(data);
  }

  Future<List<Membership>> fetchUserMemberships() async {
    // create_membership inserts the row with status='pending' and
    // payment_status='pending'; the row only becomes 'active' on a successful
    // payment confirmation. Gate strictly on payment_status='paid' so that
    // abandoned/cancelled payment attempts never surface in history and the
    // status default never accidentally grants service.
    final data = await _client
        .schema('bookings')
        .from('memberships')
        .select()
        .eq('payment_status', 'paid')
        .order('created_at', ascending: false);
    return data.map(Membership.fromJson).toList();
  }

  Future<List<Court>> fetchCourts(String placeId) async {
    final courtsData = await _client
        .schema('bookings')
        .from('courts')
        .select()
        .eq('place_id', placeId)
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    final pricingData = await _client
        .schema('bookings')
        .from('place_pricing')
        .select()
        .eq('place_id', placeId);

    final pricing = (pricingData as List).cast<Map<String, dynamic>>();

    return courtsData.map((courtJson) {
      final courtId = courtJson['id'] as String;
      final courtRate = pricing
          .where((p) => p['court_id'] == courtId)
          .firstOrNull;
      final placeRate = pricing
          .where((p) => p['court_id'] == null)
          .firstOrNull;
      final rate = ((courtRate ?? placeRate)?['hourly_rate_iqd'] as num?)?.toDouble() ?? 0.0;
      return Court.fromJson({...courtJson, 'price_per_hour': rate});
    }).toList();
  }

  Future<List<Slot>> fetchAvailableSlots({
    required String courtId,
    required String date,
  }) async {
    final data = await _client.schema('bookings').rpc(
      'available_slots',
      params: {'p_court_id': courtId, 'p_date': date},
    );
    return (data as List).map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FarmShift>> fetchFarmShifts(String placeId, String date) async {
    final data = await _client.schema('bookings').rpc(
      'available_farm_shifts',
      params: {'p_place_id': placeId, 'p_date': date},
    );
    return (data as List)
        .map((e) => FarmShift.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> fetchClosedDates({
    required String placeId,
    required String startDate,
    required String endDate,
  }) async {
    final data = await _client.schema('bookings').rpc(
      'place_closed_dates',
      params: {
        'p_place_id': placeId,
        'p_start_date': startDate,
        'p_end_date': endDate,
      },
    );
    return (data as List).map((e) => e.toString().substring(0, 10)).toSet();
  }

  Future<List<EventTier>> fetchEventTiers(String eventId) async {
    final data = await _client
        .schema('bookings')
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
        .schema('bookings')
        .from('membership_plans')
        .select()
        .eq('place_id', placeId)
        .eq('is_active', true)
        .order('duration_days', ascending: true);
    return data.map(MembershipPlan.fromJson).toList();
  }

  Future<List<RestaurantSeatingOption>> fetchSeatingOptions(String placeId) async {
    final data = await _client
        .schema('bookings')
        .from('restaurant_seating_options')
        .select()
        .eq('place_id', placeId)
        .eq('is_active', true);
    return data.map(RestaurantSeatingOption.fromJson).toList();
  }

  Future<void> confirmPayment(String bookingId, String paymentId) async {
    await _client.rpc('confirm_payment', params: {
      'p_booking_id': bookingId,
      if (paymentId.isNotEmpty) 'p_payment_id': paymentId,
    });
  }

  Future<void> confirmMembershipPayment(
      String membershipId, String paymentId) async {
    await _client.rpc('confirm_membership_payment', params: {
      'p_membership_id': membershipId,
      if (paymentId.isNotEmpty) 'p_payment_id': paymentId,
    });
  }

  Future<void> cancelBooking(String id) async {
    await _client.schema('bookings').rpc('cancel_booking', params: {'id': id});
  }

  Future<void> cancelMembership(String id) async {
    await _client.schema('bookings').rpc('cancel_membership', params: {'p_id': id});
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
