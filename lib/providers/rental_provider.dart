// lib/providers/rental_provider.dart

import 'package:flutter/material.dart';
import '../models/rental_model.dart';
import '../services/rental_service.dart';

class RentalProvider extends ChangeNotifier {
  final RentalService _service = RentalService();

  List<RentalAgreement> agreements = [];
  RentalAgreement? selectedAgreement;
  List<RentInvoice> invoices = [];
  List<MonthlyRentPayment> myPayments = [];

  bool isLoading = false;
  String? error;

  // ── Agreements list ──────────────────────────────────────────
  Future<bool> fetchMyAgreements() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final res = await _service.getMyAgreements();
    isLoading = false;

    if (res.success) {
      agreements = res.data ?? [];
      notifyListeners();
      return true;
    } else {
      error = res.message;
      notifyListeners();
      return false;
    }
  }

  // ── Agreement detail + its invoices (one call site) ─────────────
  Future<bool> fetchAgreementWithInvoices(int agreementId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final detailRes = await _service.getAgreementDetail(agreementId);
    final invoicesRes = await _service.getAgreementInvoices(agreementId);
    isLoading = false;

    if (detailRes.success) {
      selectedAgreement = detailRes.data;
      invoices = invoicesRes.data ?? [];
      notifyListeners();
      return true;
    } else {
      error = detailRes.message;
      notifyListeners();
      return false;
    }
  }

  // ── Terminate agreement ──────────────────────────────────────
  Future<Map<String, dynamic>> terminateAgreement(
      int agreementId, String reason) async {
    final res = await _service.terminateAgreement(agreementId, reason);
    if (res.success && res.data != null) {
      selectedAgreement = res.data;
      notifyListeners();
    }
    return {'success': res.success, 'message': res.message};
  }

  // ── Initiate monthly rent payment ────────────────────────────
  Future<Map<String, dynamic>> initiateMonthlyRent(int invoiceId) async {
    final res = await _service.initiateMonthlyRent(invoiceId);
    return {
      'success': res.success,
      'message': res.message,
      'data': res.data,
    };
  }

  // ── Confirm monthly rent payment ─────────────────────────────
  Future<Map<String, dynamic>> confirmMonthlyRent({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await _service.confirmMonthlyRent(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
    return {
      'success': res.success,
      'message': res.message,
      'data': res.data,
    };
  }

  // ── My monthly payment history ───────────────────────────────
  Future<bool> fetchMyPayments() async {
    final res = await _service.getMyMonthlyPayments();
    if (res.success) {
      myPayments = res.data ?? [];
      notifyListeners();
      return true;
    }
    error = res.message;
    notifyListeners();
    return false;
  }

  /// Call this after a successful monthly-rent confirm, or after
  /// terminating, to refresh the invoices list for the currently
  /// open agreement without a full reload.
  Future<void> refreshInvoices() async {
    if (selectedAgreement == null) return;
    final invoicesRes =
        await _service.getAgreementInvoices(selectedAgreement!.id);
    invoices = invoicesRes.data ?? invoices;
    notifyListeners();
  }
}