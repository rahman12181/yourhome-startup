import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _api = ApiService();

  // ============== 2.1 GET PROFILE ==============
  Future<ApiResponse<UserProfile>> getProfile() async {
    try {
      final response = await _api.get('/user/profile');
      
      // ✅ DEBUG: Print response to see what's coming
      print('📥 Profile Response: ${response.data}');
      
      // ✅ Check if response has data
      if (response.data == null) {
        return ApiResponse<UserProfile>.error('No data received from server');
      }
      
      // ✅ Check if success is true
      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        // ✅ Check if data is a Map
        if (data is Map<String, dynamic>) {
          return ApiResponse<UserProfile>(
            success: true,
            message: response.data['message'] ?? 'Profile fetched',
            data: UserProfile.fromJson(data),
          );
        } else {
          return ApiResponse<UserProfile>.error('Invalid data format received');
        }
      } else {
        return ApiResponse<UserProfile>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch profile',
        );
      }
    } on DioException catch (e) {
      print('❌ Dio Error: ${e.message}');
      if (e.response?.data != null) {
        return ApiResponse<UserProfile>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<UserProfile>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      print('❌ Error: $e');
      return ApiResponse<UserProfile>.error(e.toString());
    }
  }

  // ============== 2.2 UPDATE PROFILE ==============
  Future<ApiResponse<UserProfile>> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _api.put(
        '/user/profile',
        data: request.toJson(),
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return ApiResponse<UserProfile>(
            success: true,
            message: response.data['message'] ?? 'Profile updated',
            data: UserProfile.fromJson(data),
          );
        } else {
          return ApiResponse<UserProfile>.error('Invalid data format received');
        }
      } else {
        return ApiResponse<UserProfile>(
          success: false,
          message: response.data['message'] ?? 'Failed to update profile',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<UserProfile>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<UserProfile>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<UserProfile>.error(e.toString());
    }
  }

  // ============== 2.3 UPLOAD PROFILE PICTURE ==============
  Future<ApiResponse<UserProfile>> uploadProfilePicture(FormData formData) async {
    try {
      final response = await _api.upload(
        '/user/profile/picture',
        formData,
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return ApiResponse<UserProfile>(
            success: true,
            message: response.data['message'] ?? 'Profile picture updated',
            data: UserProfile.fromJson(data),
          );
        } else {
          return ApiResponse<UserProfile>.error('Invalid data format received');
        }
      } else {
        return ApiResponse<UserProfile>(
          success: false,
          message: response.data['message'] ?? 'Failed to upload picture',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<UserProfile>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<UserProfile>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<UserProfile>.error(e.toString());
    }
  }

  // ============== 2.4 CHANGE PASSWORD ==============
  Future<ApiResponse<void>> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await _api.put(
        '/user/change-password',
        data: request.toJson(),
      );
      
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

  // ============== 2.9 GET MY BOOKINGS ==============
  Future<ApiResponse<List<BookingRequest>>> getMyBookings() async {
    try {
      final response = await _api.get('/user/booking-requests');
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          final bookings = data.map((item) => BookingRequest.fromJson(item)).toList();
          return ApiResponse<List<BookingRequest>>(
            success: true,
            message: response.data['message'] ?? 'Bookings fetched',
            data: bookings,
          );
        } else {
          return ApiResponse<List<BookingRequest>>(
            success: true,
            message: response.data['message'] ?? 'Bookings fetched',
            data: [],
          );
        }
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

  // ============== 2.11 CANCEL BOOKING ==============
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

  // ============== 8.1 GET NOTIFICATIONS ==============
  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    try {
      final response = await _api.get('/notifications');
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          final notifications = data.map((item) => NotificationModel.fromJson(item)).toList();
          return ApiResponse<List<NotificationModel>>(
            success: true,
            message: response.data['message'] ?? 'Notifications fetched',
            data: notifications,
          );
        } else {
          return ApiResponse<List<NotificationModel>>(
            success: true,
            message: response.data['message'] ?? 'Notifications fetched',
            data: [],
          );
        }
      } else {
        return ApiResponse<List<NotificationModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch notifications',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<NotificationModel>>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<List<NotificationModel>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<NotificationModel>>.error(e.toString());
    }
  }

  // ============== 8.2 GET UNREAD COUNT ==============
  Future<ApiResponse<UnreadCount>> getUnreadCount() async {
    try {
      final response = await _api.get('/notifications/unread-count');
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return ApiResponse<UnreadCount>(
            success: true,
            message: response.data['message'] ?? 'Unread count fetched',
            data: UnreadCount.fromJson(data),
          );
        } else {
          return ApiResponse<UnreadCount>(
            success: true,
            message: response.data['message'] ?? 'Unread count fetched',
            data: UnreadCount(unreadCount: 0),
          );
        }
      } else {
        return ApiResponse<UnreadCount>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch unread count',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<UnreadCount>(
          success: false,
          message: e.response?.data['message'] ?? e.message ?? 'Something went wrong',
        );
      }
      return ApiResponse<UnreadCount>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<UnreadCount>.error(e.toString());
    }
  }

  // ============== 8.3 MARK NOTIFICATION AS READ ==============
  Future<ApiResponse<void>> markNotificationAsRead(int notificationId) async {
    try {
      final response = await _api.patch('/notifications/$notificationId/read');
      
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

  // ============== 8.4 MARK ALL AS READ ==============
  Future<ApiResponse<void>> markAllAsRead() async {
    try {
      final response = await _api.patch('/notifications/read-all');
      
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
}