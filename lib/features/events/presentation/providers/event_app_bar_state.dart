// lib/features/events/presentation/providers/event_app_bar_state.dart
//
// Mirrors PlaceAppBarDetailsState / PlaceAppbarState exactly.
// Controls collapsed state, description expansion, and image carousel index
// for the EventDetailsPage.

import 'package:flutter/material.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/events/domain/repositories/events_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_app_bar_state.g.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class EventAppBarDetailsState {
  const EventAppBarDetailsState({
    this.appBarCollapsed = false,
    this.descExpanded = false,
    this.currentImageIndex = 0,
  });

  final bool appBarCollapsed;
  final bool descExpanded;
  final int currentImageIndex;

  EventAppBarDetailsState copyWith({
    bool? appBarCollapsed,
    bool? descExpanded,
    int? currentImageIndex,
  }) => EventAppBarDetailsState(
    appBarCollapsed: appBarCollapsed ?? this.appBarCollapsed,
    descExpanded: descExpanded ?? this.descExpanded,
    currentImageIndex: currentImageIndex ?? this.currentImageIndex,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

@riverpod
class EventAppbarState extends _$EventAppbarState {
  // Same collapse threshold as the places page (380px image - toolbar height).
  static const double _collapseAt = 380 - kToolbarHeight;

  @override
  EventAppBarDetailsState build(String eventId) =>
      const EventAppBarDetailsState();

  void onScroll(double offset) {
    final collapsed = offset > _collapseAt;
    if (collapsed != state.appBarCollapsed) {
      state = state.copyWith(appBarCollapsed: collapsed);
    }
  }

  void toggleDesc() =>
      state = state.copyWith(descExpanded: !state.descExpanded);

  void setImageIndex(int i) => state = state.copyWith(currentImageIndex: i);

  void recordView() {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    ref.read(eventsRepositoryProvider).recordView(eventId, userId).ignore();
  }
}
