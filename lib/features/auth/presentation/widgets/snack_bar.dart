import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

SnackBar snack(
  BuildContext context, {
  bool isError = false,
  required String message,
}) => SnackBar(
  content: Text(
    message,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
  ),
  backgroundColor: isError
      ? Theme.of(context).colorScheme.error
      : Theme.of(context).colorScheme.primary,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.secondary,
      width: 2,
    ),
  ),
);
