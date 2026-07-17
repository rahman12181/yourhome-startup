import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  PaymentSummary? _paymentSummary;
  List<RentPayment> _studentPayments = [];
  List<OwnerPayment> _ownerPayments = [];
  List<AdminRentPayment> _adminRentPayments = [];

  bool _isLoading = false;
  String? _error;

  PaymentSummary? get paymentSummary => _paymentSummary;
  List<RentPayment> get studentPayments => _studentPayments;
  List<OwnerPayment> get ownerPayments => _ownerPayments;
  List<AdminRentPayment> get adminRentPayments => _adminRentPayments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== 14.1 - Get Payment Summary ==========
  Future<bool> fetchPaymentSummary(int bookingRequestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/user/bookings/$bookingRequestId/payment-summary');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _paymentSummary = PaymentSummary.fromJson(response.data['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch payment summary';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== 14.2 - Initiate Payment ==========
  Future<Map<String, dynamic>> initiatePayment(
    int bookingRequestId, {
    String? couponCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (couponCode != null && couponCode.isNotEmpty) {
        data['couponCode'] = couponCode;
      }

      final response = await _api.post(
        '/user/bookings/$bookingRequestId/pay/initiate',
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final result = InitiatePaymentResponse.fromJson(response.data['data']);
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'data': result,
          'message': response.data['message'],
        };
      } else {
        _error = response.data['message'] ?? 'Failed to initiate payment';
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': _error,
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
    }
  }

  // ========== 14.3 - Confirm Payment ==========
  Future<Map<String, dynamic>> confirmPayment({
    required int bookingRequestId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(
        '/user/bookings/$bookingRequestId/pay/confirm',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final result = ConfirmPaymentResponse.fromJson(response.data['data']);
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'data': result,
          'message': response.data['message'],
        };
      } else {
        _error = response.data['message'] ?? 'Payment confirmation failed';
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': _error,
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
    }
  }

  // ========== 14.4 - Get My Payments (Student) ==========
  Future<bool> fetchStudentPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/user/payments');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _studentPayments = data.map((item) => RentPayment.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch payments';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== 14.6 - Get My Payments (Owner) ==========
  Future<bool> fetchOwnerPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/owner/payments');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _ownerPayments = data.map((item) => OwnerPayment.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch owner payments';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== 14.7 - Get All Rent Payments (Admin) ==========
  Future<bool> fetchAdminRentPayments({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _api.get(
        '/admin/rent-payments/all',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _adminRentPayments = data.map((item) => AdminRentPayment.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch rent payments';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== 14.5 - Set Payout UPI ID (Owner) ==========
  Future<Map<String, dynamic>> setPayoutUpi(String upiId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.put(
        '/owner/payout-upi',
        data: {'payoutUpiId': upiId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'message': response.data['message'],
        };
      } else {
        _error = response.data['message'] ?? 'Failed to set UPI ID';
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': _error,
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _paymentSummary = null;
    _studentPayments = [];
    _ownerPayments = [];
    _adminRentPayments = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}