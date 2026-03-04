import 'package:flutter/material.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_name_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/home_test.dart';
import 'package:future_riverpod/features/auth/presentation/pages/profile_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signin_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signup_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/splash_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/verify_email_page.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/home/presentation/pages/favorites_page.dart';
import 'package:future_riverpod/features/home/presentation/pages/home_page.dart';
import 'package:future_riverpod/features/home/presentation/widgets/nav_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

// ── Placeholder pages for branches that are not yet built ────────────────────
// Replace these with your real Explore / Map pages when ready.
class _ExplorePage extends StatelessWidget {
  const _ExplorePage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Explore — coming soon')));
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/signin',
    debugLogDiagnostics: true,
    redirect: (context, state) => _redirect(ref, state),
    refreshListenable: GoRouterRefreshNotifier(ref),
    routes: [
      // ── Splash ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // ── Auth routes (public) ───────────────────────────────────────────────
      GoRoute(
        path: '/signin',
        name: RouteNames.signin,
        builder: (context, state) => const SigninPage(),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/changePassword',
        name: RouteNames.changePassword,
        builder: (context, state) {
          final fromForgot = state.uri.queryParameters['from'] == 'forgot';
          return ChangePasswordPage(fromForgotPassword: fromForgot);
        },
      ),
      GoRoute(
        path: '/changeName',
        name: RouteNames.changeName,
        builder: (context, state) => const ChangeNamePage(),
      ),
      GoRoute(
        name: RouteNames.verifyEmail,
        path: '/verify-email',
        builder: (context, state) => VerifyEmailPage(
          email: state.uri.queryParameters['email'],
          type: state.uri.queryParameters['type'],
        ),
      ),

      // ── Dev / test route ───────────────────────────────────────────────────
      GoRoute(
        path: '/test',
        name: RouteNames.test,
        builder: (context, state) => const HomeTest(),
      ),

      // ── Bottom-nav shell (protected) ───────────────────────────────────────
      // StatefulShellRoute keeps every branch alive in an IndexedStack so that
      // navigating between tabs does NOT reset scroll position or page state.
      StatefulShellRoute.indexedStack(
        // The shell wraps the branches and draws the BottomBar.
        builder: (context, state, navigationShell) =>
            NavShell(navigationShell: navigationShell),

        branches: [
          // ── Branch 0 : Home ────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),

          // ── Branch 1 : Explore ─────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                // Add RouteNames.explore to your RouteNames class
                name: 'explore',
                builder: (context, state) => const _ExplorePage(),
              ),
            ],
          ),

          // ── Branch 2 : Map ─────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                // Add RouteNames.favorites to your RouteNames class
                name: RouteNames.favorites,
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),

          // ── Branch 3 : Profile ─────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ── Redirect logic ─────────────────────────────────────────────────────────────
String? _redirect(Ref ref, GoRouterState state) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  final isEmailVerified = ref.read(isEmailVerifiedProvider);

  final path = state.matchedLocation;

  final publicPages = [
    '/splash',
    '/signin',
    '/signup',
    '/forgot-password',
    '/verify-email',
  ];

  // Protected shell paths — any sub-route of the bottom-nav
  final shellPaths = ['/home', '/explore', '/map', '/profile'];
  shellPaths.any((p) => path.startsWith(p));
  final isOnPublicPage = publicPages.any((p) => path.startsWith(p));

  // Splash
  if (path == '/splash') {
    if (isAuthenticated && isEmailVerified) return '/home';
    if (isAuthenticated && !isEmailVerified) return '/verify-email';
    return null;
  }

  // changePassword — allow unauthenticated only from forgot-password flow
  if (path.startsWith('/changePassword')) {
    final fromForgot = state.uri.queryParameters['from'] == 'forgot';
    if (fromForgot) return null;
    if (isAuthenticated && isEmailVerified) return null;
    return '/signin';
  }

  // Verify email
  if (path.startsWith('/verify-email')) {
    if (isAuthenticated && isEmailVerified) return '/home';
    final hasEmailParam = state.uri.queryParameters.containsKey('email');
    if ((isAuthenticated && !isEmailVerified) || hasEmailParam) return null;
    return '/signin';
  }

  // Fully authenticated
  if (isAuthenticated && isEmailVerified) {
    if (isOnPublicPage) return '/home';
    return null; // allow everything else (shell pages, changeName, etc.)
  }

  // Authenticated but email not verified
  if (isAuthenticated && !isEmailVerified) {
    return '/verify-email';
  }

  // Not authenticated
  if (isOnPublicPage) return null;
  return '/signin';
}

// ── Router refresh notifier ───────────────────────────────────────────────────
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
