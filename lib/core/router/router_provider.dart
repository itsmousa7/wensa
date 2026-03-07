import 'dart:async';

import 'package:flutter/material.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_name_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/home_test.dart';
import 'package:future_riverpod/features/auth/presentation/pages/profile_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signin_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signup_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/verify_email_page.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/home/presentation/pages/favorites_page.dart';
import 'package:future_riverpod/features/home/presentation/pages/home_page.dart';
import 'package:future_riverpod/features/home/presentation/pages/splash_page.dart';
import 'package:future_riverpod/features/home/presentation/widgets/nav_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

// ✅ Riverpod generator — no legacy providers
// Set to true by SplashPage after Supabase.initialize() completes
@riverpod
class SupabaseReady extends _$SupabaseReady {
  @override
  bool build() => false;
  void setReady() => state = true;
}

class _ExplorePage extends StatelessWidget {
  const _ExplorePage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Explore — coming soon')));
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (_, state) => _redirect(ref, state),
    refreshListenable: _RouterNotifier(ref),
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/signin',
        name: RouteNames.signin,
        builder: (_, __) => const SigninPage(),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (_, __) => const SignupPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
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
        builder: (_, __) => const ChangeNamePage(),
      ),
      GoRoute(
        path: '/test',
        name: RouteNames.test,
        builder: (_, __) => const HomeTest(),
      ),
      GoRoute(
        path: '/changePassword',
        name: RouteNames.changePassword,
        builder: (_, s) => ChangePasswordPage(
          fromForgotPassword: s.uri.queryParameters['from'] == 'forgot',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => NavShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                name: 'explore',
                builder: (_, __) => const _ExplorePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: RouteNames.favorites,
                builder: (_, __) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _redirect(Ref ref, GoRouterState state) {
  // Splash owns its own navigation — never touch it here
  if (state.matchedLocation == '/splash') return null;

  // Supabase not ready yet — stay on splash
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

// ✅ Notifier — debounced + guards against pre-init auth reads
class _RouterNotifier extends ChangeNotifier {
  Timer? _debounce;

  _RouterNotifier(Ref ref) {
    ref.listen(supabaseReadyProvider, (_, isReady) {
      if (!isReady) return;
      // Supabase just became ready — trigger one redirect
      _notify();
      // Now safe to listen to auth changes
      ref.listen(authStateProvider, (prev, next) {
        // Only notify on actual state change
        if (prev != next) _notify();
      });
    });
  }

  void _notify() {
    // Debounce 300ms — collapses burst of auth events into one redirect
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), notifyListeners);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
