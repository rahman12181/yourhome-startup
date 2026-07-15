import 'package:flutter/material.dart';
import '../models/referral_model.dart';
import '../services/api_service.dart';

class ReferralProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  ReferralInfo? _referralInfo;
  List<ReferralHistory> _history = [];
  List<WalletTransaction> _transactions = [];
  List<WithdrawalRequest> _withdrawals = [];
  List<PendingWithdrawal> _pendingWithdrawals = [];
  List<WithdrawalHistoryItem> _paymentHistory = [];

  bool _isLoading = false;
  bool _isHistoryLoading = false;
  bool _isTransactionLoading = false;
  String? _error;

  ReferralInfo? get referralInfo => _referralInfo;
  List<ReferralHistory> get history => _history;
  List<WalletTransaction> get transactions => _transactions;
  List<WithdrawalRequest> get withdrawals => _withdrawals;
  List<PendingWithdrawal> get pendingWithdrawals => _pendingWithdrawals;
  List<WithdrawalHistoryItem> get paymentHistory => _paymentHistory;
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isTransactionLoading => _isTransactionLoading;
  String? get error => _error;

  double get walletBalance => _referralInfo?.walletBalance ?? 0.0;
  bool get canWithdraw => walletBalance >= 100.0;

  Future<bool> fetchReferralInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getReferralInfo();
      if (response.statusCode == 200 && response.data['success'] == true) {
        _referralInfo = ReferralInfo.fromJson(response.data['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch referral info';
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

  Future<bool> fetchReferralHistory() async {
    _isHistoryLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getReferralHistory();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _history = data.map((item) => ReferralHistory.fromJson(item)).toList();
        _isHistoryLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch history';
        _isHistoryLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isHistoryLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchWalletTransactions({int page = 0, int size = 20}) async {
    _isTransactionLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getWalletTransactions(page: page, size: size);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final content = data['content'] as List? ?? [];
        _transactions = content.map((item) => WalletTransaction.fromJson(item)).toList();
        _isTransactionLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch transactions';
        _isTransactionLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isTransactionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String upiId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.requestWithdrawal(
        amount: amount,
        upiId: upiId,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        await fetchReferralInfo();
        return {
          'success': true,
          'message': response.data['message'],
          'data': response.data['data'],
        };
      } else {
        _error = response.data['message'] ?? 'Withdrawal failed';
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

  Future<bool> fetchWithdrawals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getWithdrawals();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _withdrawals = data.map((item) => WithdrawalRequest.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch withdrawals';
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

  Future<bool> fetchPendingWithdrawals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getPendingWithdrawals();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _pendingWithdrawals = data.map((item) => PendingWithdrawal.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch pending withdrawals';
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

  Future<Map<String, dynamic>> approveWithdrawal({
    required int withdrawalId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.approveWithdrawal(
        withdrawalId: withdrawalId,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        await fetchPendingWithdrawals();
        return {
          'success': true,
          'message': response.data['message'],
          'data': response.data['data'],
        };
      } else {
        _error = response.data['message'] ?? 'Approval failed';
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

  Future<Map<String, dynamic>> rejectWithdrawal({
    required int withdrawalId,
    required String reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.rejectWithdrawal(
        withdrawalId: withdrawalId,
        reason: reason,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        await fetchPendingWithdrawals();
        return {
          'success': true,
          'message': response.data['message'],
          'data': response.data['data'],
        };
      } else {
        _error = response.data['message'] ?? 'Rejection failed';
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

  Future<bool> fetchPaymentHistory({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getPaymentHistory(status: status);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _paymentHistory = data.map((item) => WithdrawalHistoryItem.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch payment history';
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

  Color getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.amber;
      case 'PROCESSING':
        return Colors.blue;
      case 'APPROVED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'REJECTED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'PROCESSING':
        return 'Processing';
      case 'APPROVED':
        return 'Approved';
      case 'FAILED':
        return 'Failed';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  String getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return '⏳';
      case 'PROCESSING':
        return '🔄';
      case 'APPROVED':
        return '✅';
      case 'FAILED':
        return '❌';
      case 'REJECTED':
        return '🚫';
      default:
        return '❓';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _referralInfo = null;
    _history = [];
    _transactions = [];
    _withdrawals = [];
    _pendingWithdrawals = [];
    _paymentHistory = [];
    _isLoading = false;
    _isHistoryLoading = false;
    _isTransactionLoading = false;
    _error = null;
    notifyListeners();
  }
}