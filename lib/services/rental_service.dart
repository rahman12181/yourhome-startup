// lib/services/rental_service.dart
//
// ⚠️ INTEGRATION NOTE:
// This file creates its own Dio instance + reads the token from
// SharedPreferences directly, so it's self-contained and compiles on its
// own. Your app already has a shared Dio client (the one BookingService /
// ChatService use, with the base URL + auth interceptor already wired).
// Replace `_dio` below with that shared client instance instead of
// duplicating the setup — search your project for how BookingService
// gets its Dio instance and mirror it here.

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rental_model.dart';

class RentalService {
  // TODO: replace with your app's actual base URL constant.
  static const String _baseUrl = 'https://api.nestora.in';

  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken'); // match your actual pref key
  }

  Future<Options> _authOptions() async {
    final token = await _token();
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  // ── 17.1 — Get my rental agreements ─────────────────────────────
  Future<RentalApiResponse<List<RentalAgreement>>> getMyAgreements() async {
    try {
      final res = await _dio.get(
        '/user/rental-agreements',
        options: await _authOptions(),
      );
      final json = res.data;
      final list = (json['data'] as List? ?? [])
          .map((e) => RentalAgreement.fromJson(e as Map<String, dynamic>))
          .toList();
      return RentalApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: list,
      );
    } on DioException catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.response?.data?['message']?.toString() ??
            'Failed to load rental agreements',
      );
    }
  }

  // ── 17.2 — Get agreement detail ─────────────────────────────────
  Future<RentalApiResponse<RentalAgreement>> getAgreementDetail(
      int agreementId) async {
    try {
      final res = await _dio.get(
        '/user/rental-agreements/$agreementId',
        options: await _authOptions(),
      );
      final json = res.data;
      return RentalApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] != null
            ? RentalAgreement.fromJson(json['data'])
            : null,
      );
    } on DioException catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.response?.data?['message']?.toString() ??
            'Failed to load agreement',
      );
    }
  }

  // ── 17.3 — Get agreement invoices ───────────────────────────────
  Future<RentalApiResponse<List<RentInvoice>>> getAgreementInvoices(
      int agreementId) async {
    try {
      final res = await _dio.get(
        '/user/rental-agreements/$agreementId/invoices',
        options: await _authOptions(),
      );
      final json = res.data;
      final list = (json['data'] as List? ?? [])
          .map((e) => RentInvoice.fromJson(e as Map<String, dynamic>))
          .toList();
      return RentalApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: list,
      );
    } on DioException catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.response?.data?['message']?.toString() ??
            'Failed to load invoices',
      );
    }
  }

  // ── 17.4 — Terminate agreement ──────────────────────────────────
  Future<RentalApiResponse<RentalAgreement>> terminateAgreement(
      int agreementId, String reason) async {
    try {
      final res = await _dio.post(
        '/user/rental-agreements/$agreementId/terminate',
        data: {'reason': reason},
        options: await _authOptions(),
      );
      final json = res.data;
      return RentalApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] != null
            ? RentalAgreement.fromJson(json['data'])
            : null,
      );
    } on DioException catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.response?.data?['message']?.toString() ??
            'Failed to terminate agreement',
      );
    }
  }

  // ── 17.5 — Initiate monthly rent payment ────────────────────────
  Future<RentalApiResponse<MonthlyRentInitiateResponse>> initiateMonthlyRent(
      int invoiceId) async {
    try {
      final res = await _dio.post(
        '/user/monthly-rent/initiate/$invoiceId',
        options: await _authOptions(),
      );
      final json = res.data;
      return RentalApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] != null
            ? MonthlyRentInitiateResponse.fromJson(json['data'])
            : null,
      );
    } on DioException catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.response?.data?['message']?.toString() ??
            'Failed to initiate payment',
      );
    }
  }

  // ── 17.6 — Confirm monthly rent payment ─────────────────────────
  Future<RentalApiResponse<MonthlyRentPayment>> confirmMonthlyRent({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await _dio.post(
        '/user/monthly-rent/confirm',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
        options: await _authOptions(),
      );
      final json = res.data;
      return RentalApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] != null
            ? MonthlyRentPayment.fromJson(json['data'])
            : null,
      );
    } on DioException catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.response?.data?['message']?.toString() ??
            'Payment confirmation failed',
      );
    }
  }

  // ── 17.7 — Get my monthly rent payments ─────────────────────────
  Future<RentalApiResponse<List<MonthlyRentPayment>>>
      getMyMonthlyPayments() async {
    try {
      final res = await _dio.get(
        '/user/monthly-rent/my-payments',
        options: await _authOptions(),
      );
      final json = res.data;
      final list = (json['data'] as List? ?? [])
          .map((e) => MonthlyRentPayment.fromJson(e as Map<String, dynamic>))
          .toList();
      return RentalApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: list,
      );
    } on DioException catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.response?.data?['message']?.toString() ??
            'Failed to load payments',
      );
    }
  }
}