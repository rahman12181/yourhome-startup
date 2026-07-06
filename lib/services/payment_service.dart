// lib/services/payment_service.dart

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

class PaymentService {
  static PaymentService? _instance;
  Razorpay? _razorpay;
  bool _isInitialized = false;

  PaymentService._internal();

  static PaymentService get instance {
    _instance ??= PaymentService._internal();
    return _instance!;
  }

  // ============ INITIALIZE ============
  void init() {
    if (_isInitialized) return;
    _razorpay = Razorpay();
    _isInitialized = true;
    print('✅ PaymentService initialized');
  }

  // ============ GET RAZORPAY INSTANCE ============
  Razorpay get razorpay {
    if (_razorpay == null) {
      throw Exception('PaymentService not initialized. Call init() first.');
    }
    return _razorpay!;
  }

  // ============ OPEN CHECKOUT ============
  void openCheckout({
    required String key,
    required int amount, // in paise
    required String orderId,
    required String name,
    required String description,
    required String contact,
    required String email,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(dynamic) onExternal,
  }) {
    final options = {
      'key': key,
      'amount': amount,
      'currency': 'INR',
      'order_id': orderId,
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'theme': {'color': '#F59E0B'},
      'modal': {
        'confirm_close': true,
        'confirm_close_title': 'Close Payment',
        'confirm_close_description': 'Are you sure you want to cancel this payment?',
        'confirm_close_confirm_text': 'Yes, Cancel',
        'confirm_close_cancel_text': 'No, Continue',
      }
    };

    try {
      print('🔓 Opening Razorpay checkout...');
      print('📦 Order ID: $orderId');
      print('💰 Amount: ₹${(amount / 100).toStringAsFixed(2)}');
      _razorpay?.open(options);
    } catch (e) {
      print('❌ Error opening Razorpay: $e');
    }
  }

  // ============ DISPOSE ============
  void dispose() {
    _razorpay?.clear();
    _isInitialized = false;
    print('🧹 PaymentService disposed');
  }
}