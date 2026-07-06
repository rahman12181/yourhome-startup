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
  
  static const String appName = 'YourHome';
  static const String appVersion = '1.0.0';

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
}