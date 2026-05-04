// FCM SETUP REQUIRED:
// 1. Run `flutterfire configure` (install CLI: `dart pub global activate flutterfire_cli`)
// 2. This generates lib/firebase_options.dart — commit it
// 3. In Firebase Console: enable Cloud Messaging, add iOS/Android app
// 4. For iOS: add push notification capability in Xcode + download GoogleService-Info.plist
// 5. For Android: download google-services.json → android/app/
// 6. In main.dart: uncomment the `options:` line in Firebase.initializeApp()

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  String? _pendingRoute;

  /// Initialize FCM: request permission, get token, listen to events
  Future<void> initialize(SupabaseClient supabase) async {
    try {
      // 1. Request permission (iOS specifically, Android auto-grants)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] User denied notification permission');
        return;
      }

      // 2. Get and store initial token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveToken(supabase, token);
      }

      // 3a. Sync preferred_locale on startup so the backend is always current
      await _saveLocale(supabase);

      // 3. Listen for token refresh and save updated tokens
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) => _saveToken(supabase, newToken),
      );

      // 4. Foreground message handler (app is in the foreground)
      FirebaseMessaging.onMessage.listen(_handleForeground);

      // 5. Background tap handler (user tapped notification while app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // 6. Check if app was launched from terminated state by tapping a notification
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleTap(initial);
      }

      debugPrint('[FCM] Initialized successfully');
    } catch (e) {
      debugPrint('[FCM] Initialization failed: $e');
      // Non-fatal: FCM won't work until properly configured, but app continues
    }
  }

  /// Save FCM token to Supabase app_users table
  Future<void> _saveToken(SupabaseClient supabase, String token) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        debugPrint('[FCM] No authenticated user; skipping token save');
        return;
      }

      await supabase.from('app_users').update({'fcm_token': token}).eq('id', uid);
      debugPrint('[FCM] Token saved for user $uid');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
      // Best-effort; don't crash if table not ready or offline
    }
  }

  /// Sync preferred_locale from SharedPreferences to Supabase
  Future<void> _saveLocale(SupabaseClient supabase) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_locale');
      // Only sync explicit ar/en choices; skip 'system' or unset
      if (saved != 'ar' && saved != 'en') return;
      await supabase
          .schema('profiles')
          .from('app_users')
          .update({'preferred_locale': saved})
          .eq('id', uid);
      debugPrint('[FCM] Synced preferred_locale=$saved');
    } catch (e) {
      debugPrint('[FCM] Failed to sync locale: $e');
    }
  }

  /// Handle notification when app is in foreground
  void _handleForeground(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    debugPrint('[FCM foreground] $title: $body');

    // TODO: Show in-app banner/overlay with FlutterOverlayWindow or similar
    // For now, just logging. Full UI implementation in polish phase.
  }

  /// Handle notification tap (app was backgrounded or terminated)
  void _handleTap(RemoteMessage message) {
    final bookingId = message.data['booking_id'] as String?;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    debugPrint(
      '[FCM tap] Title: $title, Body: $body, BookingID: $bookingId',
    );

    if (bookingId != null && bookingId.isNotEmpty) {
      // Store the route to navigate once the router is ready
      _pendingRoute = '/bookings/$bookingId';
      debugPrint('[FCM] Pending route set to: $_pendingRoute');
    }
  }

  /// Consume the pending route (called by router on first check after auth)
  String? consumePendingRoute() {
    final route = _pendingRoute;
    if (route != null) {
      _pendingRoute = null;
      debugPrint('[FCM] Consumed pending route: $route');
    }
    return route;
  }
}
