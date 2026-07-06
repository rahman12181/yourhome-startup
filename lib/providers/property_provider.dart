import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../services/api_service.dart';

class PropertyProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Property> _properties = [];
  List<Property> _savedProperties = [];
  List<Room> _rooms = []; // ✅ ADDED
  Property? _selectedProperty;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  List<Property> get properties => _properties;
  List<Property> get savedProperties => _savedProperties;
  List<Room> get rooms => _rooms; // ✅ ADDED
  Property? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> searchProperties({
    String? city,
    String? type,
    String? gender,
    double? minRent,
    double? maxRent,
    String? pincode,
    double? lat,
    double? lng,
    double? radius,
    String? sort,
  }) async {
    if (_isDisposed) return;
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final queryParams = <String, dynamic>{};
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (gender != null && gender.isNotEmpty) queryParams['gender'] = gender;
      if (minRent != null) queryParams['minRent'] = minRent;
      if (maxRent != null) queryParams['maxRent'] = maxRent;
      if (pincode != null && pincode.isNotEmpty) queryParams['pincode'] = pincode;
      if (lat != null) queryParams['lat'] = lat;
      if (lng != null) queryParams['lng'] = lng;
      if (radius != null) queryParams['radius'] = radius;
      if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;

      print('🔍 Searching properties with: $queryParams');

      final response = await _api.get(
        '/properties/search',
        queryParameters: queryParams,
      );

      if (_isDisposed) return;

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        _properties = data.map((item) => Property.fromJson(item)).toList();
        print('✅ Found ${_properties.length} properties');
      } else {
        _error = response.data['message'] ?? 'Failed to load properties';
        print('❌ Search error: $_error');
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        print('❌ Search exception: $e');
      }
    }

    if (!_isDisposed) {
      _setLoading(false);
    }
  }

  Future<void> getPropertyDetail(int propertyId) async {
    if (_isDisposed) return;
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      print('🔍 Getting property detail: $propertyId');
      
      final response = await _api.get('/properties/$propertyId');

      if (_isDisposed) return;

      if (response.data['success'] == true) {
        _selectedProperty = Property.fromJson(response.data['data']);
        print('✅ Property detail loaded');
      } else {
        _error = response.data['message'] ?? 'Failed to load property details';
        print('❌ Property detail error: $_error');
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        print('❌ Property detail exception: $e');
      }
    }

    if (!_isDisposed) {
      _setLoading(false);
    }
  }

  // ✅ NEW: Get Rooms for a Property
  Future<void> getRooms(int propertyId) async {
    if (_isDisposed) return;
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      print('🔍 Getting rooms for property: $propertyId');
      
      final response = await _api.get('/properties/$propertyId/rooms');

      if (_isDisposed) return;

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        _rooms = data.map((item) => Room.fromJson(item)).toList();
        print('✅ Found ${_rooms.length} rooms');
        
        // ✅ Update available rooms count in property
        if (_selectedProperty != null) {
          final available = _rooms.where((r) => r.status == 'AVAILABLE').length;
          // You can update the property if needed
        }
      } else {
        _error = response.data['message'] ?? 'Failed to load rooms';
        _rooms = [];
        print('❌ Rooms error: $_error');
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        _rooms = [];
        print('❌ Rooms exception: $e');
      }
    }

    if (!_isDisposed) {
      _setLoading(false);
    }
  }

  // ✅ NEW: Get Single Room Detail
  Future<Room?> getRoomDetail(int propertyId, int roomId) async {
    if (_isDisposed) return null;

    try {
      final response = await _api.get('/properties/$propertyId/rooms/$roomId');
      
      if (response.data['success'] == true) {
        return Room.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ Room detail error: $e');
      return null;
    }
  }

  Future<void> getSavedProperties() async {
    if (_isDisposed) return;
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      print('🔍 Getting saved properties');
      
      final response = await _api.get('/user/saved-properties');

      if (_isDisposed) return;

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        _savedProperties = data.map((item) => Property.fromJson(item)).toList();
        print('✅ Found ${_savedProperties.length} saved properties');
      } else {
        _error = response.data['message'] ?? 'Failed to load saved properties';
        print('❌ Saved properties error: $_error');
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        print('❌ Saved properties exception: $e');
      }
    }

    if (!_isDisposed) {
      _setLoading(false);
    }
  }

  Future<bool> saveProperty(int propertyId) async {
    if (_isDisposed) return false;

    try {
      print('💾 Saving property: $propertyId');
      
      final response = await _api.post('/user/saved-properties/$propertyId');
      
      if (response.data['success'] == true && !_isDisposed) {
        await getSavedProperties();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Save property error: $e');
      return false;
    }
  }

  Future<bool> removeSavedProperty(int propertyId) async {
    if (_isDisposed) return false;

    try {
      print('🗑️ Removing property: $propertyId');
      
      final response = await _api.delete('/user/saved-properties/$propertyId');
      
      if (response.data['success'] == true && !_isDisposed) {
        await getSavedProperties();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Remove property error: $e');
      return false;
    }
  }

  // ✅ NEW: Load All Property Data (Detail + Rooms)
  Future<void> loadPropertyDetailWithRooms(int propertyId) async {
    if (_isDisposed) return;
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      print('🔍 Loading property detail with rooms: $propertyId');
      
      // Load both in parallel
      await Future.wait([
        getPropertyDetail(propertyId),
        getRooms(propertyId),
      ]);
      
      print('✅ Property and rooms loaded successfully');
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        print('❌ Error loading property data: $e');
      }
    }

    if (!_isDisposed) {
      _setLoading(false);
    }
  }

  // ✅ NEW: Clear Rooms
  void clearRooms() {
    if (!_isDisposed) {
      _rooms = [];
      notifyListeners();
    }
  }

  // ✅ NEW: Get Available Rooms Count
  int get availableRoomsCount {
    return _rooms.where((r) => r.status == 'AVAILABLE').length;
  }

  // ✅ NEW: Get Occupied Rooms Count
  int get occupiedRoomsCount {
    return _rooms.where((r) => r.status == 'OCCUPIED').length;
  }

  void _setLoading(bool loading) {
    if (!_isDisposed && _isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _clearError() {
    if (!_isDisposed && _error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (!_isDisposed) {
      _error = null;
      notifyListeners();
    }
  }

  // Reset method to clear all data
  void reset() {
    if (!_isDisposed) {
      _properties = [];
      _savedProperties = [];
      _rooms = [];
      _selectedProperty = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }
}