// lib/core/widgets/detail_error_screen.dart
//
// Reusable full-page error screen for detail pages (EventDetailsPage,
// PlaceDetailsPage, etc.).
//
// Shows:
//   • A back button (always, so users are never trapped)
//   • GlobalErrorWidget (wifi-slash icon + friendly message)
//   • A "Try Again" button that calls [onRetry]
//
// Usage:
//   DetailErrorScreen(
//     isAr: _isAr,
//     onRetry: () => ref.invalidate(myProvider),
//   )

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_appbar_button.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/profile_error.dart';

class DetailErrorScreen extends StatelessWidget {
  const DetailErrorScreen({
    super.key,
    required this.isAr,
    required this.onRetry,
  });

  final bool isAr;

  /// Called when the user taps "Try Again". Typically invalidates the provider.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Stack(
      children: [
        // ── Error body + retry button ────────────────────────────────────
        Column(
          children: [
            Expanded(
              child: GlobalErrorWidget(
                cs: cs,
                isAr: isAr,
                tt: tt,
                onTap: onRetry,
              ),
            ),
          ],
        ),

        // ── Back button — always visible so users are never trapped ───────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: isAr ? null : 20,
          right: isAr ? 20 : null,
          child: PlaceAppBarButton(
            icon: Icon(
              isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
              color: cs.outline,
            ),
            onTap: () => Navigator.pop(context),
            collapsed: true,
            sfSymbol: isAr ? 'chevron.right' : 'chevron.left',
          ),
        ),
      ],
    );
  }
}
