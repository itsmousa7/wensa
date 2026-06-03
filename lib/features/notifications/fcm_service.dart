import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Increments every time a remote push arrives (foreground, background tap,
/// or cold-start). UI listens to this to refresh the in-app inbox + bell badge
/// without polling.
final ValueNotifier<int> fcmEventTick = ValueNotifier<int>(0);

const _kChannelId = 'wensa_default';
const _kChannelName = 'Wensa Notifications';

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  String? _pendingRoute;

  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize FCM: request permission, get token, listen to events
  Future<void> initialize(SupabaseClient supabase) async {
    try {
      await _initLocalNotifications();

      // 1. Request permission (iOS specifically, Android auto-grants pre-33)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] User denied notification permission');
        return;
      }

      // 2. Get and store initial token (only if already signed in)
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveToken(supabase, token);
      }

      // 3. Sync preferred_locale on startup so the backend is always current
      await _saveLocale(supabase);

      // 4. Re-save token whenever the user signs in (handles post-startup logins)
      supabase.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          FirebaseMessaging.instance.getToken().then((t) {
            if (t != null) _saveToken(supabase, t);
          });
          _saveLocale(supabase);
        }
      });

      // 5. Listen for token refresh and save updated tokens
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) => _saveToken(supabase, newToken),
      );

      // 6. Foreground message handler (app is in the foreground)
      FirebaseMessaging.onMessage.listen(_handleForeground);

      // 7. Background tap handler (user tapped notification while app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // 8. Check if app was launched from terminated state by tapping a notification
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleTap(initial);
      }

      debugPrint('[FCM] Initialized successfully');
    } catch (e) {
      debugPrint('[FCM] Initialization failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/app_icons');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Create the Android high-importance channel once
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _kChannelId,
            _kChannelName,
            importance: Importance.high,
          ),
        );
  }

  /// Save FCM token to Supabase profiles.app_users table
  Future<void> _saveToken(SupabaseClient supabase, String token) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        debugPrint('[FCM] No authenticated user; skipping token save');
        return;
      }

      await supabase
          .schema('profiles')
          .from('app_users')
          .update({'fcm_token': token})
          .eq('id', uid);
      debugPrint('[FCM] Token saved for user $uid');
      debugPrint('[FCM] TOKEN: $token');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// Sync preferred_locale from SharedPreferences to Supabase
  Future<void> _saveLocale(SupabaseClient supabase) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_locale');
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

  /// Show an in-app notification banner when the app is in the foreground
  void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? '';
    final body = notification.body ?? '';
    debugPrint('[FCM foreground] $title: $body');

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    fcmEventTick.value++;
  }

  /// Handle notification tap (app was backgrounded or terminated)
  void _handleTap(RemoteMessage message) {
    final bookingId = message.data['booking_id'] as String?;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    debugPrint('[FCM tap] Title: $title, Body: $body, BookingID: $bookingId');

    if (bookingId != null && bookingId.isNotEmpty) {
      _pendingRoute = '/bookings/$bookingId';
      debugPrint('[FCM] Pending route set to: $_pendingRoute');
    }

    fcmEventTick.value++;
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
