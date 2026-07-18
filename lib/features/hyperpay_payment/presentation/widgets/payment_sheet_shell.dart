import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

import '../payment_strings.dart';

/// Bottom-sheet chrome shared by the payment sheet's two states (card chooser
/// and card form): surface + top radius, the grabber, the "Payment" title row
/// with a close button, and a scrollable body.
///
/// [onClose] disables the close button when null.
class PaymentSheetShell extends StatelessWidget {
  const PaymentSheetShell({super.key, required this.child, this.onClose});

  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXL),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: AppSpacing.borderRadiusXS,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      PaymentStrings.of(context).payment,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
