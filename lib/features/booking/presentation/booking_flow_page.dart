import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/presentation/sections/concert_section.dart';
import 'package:future_riverpod/features/booking/presentation/sections/farm_section.dart';
import 'package:future_riverpod/features/booking/presentation/sections/membership_section.dart';
import 'package:future_riverpod/features/booking/presentation/sections/padel_section.dart';
import 'package:future_riverpod/features/booking/presentation/sections/restaurant_section.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';

class BookingFlowPage extends ConsumerWidget {
  const BookingFlowPage({
    super.key,
    required this.placeId,
    this.eventId,
    this.category,
  });

  final String placeId;
  final String? eventId;
  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeDetailsProvider(placeId));

    return Scaffold(
      appBar: AppBar(
        title: placeAsync.maybeWhen(
          data: (place) => Text(
            place.nameEn.isNotEmpty ? place.nameEn : place.nameAr,
          ),
          orElse: () => const Text('Book'),
        ),
      ),
      body: placeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (place) {
          final placeName =
              place.nameEn.isNotEmpty ? place.nameEn : place.nameAr;

          if (category == 'gym' || category == 'membership') {
            return MembershipSection(placeId: placeId, placeName: placeName);
          }

          if (category == 'farm') {
            return FarmSection(placeId: placeId, placeName: placeName);
          }

          if (category == 'restaurant') {
            return RestaurantSection(
                placeId: placeId, placeName: placeName);
          }

          if (category == 'concert' ||
              (category == null && eventId != null)) {
            final eid = eventId ?? '';
            if (eid.isNotEmpty) {
              return ConcertSection(eventId: eid);
            }
          }

          if (category == 'padel' || category == 'football') {
            return PadelSection(placeId: placeId);
          }

          // Fallback: if no category param, check placeId
          if (placeId.isEmpty) {
            return const Center(child: Text('Coming soon'));
          }

          // Default to padel for backwards compatibility
          return PadelSection(placeId: placeId);
        },
      ),
    );
  }
}
