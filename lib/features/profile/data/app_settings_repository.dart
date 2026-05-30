import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'app_settings_repository.g.dart';

class AppSettingsRepository {
  const AppSettingsRepository(this._client);

  final SupabaseClient _client;

  Future<String> fetchSupportPhone() async {
    final data = await _client
        .from('app_settings')
        .select('value')
        .eq('key', 'support_whatsapp_phone')
        .maybeSingle();
    return (data?['value'] as String?) ?? '';
  }
}

@riverpod
AppSettingsRepository appSettingsRepository(Ref ref) =>
    AppSettingsRepository(Supabase.instance.client);

@riverpod
Future<String> supportPhone(Ref ref) =>
    ref.watch(appSettingsRepositoryProvider).fetchSupportPhone();
