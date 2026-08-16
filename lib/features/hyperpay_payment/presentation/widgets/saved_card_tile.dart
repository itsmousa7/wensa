import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

import '../../domain/models/saved_card.dart';
import '../payment_strings.dart';
import 'card_brand_icon.dart';

/// One saved card as a rounded, subtly elevated list tile — the brand mark,
/// the masked number, and its expiry.
///
/// Used both in the payment sheet (tap to charge) and on the Saved Cards page
/// (trailing delete button).
class SavedCardTile extends StatelessWidget {
  const SavedCardTile({
    super.key,
    required this.card,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final SavedCard card;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = PaymentStrings.of(context);

    return ListTile(
      key: Key('saved_card_${card.id}'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLG),
      // Dark theme's surfaceContainer matches the surrounding surface (tiles
      // vanish), but surfaceContainerHighest (#313131) is too light — blend a
      // faint white over the surface for a subtle elevated tile (~#1F1F1F).
      tileColor: theme.brightness == Brightness.dark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.055), cs.surface)
          : cs.surfaceContainer,
      leading: CardBrandIcon(brand: card.brand),
      // Card name/masked number stays LTR — it embeds Latin digits that must
      // not mirror under Arabic.
      // Explicit onSurface colors: the app's dark textTheme is baked with
      // light-mode colors, so relying on the default style renders
      // dark-on-dark here.
      title: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          card.displayName,
          textAlign: s.isAr ? TextAlign.right : TextAlign.left,
          style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        ),
      ),
      subtitle: card.expiryLabel == null
          ? null
          : Text(
              '${s.expiresPrefix}${card.expiryLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
      trailing: trailing,
      enabled: enabled,
      onTap: onTap,
    );
  }
}
