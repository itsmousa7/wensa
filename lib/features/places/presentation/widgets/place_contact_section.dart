// lib/features/places/presentation/widgets/place_details/place_contact_section.dart
import 'package:flutter/material.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_details_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceContactSection extends StatelessWidget {
  const PlaceContactSection({
    super.key,
    required this.place,
    required this.isAr,
  });

  final PlaceModel place;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (place.phone != null)
          _Chip(
            icon: Icons.phone_outlined,
            label: 'Contact',
            color: const Color(0xFF34C759),
            onTap: () => _launch('tel:${place.phone}'),
          ),
        if (place.instagramUrl != null)
          _Chip(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            color: const Color(0xFFE1306C),
            onTap: () => _launch(instagramUrl(place.instagramUrl!)),
          ),
        if (place.websiteUrl != null)
          _Chip(
            icon: Icons.language_outlined,
            label: isAr ? 'الموقع الإلكتروني' : 'Website',
            color: const Color(0xFF007AFF),
            onTap: () => _launch(place.websiteUrl!),
          ),
      ],
    );
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
