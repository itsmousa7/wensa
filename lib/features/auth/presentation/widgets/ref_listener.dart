import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';

bool _loadingDialogShown = false;
void listenAsyncProvider<T>({
  required BuildContext context,
  required AsyncValue<T> next,
  AsyncValue<T>? prev,
  VoidCallback? onLoading,
  void Function(CustomError error)? onError,
}) {
  // SHOW dialog
  if (next.isLoading && onLoading != null && !_loadingDialogShown) {
    _loadingDialogShown = true;
    onLoading();
  }

  // HIDE dialog
  if (_loadingDialogShown && prev?.isLoading == true && !next.isLoading) {
    Navigator.of(context, rootNavigator: true).pop();
    _loadingDialogShown = false;
  }

  next.whenOrNull(
    error: (error, _) {
      if (error is CustomError) {
        onError?.call(error);
      }
    },
  );
}

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: CircularProgressIndicator(
            padding: EdgeInsets.all(8),
          ),
        ),
      ),
    ),
  );
}
