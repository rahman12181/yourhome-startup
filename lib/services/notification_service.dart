import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  // 8.1 Get My Notifications
  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    try {
      final response = await _api.get('/notifications');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final notifications = data.map((item) => NotificationModel.fromJson(item)).toList();
        return ApiResponse<List<NotificationModel>>(
          success: true,
          message: response.data['message'] ?? '',
          data: notifications,
        );
      } else {
        return ApiResponse<List<NotificationModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch notifications',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<NotificationModel>>.fromJson(
          e.response!.data,
          (data) => (data as List).map((item) => NotificationModel.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<NotificationModel>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<NotificationModel>>.error(e.toString());
    }
  }

  // 8.2 Get Unread Count
  Future<ApiResponse<UnreadCount>> getUnreadCount() async {
    try {
      final response = await _api.get('/notifications/unread-count');
      return ApiResponse<UnreadCount>.fromJson(
        response.data,
        (data) => UnreadCount.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<UnreadCount>.fromJson(
          e.response!.data,
          (data) => UnreadCount.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<UnreadCount>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<UnreadCount>.error(e.toString());
    }
  }

  // 8.3 Mark Single Notification as Read
  Future<ApiResponse<void>> markAsRead(int notificationId) async {
    try {
      final response = await _api.patch('/notifications/$notificationId/read');
      return ApiResponse<void>.fromJson(
        response.data,
        (data) => null,
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>.fromJson(
          e.response!.data,
          (data) => null,
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }

  // 8.4 Mark All Notifications as Read
  Future<ApiResponse<void>> markAllAsRead() async {
    try {
      final response = await _api.patch('/notifications/read-all');
      return ApiResponse<void>.fromJson(
        response.data,
        (data) => null,
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<void>.fromJson(
          e.response!.data,
          (data) => null,
        );
      }
      return ApiResponse<void>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }
}