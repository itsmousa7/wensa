// lib/features/places/presentation/widgets/place_location_sheet.dart
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

void showLocationSheet({
  required BuildContext context,
  required double latitude,
  required double longitude,
  required String placeName,
  required bool isAr,
}) {
  if (Platform.isIOS) {
    _showIosSheet(
      context: context,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
      isAr: isAr,
    );
  } else {
    _showAndroidSheet(
      context: context,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
      isAr: isAr,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  iOS — CupertinoActionSheet (includes Apple Maps)
// ─────────────────────────────────────────────────────────────────────────────

void _showIosSheet({
  required BuildContext context,
  required double latitude,
  required double longitude,
  required String placeName,
  required bool isAr,
}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => CupertinoActionSheet(
      title: Text(isAr ? 'افتح الموقع في' : 'Open location in'),
      message: Text(placeName),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _launch(
              'https://maps.apple.com/?q=${Uri.encodeComponent(placeName)}&ll=$latitude,$longitude',
            );
          },
          child: Text(isAr ? 'خرائط آبل' : 'Apple Maps'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _launch(
              'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
            );
          },
          child: Text(isAr ? 'خرائط جوجل' : 'Google Maps'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _launch('https://waze.com/ul?ll=$latitude,$longitude&navigate=yes');
          },
          child: const Text('Waze'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: Text(isAr ? 'إلغاء' : 'Cancel'),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Android — Material bottom sheet (no Apple Maps)
// ─────────────────────────────────────────────────────────────────────────────

void _showAndroidSheet({
  required BuildContext context,
  required double latitude,
  required double longitude,
  required String placeName,
  required bool isAr,
}) {
  final apps = [
    _MapApp(
      name: isAr ? 'خرائط جوجل' : 'Google Maps',
      icon: Icons.place_outlined,
      color: const Color(0xFF4285F4),
      url:
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    ),
    _MapApp(
      name: 'Waze',
      icon: Icons.navigation_outlined,
      color: const Color(0xFF00C8FF),
      url: 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
    ),
  ];

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) =>
        _AndroidLocationSheet(apps: apps, placeName: placeName, isAr: isAr),
  );
}

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
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ...apps.map((app) => _AppTile(app: app)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: cs.surfaceContainer,
            ),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: TextStyle(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});
  final _MapApp app;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: app.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(app.icon, color: app.color, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  app.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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

class _MapApp {
  const _MapApp({
    required this.name,
    required this.icon,
    required this.color,
    required this.url,
  });
  final String name;
  final IconData icon;
  final Color color;
  final String url;
}

Future<void> _launch(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
