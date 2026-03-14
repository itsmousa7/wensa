// lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart';
import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/profile_avatar.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/profile_skeleton.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_statistic_chip.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final profileAsync = ref.watch(profileProvider);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: profileAsync.when(
          loading: () => const ProfileSkeleton(),
          error: (e, _) => _ProfileError(message: e.toString()),
          data: (user) => _ProfileContent(user: user, isAr: isAr),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Main content — rendered when profile data is available
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user, required this.isAr});

  final dynamic user; // AppUserModel
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = ref.watch(appThemeProvider) is DarkTheme;
    final favoritesCount = ref.watch(favoritesProvider).value?.length ?? 0;
    final reviewsCountAsync = ref.watch(userReviewsCountProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _ProfileHeader(user: user, isAr: isAr),
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
                      icon: Icons.favorite_rounded,
                      value: '$favoritesCount',
                      label: isAr ? 'الاعجابات' : 'Liked',
                      accentColor: AppColors.alert,
                    ),

                    const SizedBox(width: 12),
                    reviewsCountAsync.when(
                      loading: () => PlaceStatisticChip(
                        icon: Icons.star_rounded,
                        value: '—',
                        label: isAr ? 'التقييمات' : 'Reviews',
                        highlighted: true,
                      ),
                      error: (_, __) => PlaceStatisticChip(
                        icon: Icons.star_rounded,
                        value: '0',
                        label: isAr ? 'التقييمات' : 'Reviews',
                        highlighted: true,
                      ),
                      data: (count) => PlaceStatisticChip(
                        icon: Icons.star_rounded,
                        value: '$count',
                        label: isAr ? 'التقييمات' : 'Reviews',
                        highlighted: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Appearance ─────────────────────────────────────────────
                _SectionLabel(title: isAr ? 'المظهر' : 'Appearance'),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    SwitchListTile.adaptive(
                      value: isDark,
                      onChanged: (_) =>
                          ref.read(appThemeProvider.notifier).toggle(),

                      activeTrackColor: cs.primary,
                      title: Text(
                        isAr ? 'الوضع الداكن' : 'Dark Mode',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.outline,
                        ),
                      ),
                      secondary: _SettingIcon(
                        icon: isDark
                            ? CupertinoIcons.moon_fill
                            : CupertinoIcons.sun_max_fill,
                        color: cs.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Language ───────────────────────────────────────────────
                _SectionLabel(title: isAr ? 'اللغة' : 'Language'),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.lightGreenSecondary,
                      title: isAr ? 'اللغة العربية' : 'Arabic',
                      trailing: Switch.adaptive(
                        value: isAr,
                        onChanged: (_) =>
                            ref.read(appLocaleProvider.notifier).toggle(),
                        activeTrackColor: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Account ────────────────────────────────────────────────
                _SectionLabel(title: isAr ? 'الحساب' : 'Account'),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: cs.primary,
                      title: isAr ? 'تغيير الاسم' : 'Change Name',
                      onTap: () => context.pushNamed(RouteNames.changeName),
                      showChevron: true,
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      iconColor: cs.primary,
                      title: isAr ? 'تغيير كلمة المرور' : 'Change Password',
                      onTap: () => context.pushNamed(RouteNames.changePassword),
                      showChevron: true,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Sign out ───────────────────────────────────────────────
                _SignOutButton(isAr: isAr),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Profile header — gradient band + avatar + name + email
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.isAr});

  final dynamic user;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: [
            // Avatar
            ProfileAvatar(user: user),
            const SizedBox(height: 14),

            // Full name
            Text(
              user.fullName,
              style: tt.titleMedium?.copyWith(
                color: cs.outline,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Email
            Text(
              user.email,
              style: tt.bodySmall?.copyWith(
                color: cs.outline,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),

            // City (optional)
            if (user.city != null && user.city!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.city!,
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable building blocks
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.outline,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.onTap,
    this.trailing,
    this.showChevron = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _SettingIcon(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.outline,
                ),
              ),
            ),
            ?trailing,
            if (showChevron && trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.35),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: cs.onSurface.withValues(alpha: 0.08),
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton({required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(authRepositoryProvider).signOut(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.alert.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.square_arrow_right,
              color: AppColors.alert,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isAr ? 'تسجيل الخروج' : 'Sign Out',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.alert,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
//  Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: cs.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
