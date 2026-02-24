import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

import '../../../../core/constants/theme/app_spacing.dart';

/// Custom app button with loading state
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final ButtonSize size;
  final Widget? icon;
  final bool fullWidth;
  final Color color;

  const AppButton({
    super.key,
    this.label = '',
    this.color = AppColors.white,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.fullWidth = true,
  });

  /// Primary button (elevated with green background)
  const AppButton.primary({
    required this.label,
    this.icon,
    this.color = AppColors.white,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = true,
    super.key,
  }) : type = ButtonType.primary;

  /// Secondary button (outlined with green border)
  const AppButton.secondary({
    required this.label,
    this.icon,
    this.color = AppColors.transparent,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = true,
    super.key,
  }) : type = ButtonType.secondary;

  /// Text button (no background)
  const AppButton.text({
    required this.label,
    this.color = AppColors.transparent,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    super.key,
  }) : type = ButtonType.text,
       icon = null;

  /// Destructive button (red color for delete actions)
  const AppButton.destructive({
    required this.label,
    this.color = AppColors.white,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = true,
    super.key,
  }) : type = ButtonType.destructive,
       icon = null;

  /// Filled button
  const AppButton.filled({
    required this.label,
    this.color = AppColors.white,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = true,
    super.key,
  }) : type = ButtonType.filled,
       icon = null;

  /// Icon-only button (no label)
  const AppButton.icon({
    required this.icon,
    this.color = AppColors.white,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    super.key,
  }) : type = ButtonType.icon,
       label = '';

  @override
  Widget build(BuildContext context) {
    // Determine button height based on size
    final double height = switch (size) {
      ButtonSize.small => AppSpacing.buttonHeightSM,
      ButtonSize.medium => AppSpacing.buttonHeight,
      ButtonSize.large => AppSpacing.buttonHeightLG,
    };

    // Build loading indicator
    final loadingIndicator = SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    // Build button content (label-based buttons)
    Widget buttonChild = isLoading
        ? loadingIndicator
        : Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
            ),
          );

    // Build button based on type
    final button = switch (type) {
      ButtonType.primary => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      ),
      ButtonType.filled => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: Theme.of(context).colorScheme.secondaryContainer,
            width: AppSpacing.borderThin,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      ),
      ButtonType.secondary => OutlinedButton.icon(
        icon: icon,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
          backgroundColor: AppColors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shape: const StadiumBorder(),
        ),
        onPressed: isLoading ? null : onPressed,
        label: buttonChild,
      ),
      ButtonType.text => TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      ),
      ButtonType.destructive => FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: Theme.of(context).colorScheme.errorContainer,
            width: AppSpacing.borderMedium,
          ),
        ),
        child: buttonChild,
      ),
      ButtonType.icon => IconButton(
        icon: isLoading ? loadingIndicator : icon!,
        onPressed: isLoading ? null : onPressed,
        style: IconButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: button,
    );
  }
}

enum ButtonType { primary, secondary, text, destructive, filled, icon }

enum ButtonSize { small, medium, large }
