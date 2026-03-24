// lib/bottom_bar/widgets/nav_shell.dart
//
// Thin entry-point used by the router.
// Delegates to the platform-specific shell.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/bottom_bar/widgets/android_nav_shell.dart';
import 'package:future_riverpod/features/bottom_bar/widgets/ios_nav_shell.dart';
import 'package:go_router/go_router.dart';

class NavShell extends ConsumerWidget {
  const NavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Platform.isIOS
        ? IosNavShell(navigationShell: navigationShell)
        : AndroidNavShell(navigationShell: navigationShell);
  }
}
