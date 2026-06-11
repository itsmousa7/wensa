import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/widgets/glass_back_button.dart';
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isEventFlow = eventId != null && eventId!.isNotEmpty;

    // Event-based booking has no placeId — render ConcertSection without
    // fetching place details (which would query Supabase with an empty UUID
    // and fail with 22P02).
    if (isEventFlow) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 72,
          leading: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: GlassBackButton(),
          ),
          title: Text(
            isAr ? 'الحجز' : 'Booking',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        body: ConcertSection(eventId: eventId!),
      );
    }

    final placeAsync = ref.watch(placeDetailsProvider(placeId));

    return Scaffold(
      appBar: AppBar(
        leadingWidth: GlassBackButton.appBarLeadingWidth,
        leading: GlassBackButton.appBarLeading(),
        title: placeAsync.maybeWhen(
          data: (place) {
            final name = isAr
                ? (place.nameAr.isNotEmpty ? place.nameAr : place.nameEn)
                : (place.nameEn.isNotEmpty ? place.nameEn : place.nameAr);
            return Text(
              name,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            );
          },
          orElse: () => Text(
            isAr ? 'الحجز' : 'Booking',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
      body: placeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (place) {
          final placeName = isAr
              ? (place.nameAr.isNotEmpty ? place.nameAr : place.nameEn)
              : (place.nameEn.isNotEmpty ? place.nameEn : place.nameAr);

          // Place-based booking — category comes from content.places.booking_category
          switch (category) {
            case 'hourly':
              return PadelSection(placeId: placeId);
            case 'reservation':
              return RestaurantSection(placeId: placeId, placeName: placeName);
            case 'membership':
              return MembershipSection(placeId: placeId, placeName: placeName);
            case 'shift':
            case 'farm':
              return FarmSection(placeId: placeId, placeName: placeName);
          }

          return const Center(child: Text('Coming Soon'));
        },
      ),
    );
  }
}
