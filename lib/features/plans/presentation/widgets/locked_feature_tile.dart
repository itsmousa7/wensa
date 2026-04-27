import 'package:flutter/material.dart';

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
        leading: const Icon(Icons.lock_outline, color: Color(0xFF9E9E9E)),
        title: Text(label, style: const TextStyle(color: Color(0xFF9E9E9E))),
        trailing: GestureDetector(
          onTap: onUpgradeTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2196F3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Upgrade to $requiredPlanName',
              style: const TextStyle(fontSize: 11, color: Color(0xFF2196F3)),
            ),
          ),
        ),
      ),
    );
  }
}
