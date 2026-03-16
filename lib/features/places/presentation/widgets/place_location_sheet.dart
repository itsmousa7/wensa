import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  URL helpers — single source of truth for every map deep-link
// ─────────────────────────────────────────────────────────────────────────────

String _googleMapsUrl(double lat, double lng) =>
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

String _wazeUrl(double lat, double lng) =>
    'https://waze.com/ul?ll=$lat,$lng&navigate=yes';

String _appleMapsUrl(double lat, double lng, String name) =>
    'https://maps.apple.com/?q=${Uri.encodeComponent(name)}&ll=$lat,$lng';

Future<void> _launch(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Public entry-point — branches per platform inline (no extra private fns)
// ─────────────────────────────────────────────────────────────────────────────

void showLocationSheet({
  required BuildContext context,
  required double latitude,
  required double longitude,
  required String placeName,
  required bool isAr,
}) {
  if (Platform.isIOS) {
    // ── iOS: CupertinoActionSheet ───────────────────────────────────────
    void popAndLaunch(String url) {
      Navigator.pop(context);
      _launch(url);
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(isAr ? 'افتح الموقع في' : 'Open location in'),
        message: Text(placeName),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () =>
                popAndLaunch(_appleMapsUrl(latitude, longitude, placeName)),
            child: Text(isAr ? 'خرائط آبل' : 'Apple Maps'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => popAndLaunch(_googleMapsUrl(latitude, longitude)),
            child: Text(isAr ? 'خرائط كوكل' : 'Google Maps'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => popAndLaunch(_wazeUrl(latitude, longitude)),
            child: const Text('Waze'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
      ),
    );
  } else {
    // ── Android: Material bottom sheet ─────────────────────────────────
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _AndroidLocationSheet(
        placeName: placeName,
        isAr: isAr,
        apps: [
          _MapApp(
            name: isAr ? 'خرائط جوجل' : 'Google Maps',
            icon: Image.asset('assets/icons/location.png'),

            color: const Color(0xFF4285F4),
            url: _googleMapsUrl(latitude, longitude), // reuses shared helper
          ),
          _MapApp(
            name: 'Waze',
            icon: SizedBox(
              height: 14,
              child: Image.asset('assets/icons/waze.png'),
            ),
            color: const Color(0xFF00C8FF),
            url: _wazeUrl(latitude, longitude), // reuses shared helper
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Android sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AndroidLocationSheet extends StatelessWidget {
  const _AndroidLocationSheet({
    required this.apps,
    required this.placeName,
    required this.isAr,
  });

  final List<_MapApp> apps;
  final String placeName;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isAr ? 'افتح الموقع في' : 'Open location in',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            placeName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.surfaceContainerLowest,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ...apps.map((app) => _AppTile(app: app)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.alert,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  App tile
// ─────────────────────────────────────────────────────────────────────────────

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});

  final _MapApp app;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            Navigator.pop(context);
            await _launch(app.url);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: app.icon,
                ),
                const SizedBox(width: 14),
                Text(
                  app.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────────────────────────────────────

class _MapApp {
  const _MapApp({
    required this.name,
    required this.icon,
    required this.color,
    required this.url,
  });

  final String name;
  final Widget icon;
  final Color color;
  final String url;
}
