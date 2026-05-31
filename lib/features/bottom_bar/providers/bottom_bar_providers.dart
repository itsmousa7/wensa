import 'package:flutter_riverpod/flutter_riverpod.dart';

class _BottomBarHidden extends Notifier<bool> {
  @override
  bool build() => false;
  void hide() => state = true;
  void show() => state = false;
}

/// Controls bottom nav bar visibility. Hide it when an overlay (e.g. in-app
/// browser sheet) is open; restore it when the overlay is dismissed.
final bottomBarHiddenProvider =
    NotifierProvider<_BottomBarHidden, bool>(_BottomBarHidden.new);
