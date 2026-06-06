import 'dart:async';

import 'package:flutter/material.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_email_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_name_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/change_phone_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signin_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/signup_page.dart';
import 'package:future_riverpod/features/auth/presentation/pages/verify_email_page.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:future_riverpod/features/booking/presentation/booking_flow_page.dart';
import 'package:future_riverpod/features/bookings_history/presentation/pages/bookings_history_page.dart';
import 'package:future_riverpod/features/bookings_history/presentation/pages/ticket_detail_page.dart';
import 'package:future_riverpod/features/bottom_bar/widgets/nav_shell.dart';
import 'package:future_riverpod/features/events/presentation/pages/event_details_page.dart';
import 'package:future_riverpod/features/favorites/presentation/pages/favorites_page.dart';
import 'package:future_riverpod/features/home/presentation/pages/home_page.dart';
import 'package:future_riverpod/features/home/presentation/pages/splash_page.dart';
import 'package:future_riverpod/features/notifications/fcm_service.dart';
import 'package:future_riverpod/features/notifications/presentation/pages/notifications_page.dart';
import 'package:future_riverpod/features/places/presentation/pages/place_details_page.dart';
import 'package:future_riverpod/features/profile/presentation/pages/profile_page.dart';
import 'package:future_riverpod/features/profile/presentation/pages/theme_settings_page.dart';
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
        path: '/complete-profile',
        name: RouteNames.completeProfile,
        builder: (_, _) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/changeName',
        name: RouteNames.changeName,
        builder: (_, _) => const ChangeNamePage(),
      ),
      GoRoute(
        path: '/changePhone',
        name: RouteNames.changePhone,
        builder: (_, _) => const ChangePhonePage(),
      ),
      GoRoute(
        path: '/changeEmail',
        name: RouteNames.changeEmail,
        builder: (_, _) => const ChangeEmailPage(),
      ),
      GoRoute(
        path: '/changePassword',
        name: RouteNames.changePassword,
        builder: (_, s) => ChangePasswordPage(
          fromForgotPassword: s.uri.queryParameters['from'] == 'forgot',
        ),
      ),
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
      GoRoute(
        path: '/theme-settings',
        name: RouteNames.themeSettings,
        builder: (_, s) => ThemeSettingsPage(isAr: s.extra as bool),
      ),
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
                path: '/bookings',
                name: RouteNames.bookingsHistory,
                builder: (_, _) => const BookingsHistoryPage(),
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
      GoRoute(
        path: '/bookings/:id',
        name: RouteNames.ticketDetail,
        builder: (_, s) =>
            TicketDetailPage(id: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/search',
        name: RouteNames.search,
        builder: (_, _) => const SearchPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/place/:placeId/book',
        name: RouteNames.bookingFlow,
        builder: (_, s) => BookingFlowPage(
          placeId: s.pathParameters['placeId'] ?? '',
          category: s.uri.queryParameters['category'],
        ),
      ),
      GoRoute(
        path: '/event/:eventId/book',
        name: RouteNames.eventBookingFlow,
        builder: (_, s) =>
            BookingFlowPage(placeId: '', eventId: s.pathParameters['eventId']),
      ),
    ],
  );
}

String? _redirect(Ref ref, GoRouterState state) {
  if (state.matchedLocation == '/splash') {
    if (!ref.read(supabaseReadyProvider)) return null; // still initialising
    final isAuth = ref.read(isAuthenticatedProvider);
    final isVerified = ref.read(isEmailVerifiedProvider);
    if (!isAuth) return '/signin';
    if (!isVerified) return '/verify-email';
    // Wait here until profileProvider resolves — prevents /home from showing
    // for a frame before we know the profile is incomplete.
    final isComplete = ref.read(isProfileCompleteProvider);
    if (isComplete == null) return null;
    return isComplete ? '/home' : '/complete-profile';
  }

  if (!ref.read(supabaseReadyProvider)) return '/splash';

  final isAuth = ref.read(isAuthenticatedProvider);
  final isVerified = ref.read(isEmailVerifiedProvider);
  final path = state.matchedLocation;

  // Profile completeness gate. `null` while the profile is still loading —
  // in that case we stay on the current location to avoid bouncing.
  final isComplete = (isAuth && isVerified)
      ? ref.read(isProfileCompleteProvider)
      : null;

  // Check for pending FCM route (cold-start deep link from notification)
  if (isAuth && isVerified && isComplete == true) {
    final pendingRoute = FcmService.instance.consumePendingRoute();
    if (pendingRoute != null) {
      return pendingRoute;
    }
  }

  final isPublic = const [
    '/signin',
    '/signup',
    '/forgot-password',
    '/verify-email',
  ].any(path.startsWith);

  // Signed-in + verified users with an incomplete profile must finish the
  // /complete-profile flow before they can access any guarded route.
  if (isAuth && isVerified && isComplete == false) {
    return path == '/complete-profile' ? null : '/complete-profile';
  }
  // Once complete, keep them out of /complete-profile.
  if (path == '/complete-profile') {
    if (!isAuth || !isVerified) return '/signin';
    if (isComplete == true) return '/home';
    return null;
  }

  for (final guarded in [
    '/placeDetails',
    '/eventDetails',
    '/home',
    '/search',
    '/favorites',
    '/profile',
    '/changeName',
    '/changePhone',
    '/theme-settings',
    '/place',
    '/event',
    '/bookings',
    '/notifications',
  ]) {
    if (path.startsWith(guarded)) {
      return (isAuth && isVerified) ? null : '/signin';
    }
  }

  if (path.startsWith('/changePassword')) {
    if (state.uri.queryParameters['from'] == 'forgot') return null;
    return (isAuth && isVerified) ? null : '/signin';
  }

  // Allow email-change routes regardless of isVerified so a userUpdated
  // auth event during the updateUser call can't redirect mid-flow.
  if (path.startsWith('/changeEmail')) return isAuth ? null : '/signin';

  if (path.startsWith('/verify-email')) {
    // Always allow the email-change OTP flow for authenticated users.
    if (state.uri.queryParameters['type'] == 'email_change') return null;
    if (isAuth && isVerified) {
      // Don't bounce to /home until we know whether the profile is complete —
      // otherwise the user lands on /home with a hung loading state while the
      // redirect waits for profileProvider to settle. The completeness branch
      // above handles isComplete==false; here we only act when known-true.
      if (isComplete == true) return '/home';
      return null; // stay on /verify-email until isComplete is known
    }
    return (isAuth || state.uri.queryParameters.containsKey('email'))
        ? null
        : '/signin';
  }

  if (isAuth && isVerified) {
    // Same rule as above for the other public auth pages — wait until we
    // know the profile state before sending the user to /home.
    if (isPublic) {
      if (isComplete == true) return '/home';
      return null;
    }
    return null;
  }
  if (isAuth && !isVerified) return '/verify-email';
  return isPublic ? null : '/signin';
}

class _RouterNotifier extends ChangeNotifier {
  Timer? _debounce;

  _RouterNotifier(Ref ref) {
    // FIX: The original code had a NESTED ref.listen:
    //
    //   ref.listen(supabaseReadyProvider, (_, isReady) {
    //     if (!isReady) return;
    //     _notify();
    //     ref.listen(authStateProvider, ...);  ← nested, registered late
    //   });
    //
    // The nested ref.listen on authStateProvider was only registered AFTER
    // supabaseReadyProvider first became true. If supabaseReadyProvider fired
    // before authStateProvider was built, the auth listener was set up
    // during a provider-callback context, which is fragile and can cause
    // the auth listener to miss events or fire at unexpected times,
    // contributing to the cascade of state changes.
    //
    // FIX: Register both listeners up front, side by side.
    // - The supabaseReady listener gates the first notify (same as before).
    // - The authState listener is always registered but only notifies when
    //   Supabase is already ready, preventing spurious redirects on startup.

    ref.listen(supabaseReadyProvider, (_, isReady) {
      if (isReady) _notify();
    });

    ref.listen(currentUserProvider, (prev, next) {
      // Only notify GoRouter after Supabase is ready — prevents a redirect
      // attempt while still on the splash screen.
      if (!ref.read(supabaseReadyProvider)) return;
      if (prev != next) _notify();
    });

    // Profile-completion changes (null → true/false) drive the
    // /complete-profile redirect — refresh GoRouter whenever it flips.
    ref.listen(isProfileCompleteProvider, (prev, next) {
      if (!ref.read(supabaseReadyProvider)) return;
      if (prev != next) _notify();
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
