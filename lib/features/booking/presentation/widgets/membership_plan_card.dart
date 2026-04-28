import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/bilingual_label.dart';

class MembershipPlanCard extends StatelessWidget {
  const MembershipPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  final MembershipPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final foregroundColor =
        isSelected ? colorScheme.onPrimary : colorScheme.onSurface;
    final subtextColor =
        isSelected ? colorScheme.onPrimary.withValues(alpha: 0.8) : colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : Border.all(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.fitness_center,
              color: foregroundColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: BilingualLabel(
                          ar: plan.nameAr,
                          en: plan.nameEn,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: foregroundColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (plan.allowFreeze) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(alpha: 0.2)
                                : colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Freeze allowed',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.durationDays} days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtextColor,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${plan.priceIqd} IQD',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
