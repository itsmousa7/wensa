// lib/features/notifications/domain/repositories/notifications_repository.dart

import 'package:future_riverpod/features/notifications/domain/models/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'notifications_repository.g.dart';

class NotificationsRepository {
  const NotificationsRepository(this._client);
  final SupabaseClient _client;

  Future<List<AppNotification>> fetchAll() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];

    final data = await _client
        .schema('profiles')
        .from('user_notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(200);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  /// Mark every unread notification belonging to the current user as read.
  /// Done on the server side so the next list fetch reflects the change for
  /// every device the user is signed in on.
  Future<void> markAllAsRead() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client
        .schema('profiles')
        .from('user_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', uid)
        .isFilter('read_at', null);
  }
}

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepository(Supabase.instance.client);
