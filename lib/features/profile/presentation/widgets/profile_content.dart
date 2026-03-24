import 'dart:io';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart';
import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_statistic_chip.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/profile_header.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/section_label.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/settings_card.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/sign_out_button.dart';
import 'package:go_router/go_router.dart';

class ProfileContent extends ConsumerWidget {
  const ProfileContent({super.key, required this.user, required this.isAr});

  final dynamic user;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeState = ref.watch(appThemeProvider);

    // Resolve current visual label to show as subtitle on the tile
    final isDark = switch (themeState) {
      DarkTheme() => true,
      LightTheme() => false,
      SystemTheme() =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    final themeSubtitle = switch (themeState) {
      SystemTheme() => isAr ? 'تتبع مظهر الجهاز' : 'Follow Device',
      LightTheme() => isAr ? 'الوضع الفاتح' : 'Light',
      DarkTheme() => isAr ? 'الوضع الداكن' : 'Dark',
    };

    final favoritesCount = ref.watch(favoritesProvider).value?.length ?? 0;
    final reviewsCountAsync = ref.watch(userReviewsCountProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: ProfileHeader(user: user, isAr: isAr),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Stats row ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    PlaceStatisticChip(
                      icon: CupertinoIcons.heart,
                      value: '$favoritesCount',
                      label: isAr ? 'الاعجابات' : 'Likes',
                      accentColor: AppColors.alert,
                      textColor: AppColors.alert,
                    ),
                    const SizedBox(width: 12),
                    PlaceStatisticChip(
                      icon: Icons.star_border,
                      value: '${reviewsCountAsync.value}',
                      label: isAr ? 'التقييمات' : 'Reviews',
                      highlighted: true,
                      textColor: cs.primary,
                      accentColor: cs.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Appearance ─────────────────────────────────────────────
                SectionLabel(title: isAr ? 'المظهر' : 'Appearance'),
                const SizedBox(height: 10),
                SettingsCard(
                  children: [
                    SettingsTile(
                      icon: isDark
                          ? CupertinoIcons.moon_fill
                          : CupertinoIcons.sun_max_fill,
                      iconColor: cs.primary,
                      title: isAr ? 'المظهر' : 'Appearance',
                      subtitle: themeSubtitle,
                      onTap: () => context.pushNamed(
                        RouteNames.themeSettings,
                        extra: isAr,
                      ),
                      showChevron: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Language ───────────────────────────────────────────────
                SectionLabel(title: isAr ? 'اللغة' : 'Language'),
                const SizedBox(height: 10),
                SettingsCard(
                  children: [
                    SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: cs.primary,
                      title: isAr ? 'اللغة العربية' : 'Arabic',
                      trailing: Transform.scale(
                        scaleX: isAr ? -1 : 1,
                        child: Platform.isIOS
                            ? CNSwitch(
                                value: isAr,
                                onChanged: (_) => ref
                                    .read(appLocaleProvider.notifier)
                                    .toggle(),
                              )
                            : Switch.adaptive(
                                value: isAr,
                                onChanged: (_) => ref
                                    .read(appLocaleProvider.notifier)
                                    .toggle(),
                                activeTrackColor: cs.primary,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Account ────────────────────────────────────────────────
                SectionLabel(title: isAr ? 'الحساب' : 'Account'),
                const SizedBox(height: 10),
                SettingsCard(
                  children: [
                    SettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: cs.primary,
                      title: isAr ? 'تغيير الاسم' : 'Change Name',
                      onTap: () => context.pushNamed(RouteNames.changeName),
                      showChevron: true,
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: cs.onSurface.withValues(alpha: 0.08),
                    ),
                    SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      iconColor: cs.primary,
                      title: isAr ? 'تغيير كلمة المرور' : 'Change Password',
                      onTap: () => context.pushNamed(RouteNames.changePassword),
                      showChevron: true,
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ── Sign out ───────────────────────────────────────────────
                SignOutButton(isAr: isAr),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
