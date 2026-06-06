import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

SnackBar snack(
  BuildContext context, {
  bool isError = false,
  required String message,
}) => SnackBar(
  backgroundColor: isError
      ? const Color(0xFFB91C1C)
      : Theme.of(context).colorScheme.primary,
  shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMD),
  content: Row(
    children: [
      if (isError) ...[
        const Icon(Icons.error_outline, color: Colors.white, size: 20),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ],
  ),
);
