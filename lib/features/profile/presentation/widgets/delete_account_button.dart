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

  /// Runs the actual deletion. The confirmation sheet is already closed by the
  /// caller before this runs — deleting signs the user out, which triggers the
  /// router redirect to /signin and unmounts this page, so any modal still open
  /// at that moment crashes (unmounted-context / navigator-lock assertion).
  Future<void> _performDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      // Success: the auth-state change redirects to /signin; nothing to do.
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'حدث خطأ. يرجى المحاولة مجدداً.'
                : 'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _showConfirmationSheet() async {
    if (_loading) return;
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
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    // Close the sheet FIRST, then delete. Deleting signs the
                    // user out and the router redirects to /signin, tearing
                    // down this page — popping after (or leaving the sheet
                    // open) crashes with an unmounted-context assertion.
                    onPressed: () {
                      Navigator.pop(ctx);
                      _performDelete();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.alert,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      widget.isAr ? 'حذف حسابي' : 'Delete My Account',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
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
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      widget.isAr ? 'إلغاء' : 'Cancel',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTypography.buttonFontFamily(
                          widget.isAr ? 'ar' : 'en',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.alert,
                  strokeWidth: 2,
                ),
              )
            else
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
