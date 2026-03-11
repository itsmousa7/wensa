// lib/features/places/presentation/widgets/place_details/place_contact_section.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
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
            icon: Image.asset('assets/icons/phone.png'),
            label: 'Contact',
            color: AppColors.success,
            onTap: () => _launch('tel:${place.phone}'),
          ),
        if (place.instagramUrl != null)
          _Chip(
            icon: Image.asset('assets/icons/instagram.png'),

            label: 'Instagram',
            color: AppColors.balance2,
            onTap: () => _launch(instagramUrl(place.instagramUrl!)),
          ),
        if (place.websiteUrl != null)
          _Chip(
            icon: Image.asset('assets/icons/internet.png'),

            label: isAr ? 'الموقع الإلكتروني' : 'Website',
            color: AppColors.info,
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

  final Widget icon;
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
            SizedBox(height: 14, child: icon),
            const SizedBox(width: 7),
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
