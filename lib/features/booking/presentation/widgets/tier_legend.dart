import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/event_tier.dart';

class TierLegend extends StatelessWidget {
  const TierLegend({
    super.key,
    required this.tiers,
    required this.tierColors,
  });

  final List<EventTier> tiers;
  final Map<String, Color> tierColors; // tierKey (nameEn) → Color

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tiers.map((tier) {
          final color = tierColors[tier.nameEn] ?? Colors.grey;
          final name = tier.nameEn.isNotEmpty ? tier.nameEn : tier.nameAr;
          final price = tier.priceIqd;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(price / 1000).toStringAsFixed(0)}k IQD',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
