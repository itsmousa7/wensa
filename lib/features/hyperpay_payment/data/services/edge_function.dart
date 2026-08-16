import 'package:supabase_flutter/supabase_flutter.dart';

/// Invokes a Supabase edge function and returns its JSON body.
///
/// Anything other than HTTP 200 throws — the payment services all treat a
/// non-200 as "we don't know the outcome" and surface a retryable error,
/// never a decline.
Future<Map<String, dynamic>> invokeEdgeFunction(
  String name,
  Map<String, dynamic> body,
) async {
  final result = await Supabase.instance.client.functions.invoke(
    name,
    body: body,
  );
  if (result.status != 200) {
    throw Exception('$name failed: ${result.data}');
  }
  return result.data as Map<String, dynamic>;
}
