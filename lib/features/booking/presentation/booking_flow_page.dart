import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/booking/presentation/sections/padel_section.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';

class BookingFlowPage extends ConsumerWidget {
  const BookingFlowPage({super.key, required this.placeId, this.eventId});

  final String placeId;
  final String? eventId;

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
          // For now, always mount PadelSection.
          // Category-based routing will be wired once category IDs are known.
          // The section is appropriate for padel and football venues.
          if (placeId.isEmpty) {
            return const Center(child: Text('Coming soon'));
          }
          return PadelSection(placeId: placeId);
        },
      ),
    );
  }
}
