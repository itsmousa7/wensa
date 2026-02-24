import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

CustomError handleException(Object e) {
  try {
    throw e;
  } on AuthException catch (e) {
    return CustomError(
      code: 'AUTH_ERROR',
      message: e.message,
      plugin: e.statusCode?.toString() ?? '',
    );
  } on PostgrestException catch (e) {
    return CustomError(
      code: 'DB_ERROR',
      message: e.message,
      plugin: e.code ?? '',
    );
  } catch (e) {
    return CustomError(
      code: 'UNKNOWN',
      message: e.toString(),
      plugin: '',
    );
  }
}
