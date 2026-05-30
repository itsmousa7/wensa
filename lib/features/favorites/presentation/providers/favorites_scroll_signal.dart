import 'package:flutter_riverpod/flutter_riverpod.dart';

class _Counter extends Notifier<int> {
  @override
  int build() => 0;
  void trigger() => state++;
}

final favoritesScrollToTopProvider =
    NotifierProvider<_Counter, int>(_Counter.new);
