// lib/core/share/branded_header.dart
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

/// "[app icon] WENSA" header used at the top of all shareable images.
class BrandedHeader extends StatelessWidget {
  const BrandedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.lightGreenPrimary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: 28,
            height: 28,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'WENSA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: brand,
          ),
        ),
      ],
    );
  }
}
