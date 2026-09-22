import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import '../models/booking_stats_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  // ============================================
  // USER SIDE
  // ============================================

  Future<ApiResponse<BookingRequest>> sendBookingRequest(
      CreateBookingRequest request) async {
    try {
      final response =
          await _api.post('/user/booking-requests', data: request.toJson());

      if (response.data['success'] == true) {
        return ApiResponse<BookingRequest>(
          success: true,
          message: response.data['message'] ?? 'Booking request sent',
          data: BookingRequest.fromJson(response.data['data']),
        );
      }
      return ApiResponse<BookingRequest>(
        success: false,
        message: response.data['message'] ?? 'Failed to send',
      );
    } on DioException catch (e) {
      return ApiResponse<BookingRequest>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }

  Future<ApiResponse<List<BookingRequest>>> getMyBookings() async {
    try {
      final response = await _api.get('/user/booking-requests');
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return ApiResponse<List<BookingRequest>>(
          success: true,
          message: response.data['message'] ?? 'Bookings fetched',
          data: data
              .map((e) => BookingRequest.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
      return ApiResponse<List<BookingRequest>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<List<BookingRequest>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<List<BookingRequest>>.error(e.toString());
    }
  }

  Future<ApiResponse<void>> cancelBooking(int requestId) async {
    try {
      final response = await _api.delete('/user/booking-requests/$requestId');
      return ApiResponse<void>(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  Future<ApiResponse<BookingRequest>> getBookingDetail(
      int bookingRequestId) async {
    try {
      final response =
          await _api.get('/user/booking-requests/$bookingRequestId');
      if (response.data['success'] == true) {
        return ApiResponse<BookingRequest>(
          success: true,
          message: response.data['message'] ?? 'Detail fetched',
          data: BookingRequest.fromJson(response.data['data']),
        );
      }
      return ApiResponse<BookingRequest>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<BookingRequest>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }

  Future<bool> isBookingAccepted(int bookingRequestId) async {
    try {
      final response =
          await _api.get('/user/booking-requests/$bookingRequestId/status');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final status = response.data['data']['status'];
        return status == 'ACCEPTED';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBookingPaid(int bookingRequestId) async {
    try {
      final response = await _api
          .get('/user/booking-requests/$bookingRequestId/payment-status');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['isPaid'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getBookingStatus(int bookingRequestId) async {
    try {
      final response =
          await _api.get('/user/booking-requests/$bookingRequestId/status');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['status'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<BookingRequest?> getActiveBookingForProperty(int propertyId) async {
    try {
      final response = await _api
          .get('/user/booking-requests/active?propertyId=$propertyId');
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

  // ============================================
  // OWNER SIDE
  // ============================================

  Future<ApiResponse<List<BookingRequest>>> getOwnerBookingRequests({
    String? status,
    int? propertyId,
    String? searchQuery,
    String? sortBy,
    bool? onlyNew,
    bool? onlyUrgent,
  }) async {
    try {
      final Map<String, dynamic> query = {};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (propertyId != null) query['propertyId'] = propertyId;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query['searchQuery'] = searchQuery.trim();
      }
      if (sortBy != null && sortBy.isNotEmpty) query['sortBy'] = sortBy;
      if (onlyNew == true) query['onlyNew'] = true;
      if (onlyUrgent == true) query['onlyUrgent'] = true;

      final response = await _api.get(
        '/owner/booking-requests',
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return ApiResponse<List<BookingRequest>>(
          success: true,
          message: response.data['message'] ?? 'Bookings fetched',
          data: data
              .map((e) => BookingRequest.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
      return ApiResponse<List<BookingRequest>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<List<BookingRequest>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<List<BookingRequest>>.error(e.toString());
    }
  }

  Future<ApiResponse<List<BookingRequest>>> getIncomingBookingRequests() async {
    return getOwnerBookingRequests();
  }

  Future<ApiResponse<BookingStats>> getBookingStats() async {
    try {
      final response = await _api.get('/owner/booking-requests/stats');
      if (response.data['success'] == true) {
        return ApiResponse<BookingStats>(
          success: true,
          message: response.data['message'] ?? 'Stats fetched',
          data: BookingStats.fromJson(response.data['data']),
        );
      }
      return ApiResponse<BookingStats>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<BookingStats>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<BookingStats>.error(e.toString());
    }
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final response = await _api.get('/owner/booking-requests/unread-count');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final count = (data is int) ? data : int.tryParse('$data') ?? 0;
        return ApiResponse<int>(
          success: true,
          message: 'Unread count fetched',
          data: count,
        );
      }
      return ApiResponse<int>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<int>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<int>.error(e.toString());
    }
  }

  Future<ApiResponse<BookingRequest>> getOwnerBookingDetail(
      int requestId) async {
    try {
      final response = await _api.get('/owner/booking-requests/$requestId');
      if (response.data['success'] == true) {
        return ApiResponse<BookingRequest>(
          success: true,
          message: response.data['message'] ?? 'Detail fetched',
          data: BookingRequest.fromJson(response.data['data']),
        );
      }
      return ApiResponse<BookingRequest>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<BookingRequest>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }

  Future<ApiResponse<List<BookingTimelineEvent>>> getBookingTimeline(
      int requestId) async {
    try {
      final response =
          await _api.get('/owner/booking-requests/$requestId/timeline');
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return ApiResponse<List<BookingTimelineEvent>>(
          success: true,
          message: response.data['message'] ?? 'Timeline fetched',
          data: data
              .map((e) =>
                  BookingTimelineEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
      return ApiResponse<List<BookingTimelineEvent>>(
        success: false,
        message: response.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<List<BookingTimelineEvent>>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<List<BookingTimelineEvent>>.error(e.toString());
    }
  }

  Future<ApiResponse<BookingRequest>> acceptBookingRequest(
      int requestId, String responseMsg) async {
    try {
      final res = await _api.patch(
        '/owner/booking-requests/$requestId/accept',
        data: {'response': responseMsg},
      );
      if (res.data['success'] == true) {
        return ApiResponse<BookingRequest>(
          success: true,
          message: res.data['message'] ?? 'Accepted',
          data: BookingRequest.fromJson(res.data['data']),
        );
      }
      return ApiResponse<BookingRequest>(
        success: false,
        message: res.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<BookingRequest>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }

  Future<ApiResponse<BookingRequest>> rejectBookingRequest(
      int requestId, String responseMsg) async {
    try {
      final res = await _api.patch(
        '/owner/booking-requests/$requestId/reject',
        data: {'response': responseMsg},
      );
      if (res.data['success'] == true) {
        return ApiResponse<BookingRequest>(
          success: true,
          message: res.data['message'] ?? 'Rejected',
          data: BookingRequest.fromJson(res.data['data']),
        );
      }
      return ApiResponse<BookingRequest>(
        success: false,
        message: res.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<BookingRequest>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }

  Future<ApiResponse<BookingRequest>> undoBookingResponse(int requestId) async {
    try {
      final res = await _api.patch(
        '/owner/booking-requests/$requestId/undo',
        data: {},
      );
      if (res.data['success'] == true) {
        return ApiResponse<BookingRequest>(
          success: true,
          message: res.data['message'] ?? 'Undone',
          data: BookingRequest.fromJson(res.data['data']),
        );
      }
      return ApiResponse<BookingRequest>(
        success: false,
        message: res.data['message'] ?? 'Failed',
      );
    } on DioException catch (e) {
      return ApiResponse<BookingRequest>(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }
}