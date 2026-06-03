import 'package:flutter/material.dart';
import 'package:future_riverpod/features/booking/domain/models/membership_plan.dart';
import 'package:future_riverpod/features/booking/presentation/widgets/bilingual_label.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

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

  String _formattedPrice() => plan.priceIqd.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // Selection tokens: only border + text change
    final borderColor = isSelected ? cs.primary : cs.outlineVariant;
    final borderWidth = isSelected ? 1.5 : 0.5;
    final textColor = isSelected ? cs.primary : cs.onSurface;
    final subtextColor = isSelected
        ? cs.primary.withValues(alpha: 0.65)
        : cs.onSurface.withValues(alpha: 0.50);
    final priceColor = isSelected ? cs.primary : cs.onSurface;
    final currencyColor = isSelected
        ? cs.primary.withValues(alpha: 0.55)
        : cs.onSurface.withValues(alpha: 0.40);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icon ───────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.12)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 12),

            // ── Name + duration ────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: (tt.titleSmall ?? const TextStyle()).copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                          child: BilingualLabel(
                            ar: plan.nameAr,
                            en: plan.nameEn,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (plan.allowFreeze) ...[
                        const SizedBox(width: 6),
                        _FreezeBadge(label: isAr ? 'تجميد' : 'Freeze'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (tt.bodySmall ?? const TextStyle()).copyWith(
                      color: subtextColor,
                      letterSpacing: 0.15,
                    ),
                    child: Text(
                      isAr
                          ? '${plan.durationDays} يوماً'
                          : '${plan.durationDays} days',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Price ──────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (tt.titleMedium ?? const TextStyle()).copyWith(
                    color: priceColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  child: Text(_formattedPrice()),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (tt.labelSmall ?? const TextStyle()).copyWith(
                    color: currencyColor,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                  child: const Text('IQD'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Freeze badge ─────────────────────────────────────────────────────────────

class _FreezeBadge extends StatelessWidget {
  const _FreezeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
