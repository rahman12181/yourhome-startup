import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yourhome/main.dart' show navigatorKey;
import 'package:yourhome/screens/bookings/booking_list_screen.dart';
import 'package:yourhome/screens/chat/chat_screen.dart';
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

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _navigateFromData(message.data);
      });

      _listenersAttached = true;
    }

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _navigateFromData(initialMessage.data);
    }
  }

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
  // Foreground notification — build payload with all data
  // =============================================
  static void _showNotification(RemoteMessage message) {
    String title = message.notification?.title ?? 'YourHome';
    String body = message.notification?.body ?? '';

    // Build complete payload with all chat data
    final payloadMap = <String, dynamic>{
      'type': message.data['type'],
      'refId': message.data['refId'],
    };
    if (message.data['conversationId'] != null) {
      payloadMap['conversationId'] = message.data['conversationId'];
    }
    if (message.data['senderId'] != null) {
      payloadMap['senderId'] = message.data['senderId'];
    }
    if (message.data['senderName'] != null) {
      payloadMap['senderName'] = message.data['senderName'];
    }
    if (message.data['senderPic'] != null) {
      payloadMap['senderPic'] = message.data['senderPic'];
    }

    final payload = jsonEncode(payloadMap);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'nestora_channel',
      'Nestora Notifications',
      channelDescription: 'Notifications from Nestora',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',              // ← CHANGED
      color: Color(0xFF0E7490),             // ← ADDED
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
      icon: 'ic_notification',              // ← CHANGED
      color: Color(0xFF0E7490),             // ← ADDED
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

    // Build complete payload
    final payloadMap = <String, dynamic>{
      'type': message.data['type'],
      'refId': message.data['refId'],
    };
    if (message.data['conversationId'] != null) {
      payloadMap['conversationId'] = message.data['conversationId'];
    }
    if (message.data['senderId'] != null) {
      payloadMap['senderId'] = message.data['senderId'];
    }
    if (message.data['senderName'] != null) {
      payloadMap['senderName'] = message.data['senderName'];
    }
    if (message.data['senderPic'] != null) {
      payloadMap['senderPic'] = message.data['senderPic'];
    }

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'YourHome',
      message.notification?.body ?? '',
      details,
      payload: jsonEncode(payloadMap),
    );
  }

  // =============================================
  // Tap handler (foreground local notification)
  // =============================================
  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    print('🔔 Local notification tapped: $payload');

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (e) {
      print('❌ Failed to parse notification payload: $e');
    }
  }

  // =============================================
  // NAVIGATE — handles BOOKING + CHAT
  // =============================================
  static Future<void> _navigateFromData(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final refId = data['refId'] as String?;

    print('🔔 Navigating for type=$type, refId=$refId, data=$data');

    final navState = navigatorKey.currentState;
    if (navState == null) {
      print('⚠️ navigatorKey has no state yet — cannot navigate');
      return;
    }

    // CHAT — open the specific conversation
    if (type == 'CHAT') {
      final convIdStr = data['conversationId']?.toString() ?? refId;
      final conversationId = int.tryParse(convIdStr ?? '');
      final senderId = int.tryParse(data['senderId']?.toString() ?? '');
      final senderName = data['senderName']?.toString() ?? 'User';
      final senderPic = data['senderPic']?.toString();

      if (conversationId != null && senderId != null) {
        navState.push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserId: senderId,
            otherUserName: senderName,
            otherUserPic: (senderPic != null && senderPic.isNotEmpty)
                ? senderPic
                : null,
          ),
        ));
      } else {
        print('⚠️ Invalid CHAT notification data: convId=$conversationId, senderId=$senderId');
        navState.push(MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ));
      }
      return;
    }

    // BOOKING
    if (type == 'BOOKING') {
      final role = await _storage.getUserRole();

      if (role == 'OWNER') {
        navState.push(MaterialPageRoute(
          builder: (_) => const OwnerBookingManagementPage(),
        ));
      } else {
        navState.push(MaterialPageRoute(
          builder: (_) => const BookingListScreen(),
        ));
      }
      return;
    }

    // Default
    navState.push(MaterialPageRoute(
      builder: (_) => const NotificationScreen(),
    ));
  }
}