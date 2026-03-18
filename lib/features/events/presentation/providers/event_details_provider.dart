// lib/features/events/presentation/providers/event_details_provider.dart
//
// Provides EventModel for a given eventId.
// Also exposes patchSavesCount for optimistic favorite updates,
// mirroring the same pattern used in PlaceDetails.

import 'package:future_riverpod/features/events/domain/repositories/events_repository.dart';
import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_details_provider.g.dart';

@riverpod
class EventDetails extends _$EventDetails {
  @override
  Future<EventModel> build(String eventId) =>
      ref.watch(eventsRepositoryProvider).fetchEvent(eventId);

  /// Optimistically adjusts savesCount by [delta] (+1 or -1)
  /// without triggering a network re-fetch.
  void patchSavesCount(int delta) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(savesCount: current.savesCount + delta));
  }
}
