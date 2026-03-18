// lib/features/events/domain/repositories/events_repository.dart
//
// Single source of truth for all event-related Supabase calls.
// Mirrors the pattern used in PlaceDetailsRepository.

import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'events_repository.g.dart';

class EventsRepository {
  const EventsRepository(this._client);
  final SupabaseClient _client;

  /// Fetches the full event row by [eventId].
  Future<EventModel> fetchEvent(String eventId) async {
    final data = await _client
        .from('events')
        .select()
        .eq('id', eventId)
        .single();
    return EventModel.fromJson(data);
  }

  /// Records an event view (deduplication handled server-side).
  /// Silently ignores failures — a missing view is not fatal.
  Future<void> recordView(String eventId, String userId) async {
    try {
      await _client.rpc(
        'record_event_view',
        params: {'p_event_id': eventId, 'p_user_id': userId},
      );
    } catch (_) {
      // View recording is best-effort; never surface errors to the user.
    }
  }
}

@riverpod
EventsRepository eventsRepository(Ref ref) =>
    EventsRepository(Supabase.instance.client);
