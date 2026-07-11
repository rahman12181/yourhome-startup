import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yourhome/main.dart' show navigatorKey;
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

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      // ✅ App was in background and user tapped the notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNavigation(message);
      });

      _listenersAttached = true;
    }

    // ✅ App was fully killed and opened via notification tap
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
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

  static void _showNotification(RemoteMessage message) {
    String title = message.notification?.title ?? 'Nestora';
    String body = message.notification?.body ?? '';
    String? payload = message.data['type'];

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
      message.notification?.title ?? 'Nestora',
      message.notification?.body ?? '',
      details,
      payload: message.data['type'],
    );
  }

  // =============================================
  // ✅ UPDATED — Navigate based on notification type + user role
  // =============================================
  static void _handleNavigation(RemoteMessage message) async {
    final type = message.data['type'];
    final refId = message.data['refId'];
    print('🔔 Notification tapped: type=$type, refId=$refId');

    final navState = navigatorKey.currentState;
    if (navState == null) {
      print('⚠️ navigatorKey has no state yet — cannot navigate');
      return;
    }

    if (type == 'BOOKING') {
      // Owner ko booking management page, User ko notification screen
      final role = await _storage.getUserRole();

      if (role == 'OWNER') {
        navState.push(MaterialPageRoute(
          builder: (_) => const OwnerBookingManagementPage(),
        ));
      } else {
        navState.push(MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ));
      }
      return;
    }

    // VERIFICATION, PAYMENT, SYSTEM, CHAT, aur baaki sab types —
    // NotificationScreen role-wise sab khud handle kar leta hai
    navState.push(MaterialPageRoute(
      builder: (_) => const NotificationScreen(),
    ));
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    print('🔔 Local notification tapped: $payload');
  }
}