import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  // 2.1 Get My Profile
  Future<ApiResponse<UserProfile>> getProfile() async {
    try {
      final response = await _api.get('/user/profile');
      return ApiResponse<UserProfile>.fromJson(
        response.data,
        (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<UserProfile>.fromJson(
          e.response!.data,
          (data) => UserProfile.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<UserProfile>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<UserProfile>.error(e.toString());
    }
  }

  // 2.2 Update Profile
  Future<ApiResponse<UserProfile>> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _api.put(
        '/user/profile',
        data: request.toJson(),
      );
      return ApiResponse<UserProfile>.fromJson(
        response.data,
        (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<UserProfile>.fromJson(
          e.response!.data,
          (data) => UserProfile.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<UserProfile>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<UserProfile>.error(e.toString());
    }
  }

  // 2.3 Upload Profile Picture
  Future<ApiResponse<UserProfile>> uploadProfilePicture(FormData formData) async {
    try {
      final response = await _api.upload(
        '/user/profile/picture',
        formData,
      );
      return ApiResponse<UserProfile>.fromJson(
        response.data,
        (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<UserProfile>.fromJson(
          e.response!.data,
          (data) => UserProfile.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<UserProfile>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<UserProfile>.error(e.toString());
    }
  }

  // 2.4 Change Password
  Future<ApiResponse<void>> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await _api.put(
        '/user/change-password',
        data: request.toJson(),
      );
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

  // 2.5 Update FCM Token
  Future<ApiResponse<void>> updateFcmToken(String fcmToken) async {
    try {
      final response = await _api.put(
        '/user/fcm-token',
        data: {'fcmToken': fcmToken},
      );
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

  // 2.9 Send Booking Request
  Future<ApiResponse<BookingRequest>> sendBookingRequest(CreateBookingRequest request) async {
    try {
      final response = await _api.post(
        '/user/booking-requests',
        data: request.toJson(),
      );
      return ApiResponse<BookingRequest>.fromJson(
        response.data,
        (data) => BookingRequest.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<BookingRequest>.fromJson(
          e.response!.data,
          (data) => BookingRequest.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<BookingRequest>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<BookingRequest>.error(e.toString());
    }
  }

  // 2.10 Get My Booking Requests
  Future<ApiResponse<List<BookingRequest>>> getBookingRequests() async {
    try {
      final response = await _api.get('/user/booking-requests');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final bookings = data.map((item) => BookingRequest.fromJson(item)).toList();
        return ApiResponse<List<BookingRequest>>(
          success: true,
          message: response.data['message'] ?? '',
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
        return ApiResponse<List<BookingRequest>>.fromJson(
          e.response!.data,
          (data) => (data as List).map((item) => BookingRequest.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<BookingRequest>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<BookingRequest>>.error(e.toString());
    }
  }

  // 2.11 Cancel Booking Request
  Future<ApiResponse<void>> cancelBookingRequest(int requestId) async {
    try {
      final response = await _api.delete('/user/booking-requests/$requestId');
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

  // 2.12 Write Review
  Future<ApiResponse<Review>> writeReview(int propertyId, CreateReviewRequest request) async {
    try {
      final response = await _api.post(
        '/user/reviews/$propertyId',
        data: request.toJson(),
      );
      return ApiResponse<Review>.fromJson(
        response.data,
        (data) => Review.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<Review>.fromJson(
          e.response!.data,
          (data) => Review.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<Review>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<Review>.error(e.toString());
    }
  }

  // 2.13 Submit Report
  Future<ApiResponse<void>> submitReport({
    required String type,
    required int refId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _api.post(
        '/user/report',
        data: {
          'type': type,
          'refId': refId,
          'reason': reason,
          if (description != null) 'description': description,
        },
      );
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

  // Get Property Reviews (Public)
  Future<ApiResponse<List<Review>>> getPropertyReviews(int propertyId) async {
    try {
      final response = await _api.get('/properties/$propertyId/reviews');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final reviews = data.map((item) => Review.fromJson(item)).toList();
        return ApiResponse<List<Review>>(
          success: true,
          message: response.data['message'] ?? '',
          data: reviews,
        );
      } else {
        return ApiResponse<List<Review>>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch reviews',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ApiResponse<List<Review>>.fromJson(
          e.response!.data,
          (data) => (data as List).map((item) => Review.fromJson(item)).toList(),
        );
      }
      return ApiResponse<List<Review>>.error(e.message ?? 'Something went wrong');
    } catch (e) {
      return ApiResponse<List<Review>>.error(e.toString());
    }
  }
}