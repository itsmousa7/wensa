// lib/core/share/content_share_card.dart
//
// Fixed-width branded card used for sharing a place or an event as an image.
// Always renders on a pure white background regardless of the active theme.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

class ContentShareCard extends StatelessWidget {
  const ContentShareCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isAr,
    required this.footerText,
    this.coverBytes,
    this.shareUrl,
  });

  final String name;
  final String subtitle;
  final bool isAr;
  final String footerText;
  final Uint8List? coverBytes;
  final String? shareUrl;

  static const double _width = 360;

  // Hard-coded light palette — the card must never follow dark theme.
  static const Color _white = Colors.white;
  static const Color _textPrimary = Color(0xFF111111);
  static const Color _textMuted = Color(0xFF666666);
  static const Color _divider = Color(0xFFF0F0F0);
  static const Color _brandDark = AppColors.lightGreenSecondary;

  @override
  Widget build(BuildContext context) {
    final crossAlign =
        isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = isAr ? TextAlign.right : TextAlign.left;

    return SizedBox(
      width: _width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: _white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover — full bleed, no horizontal padding
              AspectRatio(
                aspectRatio: 16 / 10,
                child: _Cover(
                  coverBytes: coverBytes,
                  name: name,
                ),
              ),

              // Name + subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(
                  crossAxisAlignment: crossAlign,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: textAlign,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _SubtitleRow(
                        subtitle: subtitle,
                        isAr: isAr,
                        color: _textMuted,
                      ),
                    ],
                  ],
                ),
              ),

              // Thin divider
              const Divider(height: 1, thickness: 1, color: _divider),

              // Footer: brand logo + name  ·  CTA text
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Wensa',
                      style: TextStyle(
                        color: _brandDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      footerText,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  const _SubtitleRow({
    required this.subtitle,
    required this.isAr,
    required this.color,
  });

  final String subtitle;
  final bool isAr;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.place_rounded, size: 13, color: color);
    final text = Flexible(
      child: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isAr
          ? [text, const SizedBox(width: 3), icon]
          : [icon, const SizedBox(width: 3), text],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.coverBytes, required this.name});

  final Uint8List? coverBytes;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverBytes != null)
          Image.memory(coverBytes!, fit: BoxFit.cover)
        else
          _GradientFallback(name: name),

        // Subtle bottom scrim — eases the transition into the white body
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x26000000)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : 'W';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E8FA3), Color(0xFF0C5563)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 72,
          fontWeight: FontWeight.w900,
          letterSpacing: -2,
        ),
      ),
    );
  }
}
