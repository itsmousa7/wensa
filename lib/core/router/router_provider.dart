import 'dart:async';

import 'package:flutter/material.dart';
import 'package:future_riverpod/bottom_bar/widgets/nav_shell.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_name_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signin_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signup_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/verify_email_page.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/events/presentation/pages/event_details_page.dart';
import 'package:future_riverpod/features/favorites/presentation/pages/favorites_page.dart';
import 'package:future_riverpod/features/home/presentation/pages/home_page.dart';
import 'package:future_riverpod/features/home/presentation/pages/splash_page.dart';
import 'package:future_riverpod/features/places/presentation/pages/place_details_page.dart';
import 'package:future_riverpod/features/profile/presentation/pages/profile_page.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/theme_settings_page.dart';
import 'package:future_riverpod/features/search/presentation/pages/search_page.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

@riverpod
class SupabaseReady extends _$SupabaseReady {
  @override
  bool build() => false;
  void setReady() => state = true;
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (_, state) => _redirect(ref, state),
    refreshListenable: _RouterNotifier(ref),
    routes: [
      // ── Unauthenticated ───────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: '/signin',
        name: RouteNames.signin,
        builder: (_, _) => const SigninPage(),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (_, _) => const SignupPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: RouteNames.verifyEmail,
        builder: (_, s) => VerifyEmailPage(
          email: s.uri.queryParameters['email'],
          type: s.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/changeName',
        name: RouteNames.changeName,
        builder: (_, _) => const ChangeNamePage(),
      ),
      GoRoute(
        path: '/changePassword',
        name: RouteNames.changePassword,
        builder: (_, s) => ChangePasswordPage(
          fromForgotPassword: s.uri.queryParameters['from'] == 'forgot',
        ),
      ),

      // ── Detail pages (pushed on top of the shell) ─────────────────────────
      GoRoute(
        path: '/placeDetails',
        name: RouteNames.placeDetails,
        builder: (_, s) =>
            PlaceDetailsPage(placeId: s.uri.queryParameters['placeId'] ?? ''),
      ),
      GoRoute(
        path: '/eventDetails',
        name: RouteNames.eventDetails,
        builder: (_, s) =>
            EventDetailsPage(eventId: s.uri.queryParameters['eventId'] ?? ''),
      ),

      // ── Theme settings ────────────────────────────────────────────────────
      GoRoute(
        path: '/theme-settings', // ← must start with /
        name: RouteNames.themeSettings,
        builder: (_, s) => ThemeSettingsPage(isAr: s.extra as bool),
      ),

      // ── Shell — 4 persistent branches ─────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => NavShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: RouteNames.favorites,
                builder: (_, _) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (_, _) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // /search stays here as a sibling of the shell — correct
      GoRoute(
        path: '/search',
        name: RouteNames.search,
        builder: (_, _) => const SearchPage(),
      ),
    ],
  );
}

String? _redirect(Ref ref, GoRouterState state) {
  if (state.matchedLocation == '/splash') return null;
  if (!ref.read(supabaseReadyProvider)) return '/splash';

  final isAuth = ref.read(isAuthenticatedProvider);
  final isVerified = ref.read(isEmailVerifiedProvider);
  final path = state.matchedLocation;

  final isPublic = const [
    '/signin',
    '/signup',
    '/forgot-password',
    '/verify-email',
  ].any(path.startsWith);

  for (final guarded in [
    '/placeDetails',
    '/eventDetails',
    '/home',
    '/search',
    '/favorites',
    '/profile',
    '/changeName',
    '/theme-settings',
  ]) {
    if (path.startsWith(guarded)) {
      return (isAuth && isVerified) ? null : '/signin';
    }
  }

  if (path.startsWith('/changePassword')) {
    if (state.uri.queryParameters['from'] == 'forgot') return null;
    return (isAuth && isVerified) ? null : '/signin';
  }

  if (path.startsWith('/verify-email')) {
    if (isAuth && isVerified) return '/home';
    return (isAuth || state.uri.queryParameters.containsKey('email'))
        ? null
        : '/signin';
  }

  if (isAuth && isVerified) return isPublic ? '/home' : null;
  if (isAuth && !isVerified) return '/verify-email';
  return isPublic ? null : '/signin';
}

class _RouterNotifier extends ChangeNotifier {
  Timer? _debounce;

  _RouterNotifier(Ref ref) {
    ref.listen(supabaseReadyProvider, (_, isReady) {
      if (!isReady) return;
      _notify();
      ref.listen(authStateProvider, (prev, next) {
        if (prev != next) _notify();
      });
    });
  }

  void _notify() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), notifyListeners);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
