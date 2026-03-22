import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';

// BUG FIX: The original file used a FILE-LEVEL global boolean (_loadingDialogShown).
// This means all widgets across the entire app share the same flag, causing:
//   - Dialog shown by Widget A never gets dismissed by Widget B
//   - Race conditions when two providers both try to show a dialog
//   - Dialog remains open permanently if the widget rebuilds at the wrong moment
//
// FIX: Pass a local per-call mutable container instead, so each call site
// owns its own "is dialog shown" state, tracked entirely inside the function.

/// Holds whether a loading dialog was opened for a specific listen call.
/// Create one per [listenAsyncProvider] site and keep it alive as long as
/// the listener is registered (typically the lifetime of the widget state).
class LoadingDialogState {
  bool _shown = false;
}

void listenAsyncProvider<T>({
  required BuildContext context,
  required AsyncValue<T> next,
  AsyncValue<T>? prev,
  // BUG FIX: accept a LoadingDialogState so each call site tracks its own flag
  LoadingDialogState? dialogState,
  VoidCallback? onLoading,
  void Function(CustomError error)? onError,
}) {
  final state = dialogState ?? LoadingDialogState(); // fallback: no-op tracking

  // SHOW dialog
  if (next.isLoading && onLoading != null && !state._shown) {
    state._shown = true;
    onLoading();
  }

  // HIDE dialog
  if (state._shown && prev?.isLoading == true && !next.isLoading) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    state._shown = false;
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
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  );
}
