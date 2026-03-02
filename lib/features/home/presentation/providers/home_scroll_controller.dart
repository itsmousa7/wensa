import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_scroll_controller.g.dart';

@riverpod
ScrollController homeScrollController(Ref ref) {
  return ScrollController();
}
