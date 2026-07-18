import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/core/widgets/glass_back_button.dart';

import '../../domain/models/saved_card.dart';
import '../payment_strings.dart';
import '../providers/saved_cards_provider.dart';
import '../widgets/saved_card_tile.dart';

/// Profile → Payment → Saved cards: lists the user's saved HyperPay cards
/// with the option to remove them. Cards are added by opting in during a
/// payment ("Save this card for future payments").
class SavedCardsPage extends ConsumerWidget {
  const SavedCardsPage({super.key, required this.isAr});

  final bool isAr;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedCard card,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _DeleteCardDialog(card: card, isAr: isAr),
    );
    if (confirmed != true) return;
    try {
      await ref.read(savedCardsProvider.notifier).deleteCard(card.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(PaymentStrings.forLocale(isAr).couldNotRemoveCard),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cardsAsync = ref.watch(savedCardsProvider);
    final s = PaymentStrings.forLocale(isAr);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: GlassBackButton.appBarLeading(),
          leadingWidth: GlassBackButton.appBarLeadingWidth,
          title: Text(
            s.savedCardsTitle,
            style: theme.textTheme.titleLarge?.copyWith(color: cs.outline),
          ),
        ),
        body: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              s.couldNotLoadSavedCards,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.credit_card_off_outlined,
                        size: 48,
                        color: cs.outlineVariant,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Hint-field gray (onSurface @ 40% — see
                      // AppTypography.hint) so the empty state reads muted in
                      // BOTH modes; the default titleMedium is baked with
                      // light-mode colors and goes dark-on-dark in dark mode.
                      Text(
                        s.noSavedCardsYet,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        s.noSavedCardsHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final card = cards[index];
                return SavedCardTile(
                  card: card,
                  trailing: _DeleteButton(
                    key: Key('delete_card_${card.id}'),
                    onPressed: () => _confirmDelete(context, ref, card),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Circular, red-tinted trash button — reads as a destructive action at a
/// glance instead of a plain icon.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(CupertinoIcons.trash, color: AppColors.danger, size: 20),
        ),
      ),
    );
  }
}

/// Modern remove-card confirmation: a centered red icon badge, clear copy,
/// and a full-width filled destructive action instead of a plain text-only
/// AlertDialog.
class _DeleteCardDialog extends StatelessWidget {
  const _DeleteCardDialog({required this.card, required this.isAr});

  final SavedCard card;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = PaymentStrings.forLocale(isAr);

    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXL),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.trash_fill,
                color: AppColors.danger,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              s.removeCardTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.removeCardBody(card.displayName),
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusLG,
                      ),
                      foregroundColor: cs.onSurface,
                    ),
                    child: Text(s.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusLG,
                      ),
                    ),
                    icon: const Icon(CupertinoIcons.trash, size: 18),
                    label: Text(s.remove),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
