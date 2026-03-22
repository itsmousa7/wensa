import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_scroll_controller.g.dart';

// BUG FIX: isAutoDispose: true (the default) means the ScrollController is
// destroyed whenever the provider loses its last listener. On Android this
// happens during navigation — pushing PlaceDetailsPage removes the HomePage
// from the active widget tree, which disposes the provider, which calls
// ScrollController.dispose().  When the user pops back, a brand-new
// controller is created at position 0, causing a visible jump AND a
// "ScrollController not attached to any scroll views" exception during
// the transition animation.
//
// FIX: keepAlive: true — the controller lives for the whole app session,
// mirroring the lifetime of the StatefulShellRoute branch that owns it.
@Riverpod(keepAlive: true)
ScrollController homeScrollController(Ref ref) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
}
