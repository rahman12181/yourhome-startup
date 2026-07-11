import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yourhome/main.dart' show navigatorKey;
import 'package:yourhome/screens/bookings/booking_list_screen.dart';
import 'package:yourhome/screens/notifications/notification_screen.dart';
import 'package:yourhome/screens/owner/owner_booking_management_page.dart';
import 'package:yourhome/services/api_service.dart';
import 'package:yourhome/services/storage_service.dart';

class FcmService {
  static final ApiService _api = ApiService();
  static final StorageService _storage = StorageService();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _listenersAttached = false;

  /// Call ONCE from main.dart, before login state is known.
  /// Sets up permissions, local notifications, and listeners.
  /// Does NOT save token to server (user may not be logged in yet).
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      // ✅ Fires when the LOCAL notification (shown while app is foreground)
      // is tapped. We now route this through the same navigation logic.
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(response.payload);
      },
    );

    NotificationSettings fcmSettings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    if (fcmSettings.authorizationStatus != AuthorizationStatus.authorized) {
      print('❌ Push notification permission denied');
    } else {
      print('✅ Push notification permission granted');
    }

    if (!_listenersAttached) {
      // Token refresh — only push to server if user is currently logged in.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token refreshed: $newToken');
        final loggedIn = await _storage.getAccessToken();
        if (loggedIn != null) {
          await _saveTokenToServer(newToken);
        }
      });

      // App is OPEN (foreground) when the push arrives — show a local
      // notification. Tapping it is handled by onDidReceiveNotificationResponse above.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      // App was in BACKGROUND (not killed) and user tapped the system notification.
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _navigateForType(message.data['type'], message.data['refId']);
      });

      _listenersAttached = true;
    }

    // App was fully KILLED and opened via notification tap.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _navigateForType(initialMessage.data['type'], initialMessage.data['refId']);
    }
  }

  /// Call AFTER successful login/signup, AND after auto-login/splash
  /// check confirms an existing valid session. Safe to call multiple
  /// times — it always re-checks login state itself.
  static Future<void> syncToken() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) {
      print('ℹ️ Skipping FCM token sync — user not logged in');
      return;
    }

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        await _saveTokenToServer(token);
      }
    } catch (e) {
      print('❌ Failed to fetch FCM token: $e');
    }
  }

  /// Call on logout so this device stops receiving push for the old user.
  static Future<void> clearToken() async {
    try {
      await _api.dio.delete('/user/fcm-token');
      print('✅ FCM Token cleared from server');
    } catch (e) {
      print('❌ Failed to clear FCM token: $e');
    }
  }

  static Future<void> _saveTokenToServer(String token) async {
    try {
      await _api.put('/user/fcm-token', data: {'fcmToken': token});
      print('✅ FCM Token saved to server');
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
    }
  }

  // =============================================
  // Show system notification while app is in foreground.
  // Payload is now a JSON string carrying BOTH type + refId, so tapping
  // it (handled in _handleNotificationTap) can navigate exactly like the
  // background/killed cases do.
  // =============================================
  static void _showNotification(RemoteMessage message) {
    String title = message.notification?.title ?? 'YourHome';
    String body = message.notification?.body ?? '';

    final payload = jsonEncode({
      'type': message.data['type'],
      'refId': message.data['refId'],
    });

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'nestora_channel',
      'Nestora Notifications',
      channelDescription: 'Notifications from Nestora',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'nestora_channel',
      'Nestora Notifications',
      channelDescription: 'Notifications from Nestora',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'YourHome',
      message.notification?.body ?? '',
      details,
      payload: jsonEncode({
        'type': message.data['type'],
        'refId': message.data['refId'],
      }),
    );
  }

  // =============================================
  // Fired when the user taps the LOCAL notification we showed ourselves
  // (i.e. the app was OPEN/foreground when the push arrived).
  // =============================================
  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    print('🔔 Local notification tapped: $payload');

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateForType(data['type'] as String?, data['refId'] as String?);
    } catch (e) {
      print('❌ Failed to parse notification payload: $e');
    }
  }

  // =============================================
  // ✅ SINGLE SOURCE OF TRUTH for navigation — used by all 3 states:
  // foreground tap, background tap, killed-app tap.
  // =============================================
  static Future<void> _navigateForType(String? type, String? refId) async {
    print('🔔 Navigating for type=$type, refId=$refId');

    final navState = navigatorKey.currentState;
    if (navState == null) {
      print('⚠️ navigatorKey has no state yet — cannot navigate');
      return;
    }

    if (type == 'BOOKING') {
      final role = await _storage.getUserRole();

      if (role == 'OWNER') {
        // Owner ko naya booking request aaya — booking management page
        navState.push(MaterialPageRoute(
          builder: (_) => const OwnerBookingManagementPage(),
        ));
      } else {
        // Student ko uske booking ka accept/reject status mila — booking list
        navState.push(MaterialPageRoute(
          builder: (_) => const BookingListScreen(),
        ));
      }
      return;
    }

    navState.push(MaterialPageRoute(
      builder: (_) => const NotificationScreen(),
    ));
  }
}