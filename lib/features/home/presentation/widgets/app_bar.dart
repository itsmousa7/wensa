import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeAppBar extends ConsumerWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final userAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    final uiLocale = isAr ? 'ar' : 'en';
    final textTheme = AppTypography.getTextTheme(uiLocale, context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
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

                error: (_, _) => Text(
                  '',
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                data: (users) {
                  final firstName = users.firstName;

                  final nameTT = AppTypography.getTextTheme(firstName, context);

                  return Text(
                    '$firstName 👋',
                    style: nameTT.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          Spacer(),

          Stack(
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
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
