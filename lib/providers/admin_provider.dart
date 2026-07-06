import 'package:flutter/material.dart';
import '../models/admin_model.dart';
import '../models/property_model.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  // ============== STATE VARIABLES ==============
  List<PendingOwner> _pendingOwners = [];
  List<PendingOwner> _allOwners = [];
  List<PendingProperty> _pendingProperties = [];
  List<AdminUser> _allUsers = [];
  List<AdminReport> _pendingReports = [];
  List<Property> _allProperties = [];
  List<AdminPropertyAccessSubscription> _subscriptions = [];

  AdminDashboardStats? _dashboardStats;
  Property? _selectedProperty;
  OwnerDetail? _selectedOwnerDetail;
  OwnerDetail? get selectedOwnerDetail => _selectedOwnerDetail;

  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  // ============== GETTERS ==============
  List<PendingOwner> get pendingOwners => _pendingOwners;
  List<PendingOwner> get allOwners => _allOwners;
  List<PendingProperty> get pendingProperties => _pendingProperties;
  List<AdminUser> get allUsers => _allUsers;
  List<AdminReport> get pendingReports => _pendingReports;
  List<Property> get allProperties => _allProperties;
  List<AdminPropertyAccessSubscription> get subscriptions => _subscriptions;
  AdminDashboardStats? get dashboardStats => _dashboardStats;
  Property? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<bool> getOwnerDetail(int ownerId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getOwnerDetail(ownerId);
      if (_isDisposed) return false;

      if (response.success && response.data != null) {
        _selectedOwnerDetail = response.data;
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.1 GET PENDING OWNERS ==============
  Future<bool> getPendingOwners() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getPendingOwners();
      if (_isDisposed) return false;

      if (response.success) {
        _pendingOwners = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.2 GET ALL OWNERS ==============
  Future<bool> getAllOwners() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getAllOwners();
      if (_isDisposed) return false;

      if (response.success) {
        _allOwners = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.3 VERIFY OWNER ==============
  Future<bool> verifyOwner(int ownerId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.verifyOwner(ownerId);
      if (_isDisposed) return false;

      if (response.success) {
        await getPendingOwners(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.4 REJECT OWNER ==============
  Future<bool> rejectOwner(int ownerId, String reason) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.rejectOwner(ownerId, reason);
      if (_isDisposed) return false;

      if (response.success) {
        await getPendingOwners(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.5 GET PENDING PROPERTIES ==============
  Future<bool> getPendingProperties() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getPendingProperties();
      if (_isDisposed) return false;

      if (response.success) {
        _pendingProperties = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.6 PUBLISH PROPERTY ==============
  Future<bool> publishProperty(int propertyId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.publishProperty(propertyId);
      if (_isDisposed) return false;

      if (response.success) {
        await getPendingProperties(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.7 UNPUBLISH PROPERTY ==============
  Future<bool> unpublishProperty(int propertyId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.unpublishProperty(propertyId);
      if (_isDisposed) return false;

      if (response.success) {
        await getPendingProperties(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.8 GET ALL USERS ==============
  Future<bool> getAllUsers() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getAllUsers();
      if (_isDisposed) return false;

      if (response.success) {
        _allUsers = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.9 DEACTIVATE USER ==============
  Future<bool> deactivateUser(int userId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.deactivateUser(userId);
      if (_isDisposed) return false;

      if (response.success) {
        await getAllUsers(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.10 ACTIVATE USER ==============
  Future<bool> activateUser(int userId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.activateUser(userId);
      if (_isDisposed) return false;

      if (response.success) {
        await getAllUsers(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.11 ADMIN DASHBOARD STATS ==============
  Future<bool> getDashboardStats() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getDashboardStats();
      if (_isDisposed) return false;

      if (response.success && response.data != null) {
        _dashboardStats = response.data;
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.12 GET PENDING REPORTS ==============
  Future<bool> getPendingReports() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getPendingReports();
      if (_isDisposed) return false;

      if (response.success) {
        _pendingReports = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.13 RESOLVE REPORT ==============
  Future<bool> resolveReport(int reportId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.resolveReport(reportId);
      if (_isDisposed) return false;

      if (response.success) {
        await getPendingReports(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.14 GET PROPERTY DETAIL (ADMIN) ==============
  Future<bool> getPropertyDetailAdmin(int propertyId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getPropertyDetailAdmin(propertyId);
      if (_isDisposed) return false;

      if (response.success && response.data != null) {
        _selectedProperty = response.data;
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.15 GET ALL PROPERTIES (ADMIN) ==============
  Future<bool> getAllPropertiesAdmin() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.getAllPropertiesAdmin();
      if (_isDisposed) return false;

      if (response.success) {
        _allProperties = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.16 GET PROPERTY ACCESS SUBSCRIPTIONS ==============
  Future<bool> getPropertyAccessSubscriptions({String? status}) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _service.getPropertyAccessSubscriptions(status: status);
      if (_isDisposed) return false;

      if (response.success) {
        _subscriptions = response.data ?? [];
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== 10.17 FORCE EXPIRE SUBSCRIPTION ==============
  Future<bool> forceExpireSubscription(
      int subscriptionId, String reason) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _service.forceExpireSubscription(subscriptionId, reason);
      if (_isDisposed) return false;

      if (response.success) {
        await getPropertyAccessSubscriptions(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== LOAD ALL ADMIN DATA ==============
  Future<void> loadAllAdminData() async {
    if (_isDisposed) return;
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        getDashboardStats(),
        getPendingOwners(),
        getPendingProperties(),
        getAllUsers(),
        getPendingReports(),
        getPropertyAccessSubscriptions(),
      ]);
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // ============== HELPERS ==============
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

  void reset() {
    if (!_isDisposed) {
      _pendingOwners = [];
      _allOwners = [];
      _pendingProperties = [];
      _allUsers = [];
      _pendingReports = [];
      _allProperties = [];
      _subscriptions = [];
      _dashboardStats = null;
      _selectedProperty = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }
}
