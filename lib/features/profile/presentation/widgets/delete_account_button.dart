import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';

class DeleteAccountButton extends ConsumerStatefulWidget {
  const DeleteAccountButton({super.key, required this.isAr});

  final bool isAr;

  @override
  ConsumerState<DeleteAccountButton> createState() =>
      _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<DeleteAccountButton> {
  bool _loading = false;
  String? _errorMessage;

  Future<void> _showConfirmationSheet() async {
    await showModalBottomSheet(
      context: context,
      // Present on the root navigator so the sheet + scrim sit above the
      // bottom navigation bar instead of behind it.
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.alert.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.trash,
                color: AppColors.alert,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isAr ? 'حذف الحساب' : 'Delete Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.alert,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isAr
                  ? 'سيتم حذف حسابك وجميع بياناتك بشكل نهائي. لا يمكن التراجع عن هذا الإجراء.'
                  : 'Your account and all data will be permanently deleted. This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            StatefulBuilder(
              builder: (ctx2, setInner) {
                return Column(
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.alert.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(ctx2).textTheme.bodySmall?.copyWith(
                            color: AppColors.alert,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                setInner(() {
                                  _loading = true;
                                  _errorMessage = null;
                                });
                                try {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .deleteAccount();
                                  // Auth state change fires → router redirects.
                                  // Close the sheet only after success.
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  if (mounted) {
                                    setInner(() {
                                      _loading = false;
                                      _errorMessage = widget.isAr
                                          ? 'حدث خطأ. يرجى المحاولة مجدداً.'
                                          : 'Something went wrong. Please try again.';
                                    });
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.alert,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isAr
                                    ? 'حذف حسابي'
                                    : 'Delete My Account',
                                style: Theme.of(
                                  ctx2,
                                ).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppTypography.buttonFontFamily(
                                    widget.isAr ? 'ar' : 'en',
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed:
                            _loading ? null : () => Navigator.pop(ctx),
                        child: Text(
                          widget.isAr ? 'إلغاء' : 'Cancel',
                          style: Theme.of(ctx2).textTheme.titleSmall?.copyWith(
                            color: Theme.of(ctx2).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTypography.buttonFontFamily(
                              widget.isAr ? 'ar' : 'en',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showConfirmationSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.alert.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.trash,
              color: AppColors.alert,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              widget.isAr ? 'حذف الحساب' : 'Delete Account',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.alert,
                fontWeight: FontWeight.w700,
                fontFamily: AppTypography.buttonFontFamily(
                  widget.isAr ? 'ar' : 'en',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
