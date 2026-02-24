import 'package:flutter/material.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_name_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/home_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/profile_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signin_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signup_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/splash_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/verify_email_page.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/verify-email',
    debugLogDiagnostics: true,
    redirect: (context, state) => _redirect(ref, state),
    refreshListenable: GoRouterRefreshNotifier(ref),
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // Auth Routes (Public)
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
        name: RouteNames.forgotPassword, // ← was wrongly using resetPassword
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
        builder: (context, state) {
          return const ChangeNamePage();
        },
      ),
      GoRoute(
        name: RouteNames.verifyEmail,
        path: '/verify-email',
        builder: (context, state) => VerifyEmailPage(
          email: state.uri.queryParameters['email'],
          type: state.uri.queryParameters['type'], // <-- THIS LINE IS MISSING
        ),
      ),

      // Protected Routes
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}

String? _redirect(Ref ref, GoRouterState state) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  final isEmailVerified = ref.read(isEmailVerifiedProvider);

  final path = state.matchedLocation;

  // Define which pages are public (don't require auth)
  final publicPages = [
    '/splash',
    '/signin',
    '/signup',
    '/forgot-password',
    '/verify-email',
  ];
  final isOnPublicPage = publicPages.any((p) => path.startsWith(p));

  // Splash - redirect to appropriate page based on auth state
  if (path == '/splash') {
    if (isAuthenticated && isEmailVerified) {
      return '/home';
    }
    if (isAuthenticated && !isEmailVerified) {
      return '/verify-email';
    }
    return null; // Stay on splash, let splash page handle navigation
  }
  // Add this block BEFORE the "User is fully authenticated" check
  if (path.startsWith('/changePassword')) {
    // Allow unauthenticated access only when coming from forgot password flow
    final fromForgot = state.uri.queryParameters['from'] == 'forgot';
    if (fromForgot) return null; // forgot password flow — let through

    // In-app flow — must be authenticated
    if (isAuthenticated && isEmailVerified) return null;
    return '/signin';
  }
  // CRITICAL: Allow verify-email page for new signups (with email parameter)
  if (path.startsWith('/verify-email')) {
    // ✅ If user just verified their email, they're now fully authenticated.
    // Must check this BEFORE hasEmailParam, otherwise the email query param
    // causes this block to return null and the user is stuck on this page forever.
    if (isAuthenticated && isEmailVerified) {
      return '/home';
    }

    final hasEmailParam = state.uri.queryParameters.containsKey('email');
    if ((isAuthenticated && !isEmailVerified) || hasEmailParam) {
      return null;
    }
    return '/signin';
  }

  // User is fully authenticated (logged in + email verified)
  if (isAuthenticated && isEmailVerified) {
    // Redirect from auth pages to home
    if (isOnPublicPage) {
      return '/home';
    }
    // Allow access to protected pages
    return null;
  }

  // User is logged in but email NOT verified
  if (isAuthenticated && !isEmailVerified) {
    // Force to verify-email page
    return '/verify-email';
  }

  // User is NOT logged in
  // Allow public pages
  if (isOnPublicPage) {
    return null;
  }

  // Redirect protected pages to signin
  return '/signin';
}

// Notifier to refresh router on auth changes
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
