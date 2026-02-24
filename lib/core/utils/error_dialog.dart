import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void errorDialog(BuildContext context, dynamic error) {
  String message;

  if (error is CustomError) {
    message = error.message;
  } else if (error is AuthException) {
    message = error.message;
  } else if (error is PostgrestException) {
    message = error.message;
  } else if (error is Exception) {
    message = error.toString().replaceAll('Exception: ', '');
  } else {
    message = error.toString();
  }

  appDialog(context, 'Error', Text(message));
}
