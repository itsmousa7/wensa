// lib/features/notifications/presentation/pages/notifications_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/widgets/glass_back_button.dart';
import 'package:future_riverpod/features/notifications/domain/models/app_notification.dart';
import 'package:future_riverpod/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:future_riverpod/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:skeletonizer/skeletonizer.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    // Defer until after first frame so the unread badge stays visible for the
    // brief moment the page opens, then disappears as the list refreshes —
    // matches the Instagram/Twitter pattern the user asked for.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAllRead());
  }

  Future<void> _markAllRead() async {
    if (_markedRead) return;
    _markedRead = true;
    try {
      await ref.read(notificationsRepositoryProvider).markAllAsRead();
    } finally {
      if (mounted) {
        ref.read(notificationsRefreshProvider.notifier).bump();
      }
    }
  }

  Future<void> _refresh() async {
    ref.read(notificationsRefreshProvider.notifier).bump();
    await ref.read(notificationsListProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final cs = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);
    final asyncList = ref.watch(notificationsListProvider);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leadingWidth: GlassBackButton.appBarLeadingWidth,
          leading: GlassBackButton.appBarLeading(),
          title: Text(
            isAr ? 'الإشعارات' : 'Notifications',
            style: tt.titleLarge?.copyWith(color: cs.onSurface),
          ),
        ),
        body: Builder(
          builder: (context) {
            final items = asyncList.value;
            final isFirstLoad = asyncList.isLoading && items == null;
            final hasError = asyncList.hasError && items == null;

            // First load: full-page skeleton (no refresh control yet)
            if (isFirstLoad) return const _NotificationsSkeleton();

            // Always render the scroll view so the refresh control
            // stays in the tree throughout refresh cycles.
            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(
                  refreshTriggerPullDistance: 80,
                  refreshIndicatorExtent: 50,
                  onRefresh: _refresh,
                  builder: (context, mode, pulledExtent, triggerDistance, _) {
                    final progress =
                        (pulledExtent / triggerDistance).clamp(0.0, 1.0);
                    final loading =
                        mode == RefreshIndicatorMode.refresh ||
                        mode == RefreshIndicatorMode.armed;
                    return Center(
                      child: loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          : Opacity(
                              opacity: progress,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 24,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                    );
                  },
                ),
                if (hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorView(
                      message: asyncList.error.toString(),
                      onRetry: _refresh,
                    ),
                  )
                else if (items == null || items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyView(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 6, bottom: 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _NotificationTile(
                          notification: items[i],
                          isAr: isAr,
                        ),
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tile
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.isAr});

  final AppNotification notification;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(isAr ? 'ar' : 'en', context);
    final unread = !notification.isRead;

    final title = isAr ? notification.titleAr : notification.titleEn;
    final body = isAr ? notification.bodyAr : notification.bodyEn;
    final accent = _accentFor(notification.kind, cs);

    return InkWell(
      onTap: () {
        final route = notification.tapRoute;
        if (route != null) context.push(route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: unread ? cs.primary.withValues(alpha: 0.05) : null,
          border: Border(
            bottom: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.06),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: Icon(
                _iconFor(notification.kind),
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: tt.titleSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(notification.createdAt, isAr),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (notification.tapRoute != null) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  isAr
                      ? CupertinoIcons.chevron_left
                      : CupertinoIcons.chevron_right,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(NotificationKind kind) => switch (kind) {
        NotificationKind.hourly => CupertinoIcons.sportscourt,
        NotificationKind.concert => CupertinoIcons.music_mic,
        NotificationKind.membership => CupertinoIcons.creditcard,
        NotificationKind.broadcastNewEvent => CupertinoIcons.calendar,
        NotificationKind.broadcastNewPlace => CupertinoIcons.map_pin_ellipse,
        NotificationKind.broadcastPromo => CupertinoIcons.tag,
        NotificationKind.broadcastGeneral => CupertinoIcons.bell_fill,
        NotificationKind.unknown => CupertinoIcons.bell_fill,
      };

  Color _accentFor(NotificationKind kind, ColorScheme cs) => switch (kind) {
        NotificationKind.hourly => cs.primary,
        NotificationKind.concert => cs.secondary,
        NotificationKind.membership => cs.primary,
        NotificationKind.broadcastNewEvent => cs.secondary,
        NotificationKind.broadcastNewPlace => cs.primary,
        NotificationKind.broadcastPromo => cs.error,
        NotificationKind.broadcastGeneral => cs.primary,
        NotificationKind.unknown => cs.primary,
      };

  String _formatTimestamp(DateTime dt, bool isAr) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;

    final time = DateFormat('h:mm a').format(dt);

    if (isAr) {
      // Arabic month names — match the rest of the app's bilingual approach
      const monthNames = [
        '',
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      final arTime = time
          .replaceAll('AM', 'ص')
          .replaceAll('PM', 'م');
      if (sameDay) return 'اليوم • $arTime';
      if (isYesterday) return 'أمس • $arTime';
      return '${dt.day} ${monthNames[dt.month]} ${dt.year} • $arTime';
    }

    if (sameDay) return 'Today • $time';
    if (isYesterday) return 'Yesterday • $time';
    return '${DateFormat('d MMM yyyy').format(dt)} • $time';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: cs.surfaceContainerHighest,
        highlightColor: cs.surface,
        duration: const Duration(milliseconds: 1100),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 32),
        itemCount: 7,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone(width: 44, height: 44, borderRadius: AppSpacing.borderRadiusMD),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(height: 13, borderRadius: BorderRadius.circular(6)),
                    const SizedBox(height: 8),
                    Bone(
                      width: double.infinity,
                      height: 11,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 6),
                    Bone(
                      width: 120,
                      height: 10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.bell_slash,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لا توجد إشعارات بعد.' : 'No notifications yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Error
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              isAr ? 'حدث خطأ ما' : 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
