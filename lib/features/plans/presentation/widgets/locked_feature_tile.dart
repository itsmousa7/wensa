import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

/// Dimmed tile with lock icon and upgrade CTA.
/// Never hide locked features — showing this is a conversion surface.
class LockedFeatureTile extends StatelessWidget {
  const LockedFeatureTile({
    super.key,
    required this.label,
    required this.requiredPlanName,
    this.onUpgradeTap,
  });

  final String  label;
  final String  requiredPlanName; // e.g. 'Growth' or 'Pro'
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: ListTile(
        leading: const Icon(Icons.lock_outline, color: AppColors.neutralGray),
        title: Text(label, style: const TextStyle(color: AppColors.neutralGray)),
        trailing: GestureDetector(
          onTap: onUpgradeTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.brandBlue),
              borderRadius: AppSpacing.borderRadiusMD,
            ),
            child: Text(
              'Upgrade to $requiredPlanName',
              style: const TextStyle(fontSize: 11, color: AppColors.brandBlue),
            ),
          ),
        ),
      ),
    );
  }
}
