import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// The FCM token currently registered for this device. Kept so we can remove
  /// exactly this device's token from the backend on sign-out.
  String? _currentToken;

  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _badgeChannel = MethodChannel('app.wensa.mobile/badge');

  /// Reset the OS app-icon badge to zero. iOS keeps the springboard badge until
  /// the app clears it explicitly; call this once the user has read their inbox.
  Future<void> clearBadge() async {
    try {
      await _badgeChannel.invokeMethod('clearBadge');
    } catch (e) {
      debugPrint('[FCM] Failed to clear badge: $e');
    }
  }

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

      // 2a. On iOS, the FCM token is unavailable until the APNs device token
      // has been registered. Wait for it (a few retries) before getToken().
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 5; i++) {
          if (await FirebaseMessaging.instance.getAPNSToken() != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // 2b. Get and store the FCM token (only saved if a user is signed in).
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveToken(supabase, token);
      }

      // 3. Sync preferred_locale on startup so the backend is always current
      await _saveLocale(supabase);

      // 4. Re-save token on sign-in; remove this device's token on sign-out so
      // a logged-out device stops receiving the previous user's notifications.
      supabase.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          FirebaseMessaging.instance.getToken().then((t) {
            if (t != null) _saveToken(supabase, t);
          });
          _saveLocale(supabase);
        } else if (data.event == AuthChangeEvent.signedOut) {
          _deleteToken(supabase);
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
    await _localNotifications.initialize(settings: initSettings);

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

  /// Register this device's FCM token in profiles.user_fcm_tokens (one row per
  /// device) so every device signed into the account receives notifications.
  Future<void> _saveToken(SupabaseClient supabase, String token) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        debugPrint('[FCM] No authenticated user; skipping token save');
        return;
      }

      _currentToken = token;
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      // Persist THIS device's notification language alongside its token so the
      // backend pushes in the language this device is showing — independent of
      // any other device signed into the same account.
      final locale = await _effectiveLocale();

      await supabase.rpc(
        'save_fcm_token',
        params: {'p_token': token, 'p_platform': platform, 'p_locale': locale},
      );
      debugPrint('[FCM] Token saved for user $uid (locale=$locale)');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// Re-save this device's token with its current app language. Called when the
  /// user switches the in-app language so notifications for THIS device follow
  /// it, without waiting for a token refresh.
  Future<void> updateDeviceLocale() async {
    final token = _currentToken;
    if (token == null) return;
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) return;
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      final locale = await _effectiveLocale();
      await supabase.rpc(
        'save_fcm_token',
        params: {'p_token': token, 'p_platform': platform, 'p_locale': locale},
      );
      debugPrint('[FCM] Device locale updated to $locale');
    } catch (e) {
      debugPrint('[FCM] Failed to update device locale: $e');
    }
  }

  /// Remove this device's token on sign-out so it no longer receives the
  /// previous user's notifications. Other devices on the account are untouched.
  Future<void> _deleteToken(SupabaseClient supabase) async {
    final token = _currentToken;
    if (token == null) return;
    try {
      await supabase.rpc('delete_fcm_token', params: {'p_token': token});
      _currentToken = null;
      debugPrint('[FCM] Token removed on sign-out');
    } catch (e) {
      debugPrint('[FCM] Failed to remove token: $e');
    }
  }

  /// Sync the effective notification language to Supabase so the backend sends
  /// pushes in the language the app is actually displaying. When the user has
  /// not made an explicit choice (system mode) this resolves the device
  /// language, so leaving the app on its default still produces matching pushes.
  Future<void> _saveLocale(SupabaseClient supabase) async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final locale = await _effectiveLocale();
      await supabase
          .schema('profiles')
          .from('app_users')
          .update({'preferred_locale': locale})
          .eq('id', uid);
      debugPrint('[FCM] Synced preferred_locale=$locale');
    } catch (e) {
      debugPrint('[FCM] Failed to sync locale: $e');
    }
  }

  /// The language notifications should use: an explicit 'ar'/'en' choice if the
  /// user picked one, otherwise the device language resolved against the two
  /// locales the app supports (Arabic, else English — matching MaterialApp's
  /// supportedLocales).
  Future<String> _effectiveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_locale');
    if (saved == 'ar' || saved == 'en') return saved!;
    return PlatformDispatcher.instance.locale.languageCode == 'ar'
        ? 'ar'
        : 'en';
  }

  /// Show an in-app notification banner when the app is in the foreground
  void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? '';
    final body = notification.body ?? '';
    debugPrint('[FCM foreground] $title: $body');

    _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
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
