import 'package:dio/dio.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class UserDashboardService {
  final ApiService _api = ApiService();

  Future<ApiResponse<Map<String, dynamic>>> getDashboardSummary() async {
    try {
      final response = await _api.get('/user/dashboard/summary');
      if (response.data['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Summary fetched',
          data: Map<String, dynamic>.from(response.data['data'] ?? {}),
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(e.toString());
    }
  }

  /// GET /user/rental-agreements
  Future<ApiResponse<List<Map<String, dynamic>>>> getRentalAgreements() async {
    try {
      final response = await _api.get('/user/rental-agreements');
      if (response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          message: 'Agreements fetched',
          data: list.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>.error(e.toString());
    }
  }

  /// POST /user/monthly-rent/initiate/{invoiceId}
  Future<ApiResponse<Map<String, dynamic>>> initiateRentPayment(int invoiceId) async {
    try {
      final response = await _api.post('/user/monthly-rent/initiate/$invoiceId');
      if (response.data['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Payment initiated',
          data: Map<String, dynamic>.from(response.data['data'] ?? {}),
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(e.toString());
    }
  }

  /// POST /user/monthly-rent/confirm
  Future<ApiResponse<Map<String, dynamic>>> confirmRentPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _api.post('/user/monthly-rent/confirm', data: {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });
      if (response.data['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Payment confirmed',
          data: Map<String, dynamic>.from(response.data['data'] ?? {}),
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(e.toString());
    }
  }

  /// POST /user/support/tickets
  Future<ApiResponse<Map<String, dynamic>>> createSupportTicket({
    required String category,
    required String subject,
    required String description,
    int? referenceId,
    String? referenceType,
  }) async {
    try {
      final response = await _api.post('/user/support/tickets', data: {
        'category': category,
        'subject': subject,
        'description': description,
        if (referenceId != null) 'referenceId': referenceId,
        if (referenceType != null) 'referenceType': referenceType,
      });
      if (response.data['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Ticket created',
          data: Map<String, dynamic>.from(response.data['data'] ?? {}),
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(e.toString());
    }
  }

  /// GET /user/support/tickets
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyTickets() async {
    try {
      final response = await _api.get('/user/support/tickets');
      if (response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          message: 'Tickets fetched',
          data: list.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>.error(e.toString());
    }
  }
}