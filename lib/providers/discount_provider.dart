// providers/discount_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/discount_model.dart';
import '../services/api_service.dart';

class DiscountProvider extends ChangeNotifier {
  DiscountEligibility? eligibility;
  List<RentPaymentItem> payments = [];

  bool isLoading = false;
  bool isPaymentsLoading = false;
  String? error;

  final ApiService _api = ApiService();

  Future<void> fetchEligibility() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/user/discount-eligibility');
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        eligibility = DiscountEligibility(
          eligible: data['eligible'] ?? false,
          couponCode: data['couponCode'],
          discountPercent: data['discountPercent'] != null 
              ? (data['discountPercent'] as num).toDouble() 
              : null,
          message: data['message'],
        );
        error = null;
      } else {
        error = response.data['message'] ?? 'Failed to fetch eligibility';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments() async {
    isPaymentsLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/user/payments');
      
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        payments = data.map((e) => RentPaymentItem.fromJson(e)).toList();
      }
    } catch (e) {
      // fail silently
    } finally {
      isPaymentsLoading = false;
      notifyListeners();
    }
  }
}