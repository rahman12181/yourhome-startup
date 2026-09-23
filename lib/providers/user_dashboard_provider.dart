import 'package:flutter/material.dart';
import '../services/user_dashboard_service.dart';

class UserDashboardProvider extends ChangeNotifier {
  final UserDashboardService _service = UserDashboardService();
  bool _isDisposed = false;

  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _agreements = [];
  List<Map<String, dynamic>> _supportTickets = [];
  bool _isLoading = false;
  bool _isAgreementsLoading = false;
  String? _error;

  Map<String, dynamic>? get summary => _summary;
  List<Map<String, dynamic>> get agreements => _agreements;
  List<Map<String, dynamic>> get supportTickets => _supportTickets;
  bool get isLoading => _isLoading;
  bool get isAgreementsLoading => _isAgreementsLoading;
  String? get error => _error;

  // ============================================
  // STATS
  // ============================================
  Map<String, dynamic>? get stats => _summary?['stats'] as Map<String, dynamic>?;
  int get totalBookings => _int(stats?['totalBookings']);
  int get activeBookings => _int(stats?['activeBookings']);
  int get completedBookings => _int(stats?['completedBookings']);
  int get cancelledBookings => _int(stats?['cancelledBookings']);
  int get savedProperties => _int(stats?['savedProperties']);
  double get walletBalance => _double(stats?['walletBalance']);
  int get unreadMessages => _int(stats?['unreadMessages']);
  int get unreadNotifications => _int(stats?['unreadNotifications']);

  // ============================================
  // PAYMENT OVERVIEW
  // ============================================
  Map<String, dynamic>? get paymentOverview =>
      _summary?['paymentOverview'] as Map<String, dynamic>?;
  double get totalPaid => _double(paymentOverview?['totalPaid']);
  double get totalPending => _double(paymentOverview?['totalPending']);
  double get thisMonthPaid => _double(paymentOverview?['thisMonthPaid']);
  double get lastMonthPaid => _double(paymentOverview?['lastMonthPaid']);
  double get monthlyGrowthPercent =>
      _double(paymentOverview?['monthlyGrowthPercent']);
  int get totalTransactions => _int(paymentOverview?['totalTransactions']);

  List<Map<String, dynamic>> get monthlyTrend {
    final list = paymentOverview?['monthlyTrend'] as List?;
    return list?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  // ============================================
  // CURRENT TENANCY
  // ============================================
  Map<String, dynamic>? get currentTenancy =>
      _summary?['currentTenancy'] as Map<String, dynamic>?;
  bool get hasActiveTenancy => currentTenancy != null;
  bool get rentDue => currentTenancy?['rentDue'] == true;

  // ============================================
  // UPCOMING PAYMENTS
  // ============================================
  List<Map<String, dynamic>> get upcomingPayments {
    final list = _summary?['upcomingPayments'] as List?;
    return list?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  bool get hasOverduePayment => upcomingPayments.any((p) => p['overdue'] == true);

  // ============================================
  // RECENT BOOKINGS
  // ============================================
  List<Map<String, dynamic>> get recentBookings {
    final list = _summary?['recentBookings'] as List?;
    return list?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  // ============================================
  // RECENT ACTIVITY
  // ============================================
  List<Map<String, dynamic>> get recentActivity {
    final list = _summary?['recentActivity'] as List?;
    return list?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  // ============================================
  // LOAD SUMMARY
  // ============================================
  Future<void> loadSummary({bool showLoader = true}) async {
    if (_isDisposed) return;
    if (showLoader) {
      _isLoading = true;
      notifyListeners();
    }

    final res = await _service.getDashboardSummary();
    if (_isDisposed) return;

    if (res.success && res.data != null) {
      _summary = res.data;
      _error = null;
    } else {
      _error = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // LOAD AGREEMENTS
  // ============================================
  Future<void> loadAgreements({bool showLoader = true}) async {
    if (_isDisposed) return;
    if (showLoader) {
      _isAgreementsLoading = true;
      notifyListeners();
    }

    final res = await _service.getRentalAgreements();
    if (_isDisposed) return;

    if (res.success && res.data != null) {
      _agreements = res.data!;
    }

    _isAgreementsLoading = false;
    notifyListeners();
  }

  // ============================================
  // LOAD SUPPORT TICKETS
  // ============================================
  Future<void> loadSupportTickets() async {
    final res = await _service.getMyTickets();
    if (_isDisposed) return;
    if (res.success && res.data != null) {
      _supportTickets = res.data!;
      notifyListeners();
    }
  }

  // ============================================
  // INITIATE RENT PAYMENT
  // ============================================
  Future<Map<String, dynamic>?> initiateRentPayment(int invoiceId) async {
    final res = await _service.initiateRentPayment(invoiceId);
    if (_isDisposed) return null;
    if (res.success && res.data != null) return res.data;
    _error = res.message;
    notifyListeners();
    return null;
  }

  // ============================================
  // CONFIRM RENT PAYMENT
  // ============================================
  Future<bool> confirmRentPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await _service.confirmRentPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
    if (_isDisposed) return false;
    if (res.success) {
      await loadSummary(showLoader: false);
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  // ============================================
  // CREATE SUPPORT TICKET
  // ============================================
  Future<bool> createSupportTicket({
    required String category,
    required String subject,
    required String description,
    int? referenceId,
    String? referenceType,
  }) async {
    final res = await _service.createSupportTicket(
      category: category,
      subject: subject,
      description: description,
      referenceId: referenceId,
      referenceType: referenceType,
    );
    if (_isDisposed) return false;
    if (res.success) {
      await loadSupportTickets();
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  void reset() {
    _summary = null;
    _agreements = [];
    _supportTickets = [];
    _isLoading = false;
    _isAgreementsLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _double(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}