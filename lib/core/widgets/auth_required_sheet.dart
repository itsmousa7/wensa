// lib/core/widgets/auth_required_sheet.dart
//
// Guest-mode gate. Content browsing is open to everyone (Apple 5.1.1(v)), but
// account-based actions — favorites, booking, profile, notifications — still
// require a signed-in user. `requireAuth` is the single choke point: call it
// before performing a gated action. If the user is signed in it returns true
// and the caller proceeds; otherwise it shows a bottom sheet inviting sign-in
// and returns false.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Returns `true` when the current user is authenticated (caller may proceed).
/// Returns `false` for guests, after presenting the sign-in invitation sheet.
bool requireAuth(BuildContext context, WidgetRef ref) {
  if (ref.read(isAuthenticatedProvider)) return true;
  showAuthRequiredSheet(context);
  return false;
}

Future<void> showAuthRequiredSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Present on the root navigator so the sheet sits ABOVE the floating
    // bottom nav bar (which lives in the NavShell Stack, above the page).
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (_) => const _AuthRequiredSheet(),
  );
}

class _AuthRequiredSheet extends StatelessWidget {
  const _AuthRequiredSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(20),
          Icon(Icons.lock_outline_rounded, size: 40, color: cs.primary),
          const Gap(16),
          Text(
            context.tr('sign_in_required_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            context.tr('sign_in_required_body'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          AppButton.filled(
            label: context.tr('sign_in'),
            onPressed: () {
              Navigator.pop(context);
              context.goNamed(RouteNames.signin);
            },
          ),
          const Gap(8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            // No ink ripple / highlight on tap.
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              splashFactory: NoSplash.splashFactory,
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
            child: Text(
              context.tr('cancel'),
              style: theme.textTheme.titleMedium?.copyWith(color: cs.outline),
            ),
          ),
        ],
      ),
    );
  }
}
