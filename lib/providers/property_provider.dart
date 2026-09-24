import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../services/api_service.dart';

class PropertyProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Property> _properties = [];
  List<Property> _savedProperties = [];
  List<Room> _rooms = [];
  Property? _selectedProperty;

  bool _isLoading = false;
  bool _isLoadingRooms = false;
  String? _error;
  bool _isDisposed = false;

  List<Property> get properties => _properties;
  List<Property> get savedProperties => _savedProperties;
  List<Room> get rooms => _rooms;
  Property? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get error => _error;

  int get availableRoomsCount =>
      _rooms.where((r) => r.status == 'AVAILABLE').length;

  int get occupiedRoomsCount =>
      _rooms.where((r) => r.status == 'OCCUPIED').length;

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

      debugPrint('🔍 Searching properties: $queryParams');

      final response = await _api.get(
        '/properties/search',
        queryParameters: queryParams,
      );

      if (_isDisposed) return;

      if (response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _properties = data.map((item) => Property.fromJson(item)).toList();
        debugPrint('✅ Found ${_properties.length} properties');
      } else {
        _error = response.data['message'] ?? 'Failed to load properties';
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        debugPrint('❌ Search exception: $e');
      }
    }

    if (!_isDisposed) _setLoading(false);
  }

  Future<void> getPropertyDetail(int propertyId) async {
    if (_isDisposed) return;

    _clearError();

    try {
      debugPrint('🔍 Getting property detail: $propertyId');

      final response = await _api.get('/properties/$propertyId');

      if (_isDisposed) return;

      if (response.data['success'] == true) {
        _selectedProperty = Property.fromJson(response.data['data']);
        debugPrint('✅ Property loaded: ${_selectedProperty?.title}');
        notifyListeners();
      } else {
        _error = response.data['message'] ?? 'Failed to load property details';
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        debugPrint('❌ Property detail exception: $e');
      }
    }
  }

  Future<void> getRooms(int propertyId) async {
    if (_isDisposed) return;

    _isLoadingRooms = true;
    _clearError();

    try {
      debugPrint('🔍 Getting rooms for property: $propertyId');

      final response = await _api.get('/properties/$propertyId/rooms');

      if (_isDisposed) return;

      if (response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _rooms = data.map((item) => Room.fromJson(item)).toList();
        debugPrint('✅ Found ${_rooms.length} rooms');
      } else {
        _error = response.data['message'] ?? 'Failed to load rooms';
        _rooms = [];
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        _rooms = [];
        debugPrint('❌ Rooms exception: $e');
      }
    }

    if (!_isDisposed) {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  Future<void> loadPropertyDetailWithRooms(int propertyId) async {
    if (_isDisposed) return;

    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔍 Loading property + rooms: $propertyId');

      await Future.wait([
        getPropertyDetail(propertyId),
        getRooms(propertyId),
        getSavedProperties(),
      ]);

      debugPrint('✅ All loaded. Rooms: ${_rooms.length}');
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        debugPrint('❌ Load all exception: $e');
      }
    }

    if (!_isDisposed) _setLoading(false);
  }

  Future<void> getSavedProperties() async {
    if (_isDisposed) return;

    _clearError();

    try {
      final response = await _api.get('/user/saved-properties');
      if (_isDisposed) return;

      if (response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _savedProperties = data.map((item) => Property.fromJson(item)).toList();
        debugPrint('✅ Saved properties: ${_savedProperties.length}');
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('❌ Saved properties exception: $e');
      }
    }
  }

  Future<bool> saveProperty(int propertyId) async {
    if (_isDisposed) return false;
    try {
      final response = await _api.post('/user/saved-properties/$propertyId');
      if (response.data['success'] == true && !_isDisposed) {
        await getSavedProperties();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Save property error: $e');
      return false;
    }
  }

  Future<bool> removeSavedProperty(int propertyId) async {
    if (_isDisposed) return false;
    try {
      final response = await _api.delete('/user/saved-properties/$propertyId');
      if (response.data['success'] == true && !_isDisposed) {
        await getSavedProperties();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Remove property error: $e');
      return false;
    }
  }

  void clearRooms() {
    if (!_isDisposed) {
      _rooms = [];
      notifyListeners();
    }
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
    }
  }

  void clearError() {
    if (!_isDisposed) {
      _error = null;
      notifyListeners();
    }
  }

  void reset() {
    if (!_isDisposed) {
      _properties = [];
      _savedProperties = [];
      _rooms = [];
      _selectedProperty = null;
      _isLoading = false;
      _isLoadingRooms = false;
      _error = null;
      notifyListeners();
    }
  }
}