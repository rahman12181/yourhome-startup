import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  // ============== 2.9 SEND BOOKING REQUEST ==============
  Future<ApiResponse<BookingRequest>> sendBookingRequest(CreateBookingRequest request) async {
    try {
      final response = await _api.post(
        '/user/booking-requests',
        data: request.toJson(),
      );
      
      print('📤 Booking Request Sent: ${request.toJson()}');
      print('📥 Response: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<BookingRequest>(
          success: true,
          message: response.data['message'] ?? 'Booking request sent successfully',
          data: BookingRequest.fromJson(data),
        );
      } else {
        return ApiResponse<BookingRequest>(
          success: false,
          message: response.data['message'] ?? 'Failed to send booking request',
        );
      }
    } on DioException catch (e) {
      print('❌ Booking Error: ${e.response?.data}');
      if (e.response?.data != null) {
        return ApiResponse<BookingRequest>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<BookingRequest>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }

  // ============== 2.10 GET MY BOOKING REQUESTS ==============
  Future<ApiResponse<List<BookingRequest>>> getMyBookings() async {
    try {
      final response = await _api.get('/user/booking-requests');
      
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final bookings = data.map((item) => BookingRequest.fromJson(item)).toList();
        return ApiResponse<List<BookingRequest>>(
          success: true,
          message: response.data['message'] ?? 'Bookings fetched',
          data: bookings,
        );
      } else {
        return ApiResponse<List<BookingRequest>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch bookings',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<BookingRequest>>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<List<BookingRequest>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<BookingRequest>>.error(e.toString());
    }
  }

  // ============== 2.11 CANCEL BOOKING REQUEST ==============
  Future<ApiResponse<void>> cancelBooking(int requestId) async {
    try {
      final response = await _api.delete('/user/booking-requests/$requestId');
      
      return ApiResponse<void>(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  // ============== CHECK IF BOOKING IS ACCEPTED ==============
  Future<bool> isBookingAccepted(int bookingRequestId) async {
    try {
      final response = await _api.get('/user/booking-requests/$bookingRequestId/status');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final status = response.data['data']['status'];
        return status == 'ACCEPTED';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============== GET SINGLE BOOKING DETAIL ==============
  Future<ApiResponse<BookingRequest>> getBookingDetail(int bookingRequestId) async {
    try {
      final response = await _api.get('/user/booking-requests/$bookingRequestId');
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return ApiResponse<BookingRequest>(
          success: true,
          message: response.data['message'] ?? 'Booking detail fetched',
          data: BookingRequest.fromJson(data),
        );
      } else {
        return ApiResponse<BookingRequest>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch booking detail',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<BookingRequest>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<BookingRequest>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }

  // ============== CHECK IF BOOKING IS PAID ==============
  Future<bool> isBookingPaid(int bookingRequestId) async {
    try {
      final response = await _api.get('/user/booking-requests/$bookingRequestId/payment-status');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['isPaid'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============== GET BOOKING STATUS ONLY ==============
  Future<String?> getBookingStatus(int bookingRequestId) async {
    try {
      final response = await _api.get('/user/booking-requests/$bookingRequestId/status');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['status'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============== GET USER'S ACTIVE BOOKING FOR A PROPERTY ==============
  Future<BookingRequest?> getActiveBookingForProperty(int propertyId) async {
    try {
      final response = await _api.get('/user/booking-requests/active?propertyId=$propertyId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          return BookingRequest.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}