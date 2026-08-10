// lib/features/bookings_history/presentation/providers/membership_realtime_provider.dart
//
// Watching this provider (via ref.watch(membershipRealtimeSyncProvider(id)))
// opens a Supabase Realtime subscription on one membership row for exactly as
// long as something is watching it — in practice, the lifetime of the ticket
// detail page. When a merchant activates the membership elsewhere (the admin
// scan page's Activate button, which writes starts_at/ends_at), the postgres
// change event bumps bookingsRefreshProvider, which userMembershipsProvider
// already watches — so the open ticket page updates on its own, with no pull
// to refresh needed.
//
// autoDispose (the @riverpod default) closes the channel automatically once
// the ticket page is popped and nothing watches this provider anymore.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tickets_provider.dart';

part 'membership_realtime_provider.g.dart';

@riverpod
class MembershipRealtimeSync extends _$MembershipRealtimeSync {
  @override
  void build(String membershipId) {
    final channel = Supabase.instance.client
        .channel('membership-$membershipId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'bookings',
          table: 'memberships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: membershipId,
          ),
          callback: (_) => ref.read(bookingsRefreshProvider.notifier).bump(),
        )
        .subscribe();

    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
  }
}
