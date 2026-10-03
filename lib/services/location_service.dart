import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Current GPS location leke aao
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check karo location service ON hai kya
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Open settings to enable.');
      }

      // GPS se location lo (accuracy HIGH)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return position;
    } catch (e) {
      print('❌ Location error: $e');
      return null;
    }
  }

  /// Lat/Lng → Address (city, state, pincode, address line)
  static Future<AddressResult?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) return null;

      final p = placemarks.first;

      return AddressResult(
        addressLine: [
          p.street,
          p.subLocality,
          p.locality,
        ].where((e) => e != null && e.isNotEmpty).join(', '),
        city: p.locality ?? p.subAdministrativeArea ?? '',
        state: p.administrativeArea ?? '',
        pincode: p.postalCode ?? '',
        country: p.country ?? '',
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      print('❌ Reverse geocoding error: $e');
      return null;
    }
  }
}

class AddressResult {
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final double latitude;
  final double longitude;

  AddressResult({
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}