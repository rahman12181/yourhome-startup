// lib/constants/app_constants.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (Platform.isAndroid) {
      return 'http://192.168.0.109:8080';
    }
    if (Platform.isIOS) {
      return 'http://192.168.0.101:8080';
    }
    return 'http://10.0.2.2:8080';
  }

  // ✅ WEBSOCKET URL - FIXED: http:// → ws://
  static String get wsUrl {
    if (kIsWeb) {
      return 'ws://localhost:8080/ws';
    }
    if (Platform.isAndroid) {
      return 'ws://192.168.0.109:8080/ws';
    }
    if (Platform.isIOS) {
      return 'ws://192.168.0.101:8080/ws';
    }
    return 'ws://10.0.2.2:8080/ws';
  }

  static const String appName = 'YourHome';
  static const String appVersion = '1.0.0';

  static const String razorpayKeyId = 'rzp_test_TADkxkSOWt1ERB';

  static const List<String> propertyTypes = ['PG', 'HOSTEL', 'HOTEL', 'FLAT', 'ROOM'];
  static const List<String> genderOptions = ['BOYS', 'GIRLS', 'BOTH'];
  static const List<String> roomTypes = ['SINGLE', 'DOUBLE', 'TRIPLE', 'DORMITORY'];

  static const List<String> amenities = [
    'WiFi',
    'AC',
    'Meals',
    'Laundry',
    'CCTV',
    'Parking',
    'Gym',
    'Hot Water',
    'Power Backup',
    'Security',
    'TV',
    'Fridge',
  ];

  static const List<String> subscriptionPlans = [
    'BASIC',
    'STANDARD',
    'PREMIUM',
    'ENTERPRISE',
  ];

  static const Map<String, double> planPrices = {
    'BASIC': 399.0,
    'STANDARD': 599.0,
    'PREMIUM': 799.0,
    'ENTERPRISE': 999.0,
  };

  static const Map<String, int> planMaxRooms = {
    'BASIC': 5,
    'STANDARD': 10,
    'PREMIUM': 20,
    'ENTERPRISE': 999,
  };

  static const Map<String, int> propertyAccessDurations = {
    'MONTHLY_1': 1,
    'MONTHLY_2': 2,
    'MONTHLY_3': 3,
    'MONTHLY_4': 4,
    'MONTHLY_5': 5,
  };

  static const Map<String, double> propertyAccessPrices = {
    'MONTHLY_1': 599.0,
    'MONTHLY_2': 899.0,
    'MONTHLY_3': 1299.0,
    'MONTHLY_4': 1599.0,
    'MONTHLY_5': 1899.0,
  };

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyThemeMode = 'theme_mode';
  static const String keyProfileImage = 'profile_image';
}