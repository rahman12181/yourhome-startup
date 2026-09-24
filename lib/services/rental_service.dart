// lib/services/rental_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/rental_model.dart';
import 'api_service.dart';

class RentalService {
  final ApiService _api = ApiService();

  // ── 17.1 — Get my rental agreements ─────────────────────────────
  Future<RentalApiResponse<List<RentalAgreement>>> getMyAgreements() async {
    try {
      debugPrint('🔍 [RentalService] Fetching agreements...');

      final response = await _api.get('/user/rental-agreements');

      debugPrint('📥 [RentalService] Response: ${response.data}');

      final json = response.data;
      final list = (json['data'] as List? ?? [])
          .map((e) => RentalAgreement.fromJson(e as Map<String, dynamic>))
          .toList();

      return RentalApiResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: list,
      );
    } on DioException catch (e) {
      debugPrint('❌ [RentalService] DioException: ${e.message}');
      debugPrint('❌ [RentalService] Response: ${e.response?.data}');

      return RentalApiResponse(
        success: false,
        message: e.response?.data?['message']?.toString() ??
            e.message ??
            'Failed to load rental agreements',
      );
    } catch (e) {
      debugPrint('❌ [RentalService] Exception: $e');
      return RentalApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // ── 17.2 — Get agreement detail ─────────────────────────────────
  Future<RentalApiResponse<RentalAgreement>> getAgreementDetail(
      int agreementId) async {
    try {
      final response = await _api.get('/user/rental-agreements/$agreementId');
      final json = response.data;

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
    } catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // ── 17.3 — Get agreement invoices ───────────────────────────────
  Future<RentalApiResponse<List<RentInvoice>>> getAgreementInvoices(
      int agreementId) async {
    try {
      final response =
          await _api.get('/user/rental-agreements/$agreementId/invoices');
      final json = response.data;

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
    } catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // ── 17.4 — Terminate agreement ──────────────────────────────────
  Future<RentalApiResponse<RentalAgreement>> terminateAgreement(
      int agreementId, String reason) async {
    try {
      final response = await _api.post(
        '/user/rental-agreements/$agreementId/terminate',
        data: {'reason': reason},
      );
      final json = response.data;

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
    } catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // ── 17.5 — Initiate monthly rent payment ────────────────────────
  Future<RentalApiResponse<MonthlyRentInitiateResponse>> initiateMonthlyRent(
      int invoiceId) async {
    try {
      final response =
          await _api.post('/user/monthly-rent/initiate/$invoiceId');
      final json = response.data;

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
    } catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.toString(),
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
      final response = await _api.post(
        '/user/monthly-rent/confirm',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      final json = response.data;

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
    } catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // ── 17.7 — Get my monthly rent payments ─────────────────────────
  Future<RentalApiResponse<List<MonthlyRentPayment>>>
      getMyMonthlyPayments() async {
    try {
      final response = await _api.get('/user/monthly-rent/my-payments');
      final json = response.data;

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
    } catch (e) {
      return RentalApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
}