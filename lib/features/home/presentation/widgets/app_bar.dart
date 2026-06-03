import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/notifications/fcm_service.dart';
import 'package:future_riverpod/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeAppBar extends ConsumerWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final userAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    // BUG FIX: use the actual locale, not the user's first name
    final uiLocale = isAr ? 'ar' : 'en';
    final textTheme = AppTypography.getTextTheme(uiLocale, context);

    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, topPadding + 14, 22, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'مرحباً،' : 'Hello,',
                style: textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 2),

              userAsync.when(
                loading: () => Skeletonizer(
                  enabled: true,
                  effect: ShimmerEffect(
                    baseColor: theme.colorScheme.surfaceContainer,
                    highlightColor: theme.colorScheme.surfaceContainerHighest,
                    duration: const Duration(milliseconds: 1000),
                  ),
                  child: Bone(
                    width: 130,
                    height: 20,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),

                error: (_, _) => const SizedBox.shrink(),

                data: (user) {
                  // BUG FIX: pass uiLocale ('en'/'ar'), not user.firstName
                  return Text(
                    '${user.firstName} 👋',
                    style: textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          const Spacer(),

          _NotificationsBell(),
        ],
      ),
    );
  }
}

class _NotificationsBell extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends ConsumerState<_NotificationsBell> {
  @override
  void initState() {
    super.initState();
    fcmEventTick.addListener(_onFcmEvent);
  }

  @override
  void dispose() {
    fcmEventTick.removeListener(_onFcmEvent);
    super.dispose();
  }

  void _onFcmEvent() {
    if (!mounted) return;
    // A push just arrived — refetch the inbox so the badge reflects the new
    // unread row that the edge function inserted before fan-out.
    ref.read(notificationsRefreshProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = ref.watch(unreadNotificationsCountProvider) > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.bell,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          if (hasUnread)
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surfaceContainer,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}