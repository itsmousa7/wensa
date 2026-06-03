// lib/features/notifications/presentation/providers/notifications_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/notifications/domain/models/app_notification.dart';
import 'package:future_riverpod/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_provider.g.dart';

/// Bumping this counter forces every notifications list/count provider to
/// re-fetch. Kept alive (non-autoDispose) so it survives navigation between
/// the bell button and the notifications page.
class _NotificationsRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final notificationsRefreshProvider =
    NotifierProvider<_NotificationsRefreshNotifier, int>(
  _NotificationsRefreshNotifier.new,
);

@riverpod
Future<List<AppNotification>> notificationsList(Ref ref) {
  ref.watch(notificationsRefreshProvider);
  return ref.watch(notificationsRepositoryProvider).fetchAll();
}

/// Unread count derived from the list — keeps a single source of truth and
/// updates the bell badge for free whenever the list refreshes.
@riverpod
int unreadNotificationsCount(Ref ref) {
  final asyncList = ref.watch(notificationsListProvider);
  return asyncList.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
}
