import 'package:flutter/material.dart';
import '../models/admin_model.dart';
import '../models/admin_analytics_models.dart';
import '../models/property_model.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  // ═══════════════════════════════════════════
  // STATE — EXISTING
  // ═══════════════════════════════════════════
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

  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  // ═══════════════════════════════════════════
  // STATE — ANALYTICS
  // ═══════════════════════════════════════════
  AdminDashboardSummary? _dashboardSummary;
  UserAnalytics? _userAnalytics;
  OwnerAnalytics? _ownerAnalytics;
  RevenueAnalytics? _revenueAnalytics;
  BookingAnalytics? _bookingAnalytics;
  PropertyAnalytics? _propertyAnalytics;
  EngagementAnalytics? _engagementAnalytics;
  String _analyticsPeriod = '30d';

  // ═══════════════════════════════════════════
  // GETTERS — EXISTING
  // ═══════════════════════════════════════════
  List<PendingOwner> get pendingOwners => _pendingOwners;
  List<PendingOwner> get allOwners => _allOwners;
  List<PendingProperty> get pendingProperties => _pendingProperties;
  List<AdminUser> get allUsers => _allUsers;
  List<AdminReport> get pendingReports => _pendingReports;
  List<Property> get allProperties => _allProperties;
  List<AdminPropertyAccessSubscription> get subscriptions => _subscriptions;
  AdminDashboardStats? get dashboardStats => _dashboardStats;
  Property? get selectedProperty => _selectedProperty;
  OwnerDetail? get selectedOwnerDetail => _selectedOwnerDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ═══════════════════════════════════════════
  // GETTERS — ANALYTICS
  // ═══════════════════════════════════════════
  AdminDashboardSummary? get dashboardSummary => _dashboardSummary;
  UserAnalytics? get userAnalytics => _userAnalytics;
  OwnerAnalytics? get ownerAnalytics => _ownerAnalytics;
  RevenueAnalytics? get revenueAnalytics => _revenueAnalytics;
  BookingAnalytics? get bookingAnalytics => _bookingAnalytics;
  PropertyAnalytics? get propertyAnalytics => _propertyAnalytics;
  EngagementAnalytics? get engagementAnalytics => _engagementAnalytics;
  String get analyticsPeriod => _analyticsPeriod;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // ANALYTICS METHODS (7 APIs)
  // ═══════════════════════════════════════════════════════════

  Future<bool> getDashboardSummary() async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.getDashboardSummary();
      if (_isDisposed) return false;
      if (response.success && response.data != null) {
        _dashboardSummary = response.data;
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

  Future<bool> getUserAnalytics({String? period}) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.getUserAnalytics(
          period: period ?? _analyticsPeriod);
      if (_isDisposed) return false;
      if (response.success && response.data != null) {
        _userAnalytics = response.data;
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

  Future<bool> getOwnerAnalytics({String? period}) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.getOwnerAnalytics(
          period: period ?? _analyticsPeriod);
      if (_isDisposed) return false;
      if (response.success && response.data != null) {
        _ownerAnalytics = response.data;
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

  Future<bool> getRevenueAnalytics({String? period}) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.getRevenueAnalytics(
          period: period ?? _analyticsPeriod);
      if (_isDisposed) return false;
      if (response.success && response.data != null) {
        _revenueAnalytics = response.data;
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

  Future<bool> getBookingAnalytics({String? period}) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.getBookingAnalytics(
          period: period ?? _analyticsPeriod);
      if (_isDisposed) return false;
      if (response.success && response.data != null) {
        _bookingAnalytics = response.data;
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

  Future<bool> getPropertyAnalytics({String? period}) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.getPropertyAnalytics(
          period: period ?? _analyticsPeriod);
      if (_isDisposed) return false;
      if (response.success && response.data != null) {
        _propertyAnalytics = response.data;
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

  Future<bool> getEngagementAnalytics({String? period}) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.getEngagementAnalytics(
          period: period ?? _analyticsPeriod);
      if (_isDisposed) return false;
      if (response.success && response.data != null) {
        _engagementAnalytics = response.data;
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

  void setAnalyticsPeriod(String period) {
    _analyticsPeriod = period;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // EXISTING METHODS
  // ═══════════════════════════════════════════════════════════

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

  Future<bool> verifyOwner(int ownerId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.verifyOwner(ownerId);
      if (_isDisposed) return false;
      if (response.success) {
        await getPendingOwners();
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

  Future<bool> rejectOwner(int ownerId, String reason) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.rejectOwner(ownerId, reason);
      if (_isDisposed) return false;
      if (response.success) {
        await getPendingOwners();
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

  Future<bool> publishProperty(int propertyId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.publishProperty(propertyId);
      if (_isDisposed) return false;
      if (response.success) {
        await getPendingProperties();
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

  Future<bool> unpublishProperty(int propertyId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.unpublishProperty(propertyId);
      if (_isDisposed) return false;
      if (response.success) {
        await getPendingProperties();
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

  Future<bool> deactivateUser(int userId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.deactivateUser(userId);
      if (_isDisposed) return false;
      if (response.success) {
        await getAllUsers();
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

  Future<bool> activateUser(int userId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.activateUser(userId);
      if (_isDisposed) return false;
      if (response.success) {
        await getAllUsers();
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

  Future<bool> resolveReport(int reportId) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _clearError();
    try {
      final response = await _service.resolveReport(reportId);
      if (_isDisposed) return false;
      if (response.success) {
        await getPendingReports();
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
        await getPropertyAccessSubscriptions();
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

  // ═══════════════════════════════════════════════════════════
  // LOAD ALL
  // ═══════════════════════════════════════════════════════════
  Future<void> loadAllAdminData() async {
    if (_isDisposed) return;
    _setLoading(true);
    _clearError();
    try {
      await Future.wait([
        getDashboardSummary(),
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

  Future<void> loadAllAnalytics({String? period}) async {
    if (_isDisposed) return;
    try {
      await Future.wait([
        getUserAnalytics(period: period),
        getOwnerAnalytics(period: period),
        getRevenueAnalytics(period: period),
        getBookingAnalytics(period: period),
        getPropertyAnalytics(period: period),
        getEngagementAnalytics(period: period),
      ]);
    } catch (e) {
      _error = e.toString();
    }
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
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
      _dashboardSummary = null;
      _userAnalytics = null;
      _ownerAnalytics = null;
      _revenueAnalytics = null;
      _bookingAnalytics = null;
      _propertyAnalytics = null;
      _engagementAnalytics = null;
      _selectedProperty = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }
}