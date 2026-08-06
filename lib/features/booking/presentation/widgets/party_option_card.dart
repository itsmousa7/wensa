import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

/// Toggle for the flat party fee, shown under the shift picker in
/// [FarmSection] when the selected shift has party pricing enabled.
/// Purely presentational — the caller owns all state. Guest-count
/// entry lives separately in [GuestCountCard].
class PartyOptionCard extends StatelessWidget {
  const PartyOptionCard({
    super.key,
    required this.flatFeeIqd,
    required this.isOn,
    required this.onToggle,
  });

  final int flatFeeIqd;
  final bool isOn;
  final ValueChanged<bool> onToggle;

  static String _formatIqd(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn ? cs.primary.withValues(alpha: 0.35) : cs.outlineVariant,
          width: isOn ? 1.5 : 0.5,
        ),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOn
                  ? cs.primary.withValues(alpha: 0.12)
                  : cs.onSurface.withValues(alpha: 0.05),
              borderRadius: AppSpacing.borderRadiusMD,
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 20,
              color: isOn ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'هل تحضر مجموعة؟' : 'Bringing a party?',
                  style: (tt.titleSmall ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOn ? cs.primary : cs.onSurface,
                  ),
                ),
                if (flatFeeIqd > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? '${_formatIqd(flatFeeIqd)} د.ع رسوم الحفلة'
                        : '${_formatIqd(flatFeeIqd)} IQD party fee',
                    style: (tt.bodySmall ?? const TextStyle())
                        .copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scaleX: isAr ? -1 : 1,
            child: Platform.isIOS
                ? CNSwitch(value: isOn, onChanged: onToggle)
                : Switch.adaptive(
                    value: isOn,
                    onChanged: onToggle,
                    activeTrackColor: cs.primary,
                  ),
          ),
        ],
      ),
    );
  }
}
