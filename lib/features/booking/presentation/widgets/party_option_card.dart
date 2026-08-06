import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

/// Toggle + guest-count stepper shown under the shift picker in
/// [FarmSection] when the selected shift has party pricing enabled.
/// Purely presentational — the caller owns all state.
class PartyOptionCard extends StatelessWidget {
  const PartyOptionCard({
    super.key,
    required this.includedPersons,
    required this.flatFeeIqd,
    required this.extraPersonFeeIqd,
    required this.isOn,
    required this.guestCount,
    required this.onToggle,
    required this.onGuestCountChanged,
  });

  final int includedPersons;
  final int flatFeeIqd;
  final int extraPersonFeeIqd;
  final bool isOn;
  final int guestCount;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onGuestCountChanged;

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

    final extraGuests = (guestCount - includedPersons).clamp(0, 1 << 30);
    final extraTotal = extraGuests * extraPersonFeeIqd;
    final String overagePart = extraGuests <= 0
        ? (isAr
            ? 'بدون رسوم إضافية حتى $includedPersons ضيوف'
            : 'No extra charge up to $includedPersons guests')
        : (isAr
            ? '+${_formatIqd(extraTotal)} د.ع لـ $extraGuests ضيوف إضافيين'
            : '+${_formatIqd(extraTotal)} IQD for $extraGuests extra guest(s)');
    final String helperText = flatFeeIqd > 0
        ? (isAr
            ? '${_formatIqd(flatFeeIqd)} د.ع رسوم الحفلة · $overagePart'
            : '${_formatIqd(flatFeeIqd)} IQD party fee · $overagePart')
        : overagePart;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  color:
                      isOn ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr ? 'هل تحضر مجموعة؟' : 'Bringing a party?',
                  style: (tt.titleSmall ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOn ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              Switch.adaptive(
                value: isOn,
                onChanged: onToggle,
                activeTrackColor: cs.primary,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: !isOn
                ? const SizedBox(width: double.infinity, height: 0)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isAr ? 'عدد الضيوف' : 'Guests',
                              style: (tt.bodyMedium ?? const TextStyle())
                                  .copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.7)),
                            ),
                            const Spacer(),
                            _StepperButton(
                              icon: Icons.remove_rounded,
                              onTap: guestCount > 1
                                  ? () => onGuestCountChanged(guestCount - 1)
                                  : null,
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '$guestCount',
                                textAlign: TextAlign.center,
                                style: (tt.titleMedium ?? const TextStyle())
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            _StepperButton(
                              icon: Icons.add_rounded,
                              onTap: () => onGuestCountChanged(guestCount + 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          helperText,
                          style: (tt.bodySmall ?? const TextStyle()).copyWith(
                            color: extraGuests > 0
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.5),
                            fontWeight: extraGuests > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? cs.primary.withValues(alpha: 0.10)
          : cs.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}
