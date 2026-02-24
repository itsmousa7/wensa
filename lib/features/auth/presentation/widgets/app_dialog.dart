import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void appDialog(
  BuildContext context,
  String title,
  Widget content, {
  bool actionNeeded = true,
}) {
  if (Platform.isIOS) {
    showCupertinoDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: title.isNotEmpty ? Text(title) : null,
          content: IntrinsicHeight(child: content),
          actions: actionNeeded
              ? [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ]
              : [],
        );
      },
    );
  } else {
    // Use plain Dialog when it's just a loading indicator
    if (title.isEmpty && !actionNeeded) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: IntrinsicWidth(
                child: IntrinsicHeight(child: content),
              ),
            ),
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: title.isNotEmpty ? Text(title) : null,
          content: IntrinsicHeight(child: content),
          actions: actionNeeded
              ? [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ]
              : [],
        );
      },
    );
  }
}
