// lib/core/share/content_share_card.dart
//
// Fixed-width branded card used for sharing a place or an event as an image.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/share/branded_header.dart';

class ContentShareCard extends StatelessWidget {
  const ContentShareCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isAr,
    required this.footerText,
    this.coverBytes,
  });

  final String name;
  final String subtitle;
  final bool isAr;
  final String footerText;
  final Uint8List? coverBytes;

  static const double _width = 360;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: _width,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandedHeader(),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: _Cover(coverBytes: coverBytes, name: name),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightGreenPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              footerText,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.lightGreenSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.coverBytes, required this.name});
  final Uint8List? coverBytes;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (coverBytes != null) {
      return Image.memory(coverBytes!, fit: BoxFit.cover);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightGreenPrimary,
            AppColors.lightGreenSecondary,
          ],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
