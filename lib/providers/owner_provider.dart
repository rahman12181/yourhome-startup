import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/owner_model.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../models/booking_stats_model.dart';
import '../models/dashboard_model.dart';
import '../services/owner_service.dart';
import '../services/booking_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OwnerProvider extends ChangeNotifier {
  final OwnerService _service = OwnerService();
  final BookingService _bookingService = BookingService();
  bool _isDisposed = false;

  OwnerProfile? _ownerProfile;
  VerificationStatus? _verificationStatus;

  DashboardStats? _dashboardStats;

  SubscriptionDetails? _listingSubscription;

  PropertyAccessStatus? _propertyAccessStatus;
  List<PropertyAccessSubscription> _propertyAccessHistory = [];

  List<PropertyAccessPlan> _propertyAccessPlans = [];
  List<ListingPlan> _listingPlans = [];

  List<Property> _myProperties = [];
  Property? _selectedProperty;

  List<Room> _rooms = [];

  List<BookingRequest> _bookingRequests = [];
  BookingStats? _bookingStats;
  int _unreadBookingCount = 0;
  bool _isStatsLoading = false;

  String _bookingSortBy = 'newest';
  String? _bookingFilterStatus;
  int? _bookingFilterPropertyId;
  String? _bookingSearchQuery;
  bool _bookingOnlyNew = false;
  bool _bookingOnlyUrgent = false;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  bool _hasPayoutUpi = false;
  bool get hasPayoutUpi => _hasPayoutUpi;

  // ============================================
  // DASHBOARD ANALYTICS STATE
  // ============================================
  DashboardSummary? _dashboardSummary;
  bool _isDashboardLoading = false;

  OwnerProfile? get ownerProfile => _ownerProfile;
  VerificationStatus? get verificationStatus => _verificationStatus;
  DashboardStats? get dashboardStats => _dashboardStats;
  SubscriptionDetails? get listingSubscription => _listingSubscription;
  PropertyAccessStatus? get propertyAccessStatus => _propertyAccessStatus;
  List<PropertyAccessSubscription> get propertyAccessHistory =>
      _propertyAccessHistory;
  List<PropertyAccessPlan> get propertyAccessPlans => _propertyAccessPlans;
  List<ListingPlan> get listingPlans => _listingPlans;
  List<Property> get myProperties => _myProperties;
  Property? get selectedProperty => _selectedProperty;
  List<Room> get rooms => _rooms;
  List<BookingRequest> get bookingRequests => _bookingRequests;
  BookingStats? get bookingStats => _bookingStats;
  int get unreadBookingCount => _unreadBookingCount;
  bool get isStatsLoading => _isStatsLoading;
  String get bookingSortBy => _bookingSortBy;
  String? get bookingFilterStatus => _bookingFilterStatus;
  int? get bookingFilterPropertyId => _bookingFilterPropertyId;
  String? get bookingSearchQuery => _bookingSearchQuery;
  bool get bookingOnlyNew => _bookingOnlyNew;
  bool get bookingOnlyUrgent => _bookingOnlyUrgent;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  // ============================================
  // DASHBOARD GETTERS
  // ============================================
  DashboardSummary? get dashboardSummary => _dashboardSummary;
  bool get isDashboardLoading => _isDashboardLoading;

  List<BookingRequest> get pendingRequests =>
      _bookingRequests.where((b) => b.status == 'PENDING').toList();
  List<BookingRequest> get acceptedRequests =>
      _bookingRequests.where((b) => b.status == 'ACCEPTED').toList();
  List<BookingRequest> get rejectedRequests =>
      _bookingRequests.where((b) => b.status == 'REJECTED').toList();

  bool get canAddProperty =>
      _propertyAccessStatus?.hasActiveSubscription ?? false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _setLoading(bool v) {
    if (_isDisposed) return;
    _isLoading = v;
    notifyListeners();
  }

  void _setSubmitting(bool v) {
    if (_isDisposed) return;
    _isSubmitting = v;
    notifyListeners();
  }

  void _setError(String? e) {
    if (_isDisposed) return;
    _error = e;
    notifyListeners();
  }

  void clearError() => _setError(null);

 Future<void> loadAllOwnerData() async {
  if (_isDisposed) return;

  // ✅ Check internet first
  final hasNet = await checkConnectivity();
  if (!hasNet) {
    _setLoading(false);
    return;
  }

  _setLoading(true);
  _setError(null);

  await Future.wait([
    getOwnerProfile(),
    getVerificationStatus(),
    getDashboardStats(),
    getPropertyAccessStatus(),
    getPropertyAccessPlans(),
    getListingPlans(),
    getListingSubscriptionDetails(),
    getMyProperties(),
    getIncomingBookingRequests(),
    loadBookingStats(),
    loadUnreadBookingCount(),
    loadDashboardSummary(showLoader: false),
    loadPayoutStatus()
  ]);

  if (!_isDisposed) _setLoading(false);
}

  Future<void> getOwnerProfile() async {
    final res = await _service.getOwnerProfile();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _ownerProfile = res.data;
      notifyListeners();
    }
  }

  // ============================================
// PAYOUT UPI STATUS
// ===========================================

Future<void> loadPayoutStatus() async {
  try {
    // 1. Pehle local se check karo (fast)
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('has_payout_upi') ?? false;
    if (_hasPayoutUpi != saved) {
      _hasPayoutUpi = saved;
      if (!_isDisposed) notifyListeners();
    }

    // 2. Phir backend se fresh check karo
    final res = await _service.getPayoutStatus();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      final has = res.data!;
      if (has != _hasPayoutUpi) {
        _hasPayoutUpi = has;
        await prefs.setBool('has_payout_upi', has);
        notifyListeners();
      }
    }
  } catch (_) {}
}

// Set manually when UPI is saved
Future<void> setPayoutUpiSaved() async {
  _hasPayoutUpi = true;
  if (!_isDisposed) notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('has_payout_upi', true);
}

  Future<void> getVerificationStatus() async {
    final res = await _service.getVerificationStatus();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _verificationStatus = res.data;
      notifyListeners();
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final hasNet = result != ConnectivityResult.none;
      if (_hasInternet != hasNet) {
        _hasInternet = hasNet;
        if (!_isDisposed) notifyListeners();
      }
      return hasNet;
    } catch (_) {
      return true;
    }
  }

  Future<ApiResponseResult> applyAsOwner({
    required String businessName,
    required String aadharNumber,
    required String panNumber,
    File? aadharDoc,
    File? panDoc,
    File? addressProof,
  }) async {
    _setSubmitting(true);
    _setError(null);
    try {
      final formData = FormData.fromMap({
        'businessName': businessName,
        'aadharNumber': aadharNumber,
        'panNumber': panNumber,
        if (aadharDoc != null)
          'aadharDoc': await MultipartFile.fromFile(aadharDoc.path),
        if (panDoc != null) 'panDoc': await MultipartFile.fromFile(panDoc.path),
        if (addressProof != null)
          'addressProof': await MultipartFile.fromFile(addressProof.path),
      });
      final res = await _service.applyAsOwner(formData);
      _setSubmitting(false);
      if (!res.success) _setError(res.message);
      return ApiResponseResult(res.success, res.message);
    } catch (e) {
      _setSubmitting(false);
      _setError(e.toString());
      return ApiResponseResult(false, e.toString());
    }
  }

  Future<void> getDashboardStats() async {
    final res = await _service.getDashboardStats();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _dashboardStats = res.data;
      notifyListeners();
    }
  }

  // ============================================
  // NEW — DASHBOARD SUMMARY LOADER
  // ============================================
  Future<void> loadDashboardSummary({bool showLoader = true}) async {
    if (_isDisposed) return;
    if (showLoader) {
      _isDashboardLoading = true;
      notifyListeners();
    }

    final res = await _service.getDashboardSummary();
    if (_isDisposed) return;

    if (res.success && res.data != null) {
      _dashboardSummary = res.data;
    }

    _isDashboardLoading = false;
    notifyListeners();
  }

  Future<void> getPropertyAccessPlans() async {
    if (_isDisposed) return;
    _propertyAccessPlans = _service.getPropertyAccessPlans();
    notifyListeners();
  }

  Future<void> getListingPlans() async {
    if (_isDisposed) return;
    _listingPlans = _service.getListingPlans();
    notifyListeners();
  }

  Future<void> getListingSubscriptionDetails() async {
    final res = await _service.getListingSubscriptionDetails();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _listingSubscription = res.data;
      notifyListeners();
    }
  }

  Future<SubscriptionOrder?> buyListingSubscription(String plan) async {
    _setSubmitting(true);
    _setError(null);
    final res = await _service.buyListingSubscription(plan);
    _setSubmitting(false);
    if (res.success && res.data != null) return res.data;
    _setError(res.message);
    return null;
  }

  Future<bool> confirmListingSubscription({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String plan,
  }) async {
    _setSubmitting(true);
    final res = await _service.confirmListingSubscription(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      plan: plan,
    );
    _setSubmitting(false);
    if (res.success) {
      await getListingSubscriptionDetails();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<bool> buyFeaturedListing(int propertyId, int days) async {
    _setSubmitting(true);
    final res = await _service.buyFeaturedListing(propertyId, days);
    _setSubmitting(false);
    if (!res.success) _setError(res.message);
    return res.success;
  }

  Future<void> getPropertyAccessStatus() async {
    final res = await _service.getPropertyAccessStatus();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _propertyAccessStatus = res.data;
      notifyListeners();
    }
  }

  Future<void> getPropertyAccessHistory() async {
    final res = await _service.getPropertyAccessHistory();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _propertyAccessHistory = res.data!;
      notifyListeners();
    }
  }

  Future<SubscriptionOrder?> buyPropertyAccessSubscription(String plan) async {
    _setSubmitting(true);
    _setError(null);
    final res = await _service.buyPropertyAccessSubscription(plan);
    _setSubmitting(false);
    if (res.success && res.data != null) return res.data;
    _setError(res.message);
    return null;
  }

  Future<bool> confirmPropertyAccessSubscription({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String plan,
  }) async {
    _setSubmitting(true);
    final res = await _service.confirmPropertyAccessSubscription(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      plan: plan,
    );
    _setSubmitting(false);
    if (res.success) {
      await getPropertyAccessStatus();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<SubscriptionOrder?> renewPropertyAccessSubscription(
      String plan) async {
    _setSubmitting(true);
    _setError(null);
    final res = await _service.renewPropertyAccessSubscription(plan);
    _setSubmitting(false);
    if (res.success && res.data != null) return res.data;
    _setError(res.message);
    return null;
  }

  Future<void> getMyProperties() async {
    final res = await _service.getMyProperties();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _myProperties = res.data!;
      notifyListeners();
    } else {
      _setError(res.message);
    }
  }

  Future<void> getPropertyDetail(int propertyId) async {
    _setLoading(true);
    final res = await _service.getPropertyDetail(propertyId);
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _selectedProperty = res.data;
    } else {
      _setError(res.message);
    }
    _setLoading(false);
  }

  Future<Property?> addProperty(Map<String, dynamic> body) async {
    _setSubmitting(true);
    _setError(null);
    final res = await _service.addProperty(body);
    _setSubmitting(false);
    if (res.success && res.data != null) {
      _myProperties.insert(0, res.data!);
      notifyListeners();
      return res.data;
    }
    _setError(res.message);
    return null;
  }

  Future<bool> updateProperty(int propertyId, Map<String, dynamic> body) async {
    _setSubmitting(true);
    _setError(null);
    final res = await _service.updateProperty(propertyId, body);
    _setSubmitting(false);
    if (res.success && res.data != null) {
      final idx = _myProperties.indexWhere((p) => p.propertyId == propertyId);
      if (idx != -1) _myProperties[idx] = res.data!;
      _selectedProperty = res.data;
      notifyListeners();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<bool> deleteProperty(int propertyId) async {
    _setSubmitting(true);
    final res = await _service.deleteProperty(propertyId);
    _setSubmitting(false);
    if (res.success) {
      _myProperties.removeWhere((p) => p.propertyId == propertyId);
      notifyListeners();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<bool> uploadPropertyMedia(
    int propertyId,
    File file, {
    String mediaType = 'IMAGE',
    bool isPrimary = false,
  }) async {
    _setSubmitting(true);
    _setError(null);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'mediaType': mediaType,
        'isPrimary': isPrimary.toString(),
      });
      final res = await _service.uploadPropertyMedia(propertyId, formData);
      _setSubmitting(false);
      if (res.success) {
        await getPropertyDetail(propertyId);
        return true;
      }
      _setError(res.message);
      return false;
    } catch (e) {
      _setSubmitting(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deletePropertyMedia(int propertyId, int mediaId) async {
    _setSubmitting(true);
    final res = await _service.deletePropertyMedia(propertyId, mediaId);
    _setSubmitting(false);
    if (res.success) {
      await getPropertyDetail(propertyId);
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<void> getRooms(int propertyId) async {
    _setLoading(true);
    final res = await _service.getOwnerRooms(propertyId);
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _rooms = res.data!;
    } else {
      _rooms = [];
      _setError(res.message);
    }
    _setLoading(false);
  }

  Future<bool> addRoom(int propertyId, Map<String, dynamic> body) async {
    _setSubmitting(true);
    _setError(null);
    final res = await _service.addRoom(propertyId, body);
    _setSubmitting(false);
    if (res.success && res.data != null) {
      _rooms.add(res.data!);
      notifyListeners();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<bool> updateRoom(
      int propertyId, int roomId, Map<String, dynamic> body) async {
    _setSubmitting(true);
    final res = await _service.updateRoom(propertyId, roomId, body);
    _setSubmitting(false);
    if (res.success && res.data != null) {
      final idx = _rooms.indexWhere((r) => r.roomId == roomId);
      if (idx != -1) _rooms[idx] = res.data!;
      notifyListeners();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<bool> updateRoomStatus(
      int propertyId, int roomId, String status) async {
    final res = await _service.updateRoomStatus(propertyId, roomId, status);
    if (res.success && res.data != null) {
      final idx = _rooms.indexWhere((r) => r.roomId == roomId);
      if (idx != -1) _rooms[idx] = res.data!;
      notifyListeners();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<bool> deleteRoom(int propertyId, int roomId) async {
    _setSubmitting(true);
    final res = await _service.deleteRoom(propertyId, roomId);
    _setSubmitting(false);
    if (res.success) {
      _rooms.removeWhere((r) => r.roomId == roomId);
      notifyListeners();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<void> checkAndRefreshSubscriptionStatus() async {
    await getPropertyAccessStatus();
    await getListingSubscriptionDetails();
  }

  Future<void> getIncomingBookingRequests({bool showLoader = true}) async {
    if (showLoader) _setLoading(true);
    final res = await _bookingService.getOwnerBookingRequests(
      status: _bookingFilterStatus,
      propertyId: _bookingFilterPropertyId,
      searchQuery: _bookingSearchQuery,
      sortBy: _bookingSortBy,
      onlyNew: _bookingOnlyNew,
      onlyUrgent: _bookingOnlyUrgent,
    );
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _bookingRequests = res.data!;
    } else {
      _setError(res.message);
    }
    if (showLoader) _setLoading(false);
  }

  Future<void> loadBookingStats() async {
    _isStatsLoading = true;
    notifyListeners();
    final res = await _bookingService.getBookingStats();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _bookingStats = res.data;
    }
    _isStatsLoading = false;
    notifyListeners();
  }

  Future<void> loadUnreadBookingCount() async {
    final res = await _bookingService.getUnreadCount();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _unreadBookingCount = res.data!;
      notifyListeners();
    }
  }

  void updateBookingFilters({
    String? sortBy,
    String? filterStatus,
    int? filterPropertyId,
    String? searchQuery,
    bool? onlyNew,
    bool? onlyUrgent,
    bool clearStatus = false,
    bool clearProperty = false,
    bool clearSearch = false,
  }) {
    if (sortBy != null) _bookingSortBy = sortBy;
    if (clearStatus) {
      _bookingFilterStatus = null;
    } else if (filterStatus != null) {
      _bookingFilterStatus = filterStatus;
    }
    if (clearProperty) {
      _bookingFilterPropertyId = null;
    } else if (filterPropertyId != null) {
      _bookingFilterPropertyId = filterPropertyId;
    }
    if (clearSearch) {
      _bookingSearchQuery = null;
    } else if (searchQuery != null) {
      _bookingSearchQuery = searchQuery;
    }
    if (onlyNew != null) _bookingOnlyNew = onlyNew;
    if (onlyUrgent != null) _bookingOnlyUrgent = onlyUrgent;
    notifyListeners();
    getIncomingBookingRequests();
  }

  void resetBookingFilters() {
    _bookingSortBy = 'newest';
    _bookingFilterStatus = null;
    _bookingFilterPropertyId = null;
    _bookingSearchQuery = null;
    _bookingOnlyNew = false;
    _bookingOnlyUrgent = false;
    notifyListeners();
    getIncomingBookingRequests();
  }

  Future<bool> acceptBookingRequest(int requestId, String responseMsg) async {
    _setSubmitting(true);
    _setError(null);
    final res =
        await _bookingService.acceptBookingRequest(requestId, responseMsg);
    _setSubmitting(false);
    if (res.success && res.data != null) {
      final idx = _bookingRequests.indexWhere((b) => b.requestId == requestId);
      if (idx != -1) _bookingRequests[idx] = res.data!;
      notifyListeners();
      loadBookingStats();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<bool> rejectBookingRequest(int requestId, String responseMsg) async {
    _setSubmitting(true);
    _setError(null);
    final res =
        await _bookingService.rejectBookingRequest(requestId, responseMsg);
    _setSubmitting(false);
    if (res.success && res.data != null) {
      final idx = _bookingRequests.indexWhere((b) => b.requestId == requestId);
      if (idx != -1) _bookingRequests[idx] = res.data!;
      notifyListeners();
      loadBookingStats();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<bool> undoBookingResponse(int requestId) async {
    _setSubmitting(true);
    final res = await _bookingService.undoBookingResponse(requestId);
    _setSubmitting(false);
    if (res.success && res.data != null) {
      final idx = _bookingRequests.indexWhere((b) => b.requestId == requestId);
      if (idx != -1) _bookingRequests[idx] = res.data!;
      notifyListeners();
      loadBookingStats();
      return true;
    }
    _setError(res.message);
    return false;
  }

  Future<List<BookingTimelineEvent>> getBookingTimeline(int requestId) async {
    final res = await _bookingService.getBookingTimeline(requestId);
    if (res.success && res.data != null) return res.data!;
    return [];
  }

  void clearSelectedProperty() {
    _selectedProperty = null;
    _rooms = [];
    notifyListeners();
  }

  void reset() {
    _ownerProfile = null;
    _verificationStatus = null;
    _dashboardStats = null;
    _listingSubscription = null;
    _propertyAccessStatus = null;
    _propertyAccessHistory = [];
    _propertyAccessPlans = [];
    _listingPlans = [];
    _myProperties = [];
    _selectedProperty = null;
    _rooms = [];
    _bookingRequests = [];
    _bookingStats = null;
    _unreadBookingCount = 0;
    _isStatsLoading = false;
    _bookingSortBy = 'newest';
    _bookingFilterStatus = null;
    _bookingFilterPropertyId = null;
    _bookingSearchQuery = null;
    _bookingOnlyNew = false;
    _bookingOnlyUrgent = false;
    _isLoading = false;
    _isSubmitting = false;
    _error = null;
    // Dashboard reset
    _dashboardSummary = null;
    _isDashboardLoading = false;
    _hasInternet = true;
    notifyListeners();
  }
}

class ApiResponseResult {
  final bool success;
  final String message;
  ApiResponseResult(this.success, this.message);
}
