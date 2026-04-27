import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hold_provider.g.dart';

@riverpod
class HoldCountdown extends _$HoldCountdown {
  Timer? _timer;

  @override
  int build(String holdUntil) {
    final expiresAt = DateTime.parse(holdUntil).toLocal();
    final remaining =
        expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final secs = expiresAt.difference(DateTime.now()).inSeconds;
      if (secs <= 0) {
        state = 0;
        _timer?.cancel();
      } else {
        state = secs;
      }
    });

    ref.onDispose(() => _timer?.cancel());
    return remaining;
  }
}
