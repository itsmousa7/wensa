import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/core/widgets/glass_back_button.dart';
import 'package:future_riverpod/features/hyperpay_payment/domain/models/saved_card.dart';
import 'package:future_riverpod/features/hyperpay_payment/presentation/providers/saved_cards_provider.dart';

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
          content: Text(
            isAr
                ? 'تعذر حذف البطاقة. حاول مرة أخرى.'
                : 'Could not remove the card. Please try again.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _brandIcon(String? brand) {
    final asset = switch (brand) {
      'VISA' => 'assets/icons/visa.svg',
      'MASTER' => 'assets/icons/mastercard.svg',
      _ => null,
    };
    if (asset == null) return const Icon(Icons.credit_card, size: 28);
    return SizedBox(
      width: 36,
      height: 24,
      child: SvgPicture.asset(asset, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cardsAsync = ref.watch(savedCardsProvider);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: GlassBackButton.appBarLeading(),
          leadingWidth: GlassBackButton.appBarLeadingWidth,
          title: Text(
            isAr ? 'البطاقات المحفوظة' : 'Saved Cards',
            style: theme.textTheme.titleLarge?.copyWith(color: cs.outline),
          ),
        ),
        body: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              isAr
                  ? 'تعذر تحميل البطاقات المحفوظة.'
                  : 'Could not load your saved cards.',
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
                      Text(
                        isAr ? 'لا توجد بطاقات محفوظة' : 'No saved cards yet',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        isAr
                            ? 'يمكنك حفظ بطاقتك أثناء الدفع لاستخدامها لاحقًا.'
                            : 'You can save a card during checkout to use it for faster payments.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.outline,
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
                return ListTile(
                  key: Key('saved_card_${card.id}'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusLG,
                  ),
                  // Dark theme's surfaceContainer matches the page surface
                  // (tiles vanish) — use the highest container tone there.
                  tileColor: theme.brightness == Brightness.dark
                      ? cs.surfaceContainerHighest
                      : cs.surfaceContainer,
                  leading: _brandIcon(card.brand),
                  // Explicit onSurface colors: the app's dark textTheme is
                  // baked with light-mode colors, so default-styled text
                  // renders dark-on-dark.
                  title: Text(
                    card.displayName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: card.expiryLabel == null
                      ? null
                      : Text(
                          isAr
                              ? 'تنتهي ${card.expiryLabel}'
                              : 'Expires ${card.expiryLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
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
          child: Icon(
            CupertinoIcons.trash,
            color: AppColors.danger,
            size: 20,
          ),
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
              isAr ? 'حذف البطاقة؟' : 'Remove this card?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isAr
                  ? '${card.displayName} ستُحذف. يمكنك حفظها مجددًا في عملية دفع لاحقة.'
                  : '${card.displayName} will be removed. You can save it again during a future payment.',
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
                    child: Text(isAr ? 'إلغاء' : 'Cancel'),
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
                    label: Text(isAr ? 'حذف' : 'Remove'),
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
