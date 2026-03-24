// lib/features/places/presentation/providers/place_details_notifier.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/places/domain/repositories/place_details_repository.dart';

part 'place_app_bar_state.g.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class PlaceAppBarDetailsState {
  const PlaceAppBarDetailsState({
    this.appBarCollapsed = false,
    this.descExpanded = false,
    this.currentImageIndex = 0,
  });

  final bool appBarCollapsed;
  final bool descExpanded;
  final int currentImageIndex;

  PlaceAppBarDetailsState copyWith({
    bool? appBarCollapsed,
    bool? descExpanded,
    int? currentImageIndex,
  }) => PlaceAppBarDetailsState(
    appBarCollapsed: appBarCollapsed ?? this.appBarCollapsed,
    descExpanded: descExpanded ?? this.descExpanded,
    currentImageIndex: currentImageIndex ?? this.currentImageIndex,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

@riverpod
class PlaceAppbarState extends _$PlaceAppbarState {
  static const double _collapseAt = 380 - kToolbarHeight;

  @override
  PlaceAppBarDetailsState build(String placeId) =>
      const PlaceAppBarDetailsState();

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
    ref
        .read(placeDetailsRepositoryProvider)
        .recordView(placeId, userId)
        .ignore();
  }
}
